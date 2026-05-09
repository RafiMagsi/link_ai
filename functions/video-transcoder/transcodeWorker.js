import "dotenv/config";
import * as admin from "firebase-admin";
import { exec } from "child_process";
import { promisify } from "util";
import * as fs from "fs";
import * as path from "path";
import * as AWS from "aws-sdk";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function initializeFirebase() {
  const serviceAccountPath = path.join(
    __dirname,
    "firebase-service-account.json",
  );

  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error(
      `Missing firebase-service-account.json at ${serviceAccountPath}`,
    );
  }

  const serviceAccount = JSON.parse(
    fs.readFileSync(serviceAccountPath, "utf8"),
  );

  if (
    !serviceAccount.project_id ||
    !serviceAccount.client_email ||
    !serviceAccount.private_key
  ) {
    throw new Error(
      "firebase-service-account.json is missing project_id, client_email, or private_key",
    );
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

initializeFirebase();

const db = admin.firestore();
const execAsync = promisify(exec);
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION,
});

const CLOUDFRONT_DOMAIN = process.env.CLOUDFRONT_DOMAIN;
const TEMP_DIR = "/tmp/link-ai-transcode";

if (
  !process.env.AWS_ACCESS_KEY_ID ||
  !process.env.AWS_SECRET_ACCESS_KEY ||
  !process.env.AWS_REGION ||
  !CLOUDFRONT_DOMAIN
) {
  throw new Error(
    "Missing required env: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, or CLOUDFRONT_DOMAIN",
  );
}

// Ensure temp directory exists
if (!fs.existsSync(TEMP_DIR)) {
  fs.mkdirSync(TEMP_DIR, { recursive: true });
}

async function processVideoQueue() {
  try {
    const job = await getNextTranscodeJob();

    if (!job) {
      console.log("No pending videos to process");
      return;
    }

    console.log(`Processing video: ${job.videoId}`);

    try {
      await transcodeVideo(job);
      console.log(`✓ Transcoding complete for ${job.videoId}`);
    } catch (error) {
      console.error(`✗ Transcoding failed for ${job.videoId}:`, error);
      await markTranscodeJobFailed(
        job.postId,
        job.mediaIndex,
        job.videoId,
        error.message
      );
    }
  } catch (error) {
    console.error("Error in queue processor:", error);
  }
}

async function getNextTranscodeJob() {
  const snapshot = await db
    .collection("videoTranscodeQueue")
    .where("status", "==", "pending")
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  return {
    docId: snapshot.docs[0].id,
    ...snapshot.docs[0].data(),
  };
}

async function transcodeVideo(job) {
  const {
    videoId,
    postId,
    mediaIndex,
    s3InputKey,
    bucket,
    region,
  } = job;

  const videoDir = path.join(TEMP_DIR, videoId);
  const inputFile = path.join(videoDir, "input.mp4");
  const outputDir = path.join(videoDir, "hls");

  // Create directories
  fs.mkdirSync(videoDir, { recursive: true });
  fs.mkdirSync(outputDir, { recursive: true });

  try {
    // Step 1: Download from S3
    console.log(`Downloading s3://${bucket}/${s3InputKey}...`);
    const s3Object = await s3
      .getObject({ Bucket: bucket, Key: s3InputKey })
      .promise();
    fs.writeFileSync(inputFile, s3Object.Body);

    // Step 2: Transcode with FFmpeg
    console.log(`Transcoding ${videoId}...`);
    const ffmpegCmd = `ffmpeg -i "${inputFile}" \\
      -filter_complex "[0:v]split=3[v1][v2][v3];[v1]scale=-2:360[v1out];[v2]scale=-2:480[v2out];[v3]scale=-2:720[v3out]" \\
      -map "[v1out]" -map 0:a -c:v:0 h264 -b:v:0 800k -c:a:0 aac -b:a:0 96k \\
      -map "[v2out]" -map 0:a -c:v:1 h264 -b:v:1 1400k -c:a:1 aac -b:a:1 128k \\
      -map "[v3out]" -map 0:a -c:v:2 h264 -b:v:2 2800k -c:a:2 aac -b:a:2 128k \\
      -f hls \\
      -hls_time 3 \\
      -hls_playlist_type vod \\
      -var_stream_map "v:0,a:0 v:1,a:1 v:2,a:2" \\
      -master_pl_name master.m3u8 \\
      -hls_segment_filename "${outputDir}/v%v/segment_%03d.ts" \\
      "${outputDir}/v%v/prog_index.m3u8" 2>&1`;

    await execAsync(ffmpegCmd);

    // Step 3: Upload HLS to S3
    console.log(`Uploading HLS to S3...`);
    const s3OutputPath = `output/videos/${videoId}`;
    await uploadDirToS3(outputDir, bucket, s3OutputPath);

    // Step 4: Create CloudFront URL
    const hlsUrl = `https://${CLOUDFRONT_DOMAIN}/${s3OutputPath}/master.m3u8`;

    // Step 5: Update Firestore
    console.log(`Updating Firestore...`);
    await updatePostWithHlsUrl(postId, mediaIndex, hlsUrl);

    // Update queue
    await db.collection("videoTranscodeQueue").doc(videoId).update({
      status: "completed",
      hlsUrl,
      completedAt: new Date(),
    });

    console.log(`✓ Video ${videoId} ready at ${hlsUrl}`);
  } finally {
    // Cleanup
    fs.rmSync(videoDir, { recursive: true, force: true });
  }
}

async function uploadDirToS3(localDir, bucket, s3Path) {
  const files = fs.readdirSync(localDir, { recursive: true });

  for (const file of files) {
    const filePath = path.join(localDir, file.toString());
    
    if (fs.statSync(filePath).isFile()) {
      const s3Key = `${s3Path}/${path.relative(localDir, filePath)}`;
      const fileContent = fs.readFileSync(filePath);

      const contentType = s3Key.endsWith(".m3u8")
        ? "application/x-mpegURL"
        : s3Key.endsWith(".ts")
          ? "video/mp2t"
          : "application/octet-stream";

      const cacheControl = s3Key.endsWith(".ts")
        ? "public, max-age=31536000, immutable"
        : "public, max-age=3600";

      await s3
        .putObject({
          Bucket: bucket,
          Key: s3Key,
          Body: fileContent,
          ContentType: contentType,
          CacheControl: cacheControl,
        })
        .promise();

      console.log(`  → ${s3Key}`);
    }
  }
}

async function updatePostWithHlsUrl(
  postId,
  mediaIndex,
  hlsUrl
) {
  await db.runTransaction(async (transaction) => {
    const postRef = db.collection("posts").doc(postId);
    const postDoc = await transaction.get(postRef);
    const post = postDoc.data();

    if (post && post.media && post.media[mediaIndex]) {
      post.media[mediaIndex].hlsUrl = hlsUrl;
      post.media[mediaIndex].status = "ready";
      transaction.update(postRef, { media: post.media });
    }
  });
}

async function markTranscodeJobFailed(
  postId,
  mediaIndex,
  videoId,
  error
) {
  await db.collection("videoTranscodeQueue").doc(videoId).update({
    status: "failed",
    error,
    failedAt: new Date(),
  });

  await db.runTransaction(async (transaction) => {
    const postRef = db.collection("posts").doc(postId);
    const postDoc = await transaction.get(postRef);
    const post = postDoc.data();

    if (post && post.media && post.media[mediaIndex]) {
      post.media[mediaIndex].status = "failed";
      transaction.update(postRef, { media: post.media });
    }
  });
}

// Process queue every 30 seconds
console.log("Starting video transcode worker...");
console.log(`CloudFront Domain: ${CLOUDFRONT_DOMAIN}`);
console.log("Polling for videos to transcode every 30 seconds...");

setInterval(processVideoQueue, 30000);

// Process immediately on start
processVideoQueue();
