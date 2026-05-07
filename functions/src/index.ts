import {onCall, HttpsError, onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {createSign} from "node:crypto";
import {
  onDocumentCreated,
} from "firebase-functions/v2/firestore";
import {S3Client, PutObjectCommand} from "@aws-sdk/client-s3";
import {getSignedUrl} from "@aws-sdk/s3-request-presigner";

admin.initializeApp();

const db = admin.firestore();
const SNOW_UID = "snow_ai";
const SNOW_NAME = "Snow AI";
const DEFAULT_SNOW_USER_COOLDOWN_HOURS = 6;
const DEFAULT_SNOW_GLOBAL_MAX_REPLIES_PER_HOUR = 10;
const DEFAULT_GOLD_PRODUCT_IDS = ["gold_subscription_monthly"];
const APPLE_API_PRODUCTION_URL = "https://api.storekit.itunes.apple.com";
const APPLE_API_SANDBOX_URL = "https://api.storekit-sandbox.itunes.apple.com";

type AppleTransactionPayload = {
  bundleId?: string;
  productId?: string;
  environment?: string;
  transactionId?: string;
  originalTransactionId?: string;
  purchaseDate?: number;
  expiresDate?: number;
  revocationDate?: number;
};

/**
 * Returns OpenAI runtime config.
 * @return {{apiKey: string, model: string}} OpenAI config
 */
function getOpenAiConfig(): {apiKey: string; model: string} {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "AI assistance is not configured on the server."
    );
  }

  return {
    apiKey,
    model: process.env.OPENAI_MODEL || "gpt-4.1",
  };
}

/**
 * Calls the OpenAI Responses API and returns plain text output.
 * @param {object} params request payload
 * @param {string} params.instructions system instructions
 * @param {string} params.input user input
 * @return {Promise<string>} generated text
 */
async function generateOpenAiText(params: {
  instructions: string;
  input: string;
}): Promise<string> {
  const config = getOpenAiConfig();
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${config.apiKey}`,
    },
    body: JSON.stringify({
      model: config.model,
      instructions: params.instructions,
      input: params.input,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("OpenAI API error:", errorText);
    throw new HttpsError("internal", "AI generation failed.");
  }

  const data = await response.json() as {output_text?: string};
  const output = data.output_text?.trim();

  if (!output) {
    throw new HttpsError("internal", "AI returned an empty response.");
  }

  return output;
}

/**
 * Returns true when a comment explicitly asks Snow.
 * @param {string} text comment text
 * @return {boolean} whether Snow should reply
 */
function shouldReplyAsSnow(text: string): boolean {
  return /(^|\s)@snow\b/i.test(text);
}

/**
 * Removes the @snow mention from a prompt body.
 * @param {string} text comment text
 * @return {string} cleaned text
 */
function stripSnowMention(text: string): string {
  return text.replace(/(^|\s)@snow\b/gi, " ").replace(/\s+/g, " ").trim();
}

/**
 * Encodes a string or buffer as base64url.
 * @param {Buffer|string} input value
 * @return {string} encoded value
 */
function toBase64Url(input: Buffer | string): string {
  return Buffer.from(input)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

/**
 * Decodes a compact JWS payload without verifying the signature.
 * @param {string} token compact JWS
 * @return {Record<string, unknown>} decoded payload
 */
function decodeJwsPayload(token: string): Record<string, unknown> {
  const parts = token.split(".");
  if (parts.length < 2) {
    throw new HttpsError("invalid-argument", "Invalid signed payload.");
  }

  const normalized = parts[1]
    .replace(/-/g, "+")
    .replace(/_/g, "/");
  const padding = normalized.length % 4;
  const padded = padding == 0 ?
    normalized :
    normalized.padEnd(normalized.length + (4 - padding), "=");

  return JSON.parse(Buffer.from(padded, "base64").toString("utf8")) as
    Record<string, unknown>;
}

/**
 * Returns direct App Store Server API config.
 * @return {{
 *   issuerId: string,
 *   keyId: string,
 *   privateKey: string,
 *   bundleId: string,
 *   productIds: string[]
 * }} config
 */
function getAppleSubscriptionConfig(): {
  issuerId: string;
  keyId: string;
  privateKey: string;
  bundleId: string;
  productIds: string[];
  } {
  const issuerId = process.env.APPLE_SUBSCRIPTION_ISSUER_ID;
  const keyId = process.env.APPLE_SUBSCRIPTION_KEY_ID;
  const privateKey = process.env.APPLE_SUBSCRIPTION_PRIVATE_KEY;
  const bundleId =
    process.env.APPLE_SUBSCRIPTION_BUNDLE_ID || "com.nextfiction.linkaiapp";
  const productIds = (
    process.env.APPLE_SUBSCRIPTION_PRODUCT_IDS ||
    DEFAULT_GOLD_PRODUCT_IDS.join(",")
  )
    .split(",")
    .map((value) => value.trim())
    .filter((value) => value.length > 0);

  if (!issuerId || !keyId || !privateKey) {
    throw new HttpsError(
      "failed-precondition",
      "Apple subscription server verification is not configured."
    );
  }

  return {
    issuerId,
    keyId,
    privateKey: privateKey.replace(/\\n/g, "\n"),
    bundleId,
    productIds,
  };
}

/**
 * Creates a signed JWT for App Store Server API requests.
 * @return {string} signed JWT
 */
function createAppleApiToken(): string {
  const config = getAppleSubscriptionConfig();
  const issuedAt = Math.floor(Date.now() / 1000);
  const expiresAt = issuedAt + (60 * 10);
  const header = {
    alg: "ES256",
    kid: config.keyId,
    typ: "JWT",
  };
  const payload = {
    iss: config.issuerId,
    iat: issuedAt,
    exp: expiresAt,
    aud: "appstoreconnect-v1",
    bid: config.bundleId,
  };

  const encodedHeader = toBase64Url(JSON.stringify(header));
  const encodedPayload = toBase64Url(JSON.stringify(payload));
  const unsignedToken = `${encodedHeader}.${encodedPayload}`;
  const signature = createSign("SHA256")
    .update(unsignedToken)
    .end()
    .sign({
      key: config.privateKey,
      dsaEncoding: "ieee-p1363",
    });

  return `${unsignedToken}.${toBase64Url(signature)}`;
}

/**
 * Loads verified App Store transaction info for a transaction identifier.
 * @param {string} transactionId transaction id
 * @return {Promise<AppleTransactionPayload>} verified payload
 */
async function fetchAppleTransactionInfo(
  transactionId: string
): Promise<AppleTransactionPayload> {
  const token = createAppleApiToken();
  const urls = [
    APPLE_API_PRODUCTION_URL,
    APPLE_API_SANDBOX_URL,
  ];

  for (const baseUrl of urls) {
    const response = await fetch(
      `${baseUrl}/inApps/v1/transactions/${transactionId}`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );

    if (response.ok) {
      const data = await response.json() as {
        signedTransactionInfo?: string;
      };
      const signedInfo = data.signedTransactionInfo;
      if (!signedInfo) {
        throw new HttpsError(
          "internal",
          "Missing signed transaction info from Apple."
        );
      }
      return decodeJwsPayload(signedInfo) as AppleTransactionPayload;
    }

    if (response.status === 404) {
      continue;
    }

    const errorText = await response.text();
    console.error("Apple transaction lookup failed:", errorText);
    throw new HttpsError(
      "internal",
      "Failed to verify the App Store transaction."
    );
  }

  throw new HttpsError(
    "not-found",
    "Transaction was not found in App Store environments."
  );
}

/**
 * Loads Snow mention settings from app config with safe defaults.
 * @return {Promise<{
 *   userCooldownHours: number,
 *   globalMaxRepliesPerHour: number
 * }>}
 */
async function getSnowMentionSettings(): Promise<{
  userCooldownHours: number;
  globalMaxRepliesPerHour: number;
}> {
  const snapshot = await db.collection("appConfig").doc("global").get();
  const data = snapshot.data() || {};

  const userCooldownHours =
    typeof data.snowAiUserCooldownHours === "number" &&
      data.snowAiUserCooldownHours > 0 ?
      data.snowAiUserCooldownHours :
      DEFAULT_SNOW_USER_COOLDOWN_HOURS;

  const globalMaxRepliesPerHour =
    typeof data.snowAiGlobalMaxRepliesPerHour === "number" &&
      data.snowAiGlobalMaxRepliesPerHour > 0 ?
      data.snowAiGlobalMaxRepliesPerHour :
      DEFAULT_SNOW_GLOBAL_MAX_REPLIES_PER_HOUR;

  return {
    userCooldownHours,
    globalMaxRepliesPerHour,
  };
}

/**
 * Reserves a Snow reply slot with idempotency and rate limiting.
 * @param {object} params input
 * @param {string} params.commentId comment id
 * @param {string} params.authorUid author uid
 * @param {number} params.userCooldownHours per-user cooldown
 * @param {number} params.globalMaxRepliesPerHour global hourly cap
 * @return {Promise<boolean>} whether Snow may proceed
 */
async function reserveSnowReply(params: {
  commentId: string;
  authorUid: string;
  userCooldownHours: number;
  globalMaxRepliesPerHour: number;
}): Promise<boolean> {
  const replyRef = db.collection("snowAiReplies").doc(params.commentId);
  const userUsageRef = db.collection("snowAiUserUsage").doc(params.authorUid);
  const globalUsageRef = db.collection("snowAiUsage").doc("global");
  const now = admin.firestore.Timestamp.now();
  const nowMs = now.toMillis();
  const cooldownMs = params.userCooldownHours * 60 * 60 * 1000;
  const windowMs = 60 * 60 * 1000;

  return db.runTransaction(async (transaction) => {
    const [replySnap, userUsageSnap, globalUsageSnap] = await Promise.all([
      transaction.get(replyRef),
      transaction.get(userUsageRef),
      transaction.get(globalUsageRef),
    ]);

    if (replySnap.exists) {
      return false;
    }

    const userUsage = userUsageSnap.data() || {};
    const lastReplyAt = userUsage.lastReplyAt as
      | admin.firestore.Timestamp
      | undefined;
    if (lastReplyAt && nowMs - lastReplyAt.toMillis() < cooldownMs) {
      return false;
    }

    const globalUsage = globalUsageSnap.data() || {};
    const windowStartedAt = globalUsage.windowStartedAt as
      | admin.firestore.Timestamp
      | undefined;
    const currentCount = typeof globalUsage.replyCount === "number" ?
      globalUsage.replyCount :
      0;

    const isSameWindow = windowStartedAt &&
      nowMs - windowStartedAt.toMillis() < windowMs;
    const nextCount = isSameWindow ? currentCount + 1 : 1;

    if (isSameWindow && currentCount >= params.globalMaxRepliesPerHour) {
      return false;
    }

    transaction.set(replyRef, {
      commentId: params.commentId,
      authorUid: params.authorUid,
      status: "pending",
      createdAt: now,
      updatedAt: now,
    });

    transaction.set(userUsageRef, {
      uid: params.authorUid,
      lastReplyAt: now,
      updatedAt: now,
    }, {merge: true});

    transaction.set(globalUsageRef, {
      windowStartedAt: isSameWindow ? windowStartedAt : now,
      replyCount: nextCount,
      updatedAt: now,
    }, {merge: true});

    return true;
  });
}

/**
 * Loads prompt context for a Snow reply.
 * @param {object} params input
 * @param {string} params.postId post id
 * @param {string=} params.parentCommentId parent comment id
 * @return {Promise<string>} compact context string
 */
async function buildSnowThreadContext(params: {
  postId: string;
  parentCommentId?: string;
}): Promise<string> {
  const contextParts: string[] = [];

  if (params.parentCommentId) {
    const parentSnapshot = await db
      .collection("posts")
      .doc(params.postId)
      .collection("comments")
      .doc(params.parentCommentId)
      .get();

    if (parentSnapshot.exists) {
      const parent = parentSnapshot.data() || {};
      const parentAuthor = (parent.authorName as string | undefined) || "User";
      const parentText = (parent.text as string | undefined)?.trim() || "";
      if (parentText) {
        contextParts.push(
          `Parent comment by ${parentAuthor}: ${parentText}`
        );
      }
    }
  }

  const recentCommentsSnapshot = await db
    .collection("posts")
    .doc(params.postId)
    .collection("comments")
    .orderBy("createdAt", "desc")
    .limit(4)
    .get();

  const recentComments = recentCommentsSnapshot.docs
    .map((doc) => doc.data())
    .filter((item) => item.authorUid !== SNOW_UID)
    .map((item) => {
      const author = (item.authorName as string | undefined) || "User";
      const text = (item.text as string | undefined)?.trim() || "";
      return text ? `${author}: ${text}` : "";
    })
    .filter((item) => item.length > 0);

  if (recentComments.length > 0) {
    contextParts.push(`Recent discussion:\n${recentComments.join("\n")}`);
  }

  return contextParts.join("\n\n");
}

/**
 * Returns whether a user currently has an active Gold subscription.
 * @param {string} uid user id
 * @return {Promise<boolean>} whether gold is active
 */
async function isUserGoldSubscriber(uid: string): Promise<boolean> {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .collection("subscription")
    .doc("data")
    .get();

  if (!snapshot.exists) {
    return false;
  }

  const data = snapshot.data() || {};
  const isGold = data.isGoldSubscriber === true;
  const expiresAt = data.expiresAt as admin.firestore.Timestamp | undefined;

  if (!isGold) {
    return false;
  }

  return !expiresAt || expiresAt.toMillis() > Date.now();
}

/**
 * Loads all FCM tokens for a user.
 * @param {string} uid user id
 * @return {Promise<string[]>} FCM tokens
 */
async function getUserTokens(uid: string): Promise<string[]> {
  const snapshot = await admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("fcmTokens")
    .get();

  return snapshot.docs
    .map((doc) => doc.data().token as string | undefined)
    .filter((token): token is string => Boolean(token));
}

/**
 * Creates an in-app notification doc and sends a push notification.
 * @param {object} params notification payload
 */
async function createNotification(params: {
  receiverUid: string;
  senderUid: string;
  senderName: string;
  senderAvatarUrl?: string | null;
  type: string;
  title: string;
  body: string;
  postId?: string | null;
  productId?: string | null;
}) {
  if (params.receiverUid === params.senderUid) {
    return;
  }

  const notificationRef = admin.firestore().collection("notifications").doc();

  await notificationRef.set({
    id: notificationRef.id,
    receiverUid: params.receiverUid,
    senderUid: params.senderUid,
    senderName: params.senderName,
    senderAvatarUrl: params.senderAvatarUrl || null,
    type: params.type,
    title: params.title,
    body: params.body,
    postId: params.postId || null,
    productId: params.productId || null,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const tokens = await getUserTokens(params.receiverUid);

  if (tokens.length === 0) {
    return;
  }

  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: params.title,
      body: params.body,
    },
    data: {
      type: params.type,
      postId: params.postId || "",
      productId: params.productId || "",
    },
  });
}

/**
 * Best-effort profile lookup used for notification sender labels.
 * @param {string} uid user id
 * @return {Promise<Object>} safe sender fields
 */
async function getProfileSafe(uid: string) {
  const snapshot = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();

  if (!snapshot.exists) {
    return {
      name: "Someone",
      avatarUrl: null,
    };
  }

  const data = snapshot.data() || {};

  return {
    name: data.name || "Someone",
    avatarUrl: data.avatarUrl || null,
  };
}

/**
 * Syncs a Gold entitlement from a verified App Store transaction.
 */
export const syncGoldSubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const uid = request.auth.uid;
  const purchaseSource =
    (request.data.purchaseSource as string | undefined)?.trim() || "";
  const productId =
    (request.data.productId as string | undefined)?.trim() || "";
  const transactionIdInput =
    (request.data.transactionId as string | undefined)?.trim() || "";
  const serverVerificationData =
    (request.data.serverVerificationData as string | undefined)?.trim() || "";

  if (purchaseSource !== "app_store") {
    throw new HttpsError(
      "failed-precondition",
      "Direct Gold verification is configured for App Store only."
    );
  }

  const config = getAppleSubscriptionConfig();
  if (!config.productIds.includes(productId)) {
    throw new HttpsError("invalid-argument", "Unsupported product id.");
  }

  const fallbackPayload = serverVerificationData ?
    decodeJwsPayload(serverVerificationData) :
    null;
  const transactionId = transactionIdInput ||
    (typeof fallbackPayload?.transactionId === "string" ?
      fallbackPayload.transactionId :
      "");

  if (!transactionId) {
    throw new HttpsError(
      "invalid-argument",
      "Transaction id is required for App Store verification."
    );
  }

  const payload = await fetchAppleTransactionInfo(transactionId);
  if (payload.bundleId !== config.bundleId) {
    throw new HttpsError("permission-denied", "Bundle id mismatch.");
  }
  if (payload.productId !== productId) {
    throw new HttpsError("permission-denied", "Product id mismatch.");
  }

  const expiresAtMs =
    typeof payload.expiresDate === "number" ? payload.expiresDate : null;
  const purchaseDateMs =
    typeof payload.purchaseDate === "number" ? payload.purchaseDate : null;
  const revoked = typeof payload.revocationDate === "number";
  const isActive = !revoked &&
    (!expiresAtMs || expiresAtMs > Date.now());
  const subscriptionStatus = revoked ?
    "revoked" :
    isActive ?
      "active" :
      "expired";

  await db
    .collection("users")
    .doc(uid)
    .collection("subscription")
    .doc("data")
    .set({
      uid,
      productId,
      purchaseId: payload.originalTransactionId || transactionId,
      transactionId: payload.transactionId || transactionId,
      originalTransactionId: payload.originalTransactionId || transactionId,
      provider: "app_store",
      environment: payload.environment || "unknown",
      isGoldSubscriber: isActive,
      subscribedAt: purchaseDateMs ?
        admin.firestore.Timestamp.fromMillis(purchaseDateMs) :
        admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresAtMs ?
        admin.firestore.Timestamp.fromMillis(expiresAtMs) :
        null,
      subscriptionStatus,
      verificationSource: "app_store_server_api",
      lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

  return {
    isActive,
    subscriptionStatus,
    expiresAt: expiresAtMs ?
      new Date(expiresAtMs).toISOString() :
      null,
  };
});

export const onPostLikeCreated = onDocumentCreated(
  "postLikes/{likeId}",
  async (event) => {
    const like = event.data?.data();

    if (!like) return;

    const postId = like.postId as string;
    const senderUid = like.uid as string;

    const postSnapshot = await admin
      .firestore()
      .collection("posts")
      .doc(postId)
      .get();

    if (!postSnapshot.exists) return;

    const post = postSnapshot.data() || {};
    const receiverUid = post.authorUid as string;

    const senderProfile = await getProfileSafe(senderUid);

    await createNotification({
      receiverUid,
      senderUid,
      senderName: senderProfile.name,
      senderAvatarUrl: senderProfile.avatarUrl,
      type: "post_like",
      title: "New like",
      body: `${senderProfile.name} liked your post.`,
      postId,
    });
  }
);

export const onPostRepostCreated = onDocumentCreated(
  "postReposts/{repostId}",
  async (event) => {
    const repost = event.data?.data();

    if (!repost) return;

    const postId = repost.postId as string;
    const senderUid = repost.uid as string;

    const postSnapshot = await admin
      .firestore()
      .collection("posts")
      .doc(postId)
      .get();

    if (!postSnapshot.exists) return;

    const post = postSnapshot.data() || {};
    const receiverUid = post.authorUid as string;

    const senderProfile = await getProfileSafe(senderUid);

    await createNotification({
      receiverUid,
      senderUid,
      senderName: senderProfile.name,
      senderAvatarUrl: senderProfile.avatarUrl,
      type: "post_repost",
      title: "New repost",
      body: `${senderProfile.name} reposted your post.`,
      postId,
    });
  }
);

export const onPostSaveCreated = onDocumentCreated(
  "postSaves/{saveId}",
  async (event) => {
    const save = event.data?.data();

    if (!save) return;

    const postId = save.postId as string;
    const senderUid = save.uid as string;

    const postSnapshot = await admin
      .firestore()
      .collection("posts")
      .doc(postId)
      .get();

    if (!postSnapshot.exists) return;

    const post = postSnapshot.data() || {};
    const receiverUid = post.authorUid as string;

    const senderProfile = await getProfileSafe(senderUid);

    await createNotification({
      receiverUid,
      senderUid,
      senderName: senderProfile.name,
      senderAvatarUrl: senderProfile.avatarUrl,
      type: "post_save",
      title: "Post saved",
      body: `${senderProfile.name} saved your post.`,
      postId,
    });
  }
);

export const onPostCommentCreated = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const comment = event.data?.data();

    if (!comment) return;

    const postId = event.params.postId;
    const senderUid = comment.authorUid as string;

    const postSnapshot = await admin
      .firestore()
      .collection("posts")
      .doc(postId)
      .get();

    if (!postSnapshot.exists) return;

    const post = postSnapshot.data() || {};
    const receiverUid = post.authorUid as string;

    const senderName = comment.authorName || "Someone";
    const senderAvatarUrl = comment.authorAvatarUrl || null;

    await createNotification({
      receiverUid,
      senderUid,
      senderName,
      senderAvatarUrl,
      type: "post_comment",
      title: "New comment",
      body: `${senderName} commented on your post.`,
      postId,
    });
  }
);

export const onSnowMentionCommentCreated = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const comment = event.data?.data();

    if (!comment) return;

    const postId = event.params.postId;
    const commentId = event.params.commentId;
    const authorUid = comment.authorUid as string | undefined;
    const rawText = (comment.text as string | undefined)?.trim() || "";
    const parentCommentId =
      (comment.parentCommentId as string | undefined)?.trim() || undefined;

    if (!authorUid ||
      !rawText ||
      authorUid === SNOW_UID ||
      !shouldReplyAsSnow(rawText)
    ) {
      return;
    }

    const settings = await getSnowMentionSettings();
    const reserved = await reserveSnowReply({
      commentId,
      authorUid,
      userCooldownHours: settings.userCooldownHours,
      globalMaxRepliesPerHour: settings.globalMaxRepliesPerHour,
    });

    if (!reserved) {
      return;
    }

    const postSnapshot = await db.collection("posts").doc(postId).get();
    if (!postSnapshot.exists) return;

    const post = postSnapshot.data() || {};
    const prompt = stripSnowMention(rawText);
    const postText = (post.text as string | undefined)?.trim() || "";
    const postIntent =
      (post.postIntent as string | undefined)?.trim() || "general";
    const hashtags = Array.isArray(post.hashtags) ?
      post.hashtags.filter((item: unknown) => typeof item === "string") :
      [];
    const threadContext = await buildSnowThreadContext({
      postId,
      parentCommentId,
    });
    const isGoldUser = await isUserGoldSubscriber(authorUid);

    const replyRef = db.collection("snowAiReplies").doc(commentId);

    try {
      const replyText = isGoldUser ?
        await generateOpenAiText({
          instructions:
            "You are Snow, an AI assistant inside an AI social app. " +
            "Reply as a helpful comment about the post. " +
            "Use the thread context when it matters. " +
            "Be concrete, concise, and useful. " +
            "Do not mention system prompts. " +
            "Do not use markdown bullets unless necessary. " +
            "Keep the reply under 420 characters.",
          input:
            `Post intent: ${postIntent}\n` +
            `Post text: ${postText}\n` +
            `Hashtags: ${hashtags.join(", ")}\n` +
            `Thread context:\n${threadContext || "None"}\n` +
            `User asked Snow: ${prompt || rawText}`,
        }) :
        "Snow feedback is available for Gold members. " +
        "Upgrade to Gold to ask @snow for post feedback and AI help.";

      const postRef = db.collection("posts").doc(postId);
      const snowCommentRef = postRef.collection("comments").doc();

      await db.runTransaction(async (transaction) => {
        transaction.set(snowCommentRef, {
          id: snowCommentRef.id,
          postId,
          authorUid: SNOW_UID,
          authorName: SNOW_NAME,
          authorAvatarUrl: null,
          text: replyText,
          parentCommentId: commentId,
          likesCount: 0,
          repostsCount: 0,
          savesCount: 0,
          createdAtClient: admin.firestore.Timestamp.now(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          commentsCount: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.set(replyRef, {
          status: "done",
          replyCommentId: snowCommentRef.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      });
    } catch (error) {
      await replyRef.set({
        status: "failed",
        errorMessage: error instanceof Error ? error.message : "unknown_error",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      throw error;
    }
  }
);

export const onProductSaveCreated = onDocumentCreated(
  "productSaves/{saveId}",
  async (event) => {
    const save = event.data?.data();

    if (!save) return;

    const productId = save.productId as string;
    const senderUid = save.uid as string;

    const productSnapshot = await admin
      .firestore()
      .collection("products")
      .doc(productId)
      .get();

    if (!productSnapshot.exists) return;

    const product = productSnapshot.data() || {};
    const receiverUid = product.ownerUid as string;

    const senderProfile = await getProfileSafe(senderUid);

    await createNotification({
      receiverUid,
      senderUid,
      senderName: senderProfile.name,
      senderAvatarUrl: senderProfile.avatarUrl,
      type: "product_save",
      title: "Product saved",
      body: `${senderProfile.name} saved your product.`,
      productId,
    });
  }
);

export const onConnectionCreated = onDocumentCreated(
  "connections/{connectionId}",
  async (event) => {
    const connection = event.data?.data();

    if (!connection) return;

    const receiverUid = connection.connectedUid as string;
    const senderUid = connection.userUid as string;
    const senderProfile = await getProfileSafe(senderUid);

    await createNotification({
      receiverUid,
      senderUid,
      senderName: senderProfile.name,
      senderAvatarUrl: senderProfile.avatarUrl,
      type: "new_follower",
      title: "New follower",
      body: `${senderProfile.name} followed you.`,
    });
  }
);

/**
 * Queues a decrement against a counter doc only if the doc still exists.
 * @param {FirebaseFirestore.WriteBatch} batch write batch
 * @param {FirebaseFirestore.DocumentReference} ref target doc ref
 * @param {string} field counter field
 * @return {Promise<number>} number of queued writes
 */
async function queueDecrementIfExists(
  batch: FirebaseFirestore.WriteBatch,
  ref: FirebaseFirestore.DocumentReference,
  field: string
): Promise<number> {
  const snapshot = await ref.get();

  if (!snapshot.exists) {
    return 0;
  }

  const data = snapshot.data() || {};
  const currentValue = typeof data[field] === "number" ? data[field] : 0;

  batch.update(ref, {
    [field]: currentValue > 0 ? currentValue - 1 : 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return 1;
}

/**
 * Deletes query results in batches and optionally runs extra batched work.
 * @param {FirebaseFirestore.Query} query firestore query
 * @param {Function} beforeDelete optional hook before each delete
 * @return {Promise<void>}
 */
async function deleteDocsByQuery(
  query: FirebaseFirestore.Query,
  beforeDelete?: (
    batch: FirebaseFirestore.WriteBatch,
    doc: FirebaseFirestore.QueryDocumentSnapshot
  ) => Promise<number>
): Promise<void> {
  const snapshot = await query.get();

  if (snapshot.empty) {
    return;
  }

  let batch = db.batch();
  let operationCount = 0;

  for (const doc of snapshot.docs) {
    if (beforeDelete) {
      operationCount += await beforeDelete(batch, doc);
    }

    batch.delete(doc.ref);
    operationCount += 1;

    if (operationCount >= 350) {
      await batch.commit();
      batch = db.batch();
      operationCount = 0;
    }
  }

  if (operationCount > 0) {
    await batch.commit();
  }
}

/**
 * Deletes all FCM tokens stored for a user.
 * @param {string} uid user id
 * @return {Promise<void>}
 */
async function deleteUserTokens(uid: string): Promise<void> {
  const tokensSnapshot = await db
    .collection("users")
    .doc(uid)
    .collection("fcmTokens")
    .get();

  if (tokensSnapshot.empty) {
    return;
  }

  const batch = db.batch();

  for (const doc of tokensSnapshot.docs) {
    batch.delete(doc.ref);
  }

  await batch.commit();
}

/**
 * Deletes all posts created by a user, including subcollections and reactions.
 * @param {string} uid user id
 * @return {Promise<void>}
 */
async function deleteOwnedPosts(uid: string): Promise<void> {
  const postsSnapshot = await db
    .collection("posts")
    .where("authorUid", "==", uid)
    .get();

  for (const postDoc of postsSnapshot.docs) {
    const postId = postDoc.id;

    await deleteDocsByQuery(
      db.collection("postLikes").where("postId", "==", postId)
    );
    await deleteDocsByQuery(
      db.collection("postReposts").where("postId", "==", postId)
    );
    await deleteDocsByQuery(
      db.collection("postSaves").where("postId", "==", postId)
    );
    await deleteDocsByQuery(
      db.collection("reports").where("postId", "==", postId)
    );

    await db.recursiveDelete(postDoc.ref);
  }
}

/**
 * Deletes all products owned by a user and their save records.
 * @param {string} uid user id
 * @return {Promise<void>}
 */
async function deleteOwnedProducts(uid: string): Promise<void> {
  const productsSnapshot = await db
    .collection("products")
    .where("ownerUid", "==", uid)
    .get();

  for (const productDoc of productsSnapshot.docs) {
    const productId = productDoc.id;

    await deleteDocsByQuery(
      db.collection("productSaves").where("productId", "==", productId)
    );

    await productDoc.ref.delete();
  }
}

/**
 * Deletes all user-authored comments that live on other users' posts.
 * @param {string} uid user id
 * @return {Promise<void>}
 */
async function deleteCommentsByAuthor(uid: string): Promise<void> {
  await deleteDocsByQuery(
    db.collectionGroup("comments").where("authorUid", "==", uid),
    async (batch, doc) => {
      const postRef = doc.ref.parent.parent;

      if (!postRef) {
        return 0;
      }

      return queueDecrementIfExists(batch, postRef, "commentsCount");
    }
  );
}

/**
 * Deletes reaction and save records created by a user.
 * @param {string} uid user id
 * @return {Promise<void>}
 */
async function deleteUserEngagement(uid: string): Promise<void> {
  await deleteDocsByQuery(
    db.collection("postLikes").where("uid", "==", uid),
    async (batch, doc) => {
      const postId = doc.data().postId as string | undefined;

      if (!postId) {
        return 0;
      }

      return queueDecrementIfExists(
        batch,
        db.collection("posts").doc(postId),
        "likesCount"
      );
    }
  );

  await deleteDocsByQuery(
    db.collection("postReposts").where("uid", "==", uid),
    async (batch, doc) => {
      const postId = doc.data().postId as string | undefined;

      if (!postId) {
        return 0;
      }

      return queueDecrementIfExists(
        batch,
        db.collection("posts").doc(postId),
        "repostsCount"
      );
    }
  );

  await deleteDocsByQuery(
    db.collection("postSaves").where("uid", "==", uid),
    async (batch, doc) => {
      const postId = doc.data().postId as string | undefined;

      if (!postId) {
        return 0;
      }

      return queueDecrementIfExists(
        batch,
        db.collection("posts").doc(postId),
        "savesCount"
      );
    }
  );

  await deleteDocsByQuery(
    db.collection("productSaves").where("uid", "==", uid),
    async (batch, doc) => {
      const productId = doc.data().productId as string | undefined;

      if (!productId) {
        return 0;
      }

      return queueDecrementIfExists(
        batch,
        db.collection("products").doc(productId),
        "savesCount"
      );
    }
  );
}

/**
 * Deletes simple user-scoped query results across top-level collections.
 * @param {string} uid user id
 * @return {Promise<void>}
 */
async function deleteSimpleUserData(uid: string): Promise<void> {
  await deleteDocsByQuery(db.collection("reports").where(
    "reporterUid",
    "==",
    uid
  ));
  await deleteDocsByQuery(db.collection("reports").where(
    "targetUid",
    "==",
    uid
  ));
  await deleteDocsByQuery(db.collection("notifications").where(
    "receiverUid",
    "==",
    uid
  ));
  await deleteDocsByQuery(db.collection("notifications").where(
    "senderUid",
    "==",
    uid
  ));
  await deleteDocsByQuery(db.collection("connections").where(
    "userUid",
    "==",
    uid
  ));
  await deleteDocsByQuery(db.collection("connections").where(
    "connectedUid",
    "==",
    uid
  ));
  await deleteDocsByQuery(db.collection("userBlocks").where(
    "blockerUid",
    "==",
    uid
  ));
  await deleteDocsByQuery(db.collection("userBlocks").where(
    "blockedUid",
    "==",
    uid
  ));
}

/**
 * Deletes all account data for the current user.
 */
export const deleteMyAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const uid = request.auth.uid;

  await deleteOwnedPosts(uid);
  await deleteOwnedProducts(uid);
  await deleteCommentsByAuthor(uid);
  await deleteUserEngagement(uid);
  await deleteSimpleUserData(uid);
  await deleteUserTokens(uid);

  await Promise.all([
    db.collection("profiles").doc(uid).delete().catch(() => undefined),
    db.collection("userModeration").doc(uid).delete().catch(() => undefined),
    db.collection("userSettings").doc(uid).delete().catch(() => undefined),
    db
      .collection("userConnectionStats")
      .doc(uid)
      .delete()
      .catch(() => undefined),
  ]);

  await admin.auth().deleteUser(uid);

  return {success: true};
});

/**
 * Optional external webhook for syncing subscription updates.
 */
export const subscriptionWebhook = onRequest(async (request, response) => {
  try {
    // Verify webhook signature (implement RevenueCat signature verification)
    const event = request.body.event;

    if (!event || !event.app_user_id) {
      response.status(400).send({error: "Missing required fields"});
      return;
    }

    const uid = event.app_user_id;
    const thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    const expiresDateMs = event.expiration_date_ms || Date.now() + thirtyDaysMs;

    // Create or update subscription document
    const subscriptionRef = db
      .collection("users")
      .doc(uid)
      .collection("subscription")
      .doc("data");

    await subscriptionRef.set({
      uid,
      isGoldSubscriber: true,
      purchaseId: event.transaction_id,
      subscribedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(expiresDateMs),
      subscriptionStatus: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    response.json({success: true});
  } catch (error) {
    console.error("Subscription webhook error:", error);
    response.status(500).json({error: "Internal server error"});
  }
});

/**
 * Generates AI response from @snow chatbot using Gemini API.
 * Called by client to get AI responses.
 */
export const snowAiResponse = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const uid = request.auth.uid;
  const userMessage = request.data.message as string;
  const history = Array.isArray(request.data.messages) ?
    request.data.messages.filter((item: unknown) =>
      typeof item === "object" &&
      item !== null &&
      typeof (item as {role?: unknown}).role === "string" &&
      typeof (item as {text?: unknown}).text === "string"
    ) as Array<{role: string; text: string}> :
    [];

  if (!userMessage || userMessage.trim().length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Message cannot be empty.",
    );
  }

  if (!(await isUserGoldSubscriber(uid))) {
    throw new HttpsError(
      "permission-denied",
      "Gold subscription required.",
    );
  }

  try {
    const historyText = history
      .slice(-8)
      .map((item) => `${item.role}: ${item.text}`)
      .join("\n");
    const response = await generateOpenAiText({
      instructions:
        "You are Snow, an AI assistant inside AI Links. " +
        "Be concise, useful, and practical. " +
        "Focus on AI products, builders, feedback, growth, and networking. " +
        "Do not claim actions you cannot take. " +
        "Return only the assistant reply.",
      input:
        `Conversation so far:\n${historyText}\n\n` +
        `User: ${userMessage.trim()}`,
    });

    return {
      success: true,
      response,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error("Snow AI error:", error);
    throw new HttpsError("internal", "Failed to generate response.");
  }
});

/**
 * Improves a profile bio or building summary using AI.
 */
export const improveProfileText = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const field = (request.data.field as string | undefined)?.trim();
  const name = (request.data.name as string | undefined)?.trim() || "";
  const role = (request.data.role as string | undefined)?.trim() || "";
  const skills = Array.isArray(request.data.skills) ?
    request.data.skills.filter((item: unknown) => typeof item === "string") :
    [];
  const tools = Array.isArray(request.data.tools) ?
    request.data.tools.filter((item: unknown) => typeof item === "string") :
    [];
  const building = (request.data.building as string | undefined)?.trim() || "";
  const need = (request.data.need as string | undefined)?.trim() || "";
  const currentText =
    (request.data.currentText as string | undefined)?.trim() || "";

  if (field !== "bio" && field !== "building") {
    throw new HttpsError("invalid-argument", "Unsupported profile field.");
  }

  const instructions = field === "bio" ?
    "Rewrite the user's profile bio for an AI networking app. " +
      "Keep it professional, clear, and compact. " +
      "Return only the final bio text in 2 short sentences, max 220 chars." :
    "Rewrite the user's 'what are you building' text for an AI networking " +
      "app. Keep it concise, concrete, and useful for collaborators. " +
      "Return only the final text in 1-2 short sentences, max 220 chars.";

  const input =
    `Name: ${name}\n` +
    `Role: ${role}\n` +
    `Skills: ${skills.join(", ")}\n` +
    `Tools: ${tools.join(", ")}\n` +
    `Building: ${building}\n` +
    `Need: ${need}\n` +
    `Current ${field}: ${currentText}`;

  const text = await generateOpenAiText({
    instructions,
    input,
  });

  return {text};
});

/**
 * Improves a post draft using AI.
 */
export const improvePostDraft = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const intent =
    (request.data.intent as string | undefined)?.trim() || "general";
  const text = (request.data.text as string | undefined)?.trim() || "";

  if (!text) {
    throw new HttpsError("invalid-argument", "Post text is required.");
  }

  const improvedText = await generateOpenAiText({
    instructions:
      "Rewrite the user's social post for an AI networking app. " +
      "Preserve the meaning, improve clarity, and keep the tone natural. " +
      "Do not add emojis unless the user already used them. " +
      "Keep it under 280 characters. Return only the final post text.",
    input:
      `Post intent: ${intent}\n` +
      `Draft post:\n${text}`,
  });

  return {text: improvedText};
});

/**
 * Suggests a few hashtags for a post draft.
 */
export const suggestPostTags = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const intent =
    (request.data.intent as string | undefined)?.trim() || "general";
  const text = (request.data.text as string | undefined)?.trim() || "";

  if (!text) {
    throw new HttpsError("invalid-argument", "Post text is required.");
  }

  const rawTags = await generateOpenAiText({
    instructions:
      "Suggest 3 to 5 short hashtags for the user's AI social post. " +
      "Return only hashtags separated by commas. " +
      "No explanation. Do not repeat tags already present in the text.",
    input:
      `Post intent: ${intent}\n` +
      `Draft post:\n${text}`,
  });

  const tags = rawTags
    .split(",")
    .map((tag) => tag.trim())
    .filter((tag) => tag.startsWith("#"))
    .filter((tag) => tag.length > 1)
    .slice(0, 5);

  return {tags};
});

/**
 * Validates if a user has access to gold-only features.
 * Called by client for feature authorization checks.
 */
export const validateGoldFeatures = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Login required.",
    );
  }

  const uid = request.auth.uid;
  const featureName = request.data.feature as string;

  if (!featureName) {
    throw new HttpsError(
      "invalid-argument",
      "Feature name required.",
    );
  }

  // List of gold-only features
  const goldFeatures = ["snow_chat", "ai_responses"];

  if (!goldFeatures.includes(featureName)) {
    return {allowed: true}; // Feature is not restricted
  }

  // Check subscription status
  const subRef = db
    .collection("users")
    .doc(uid)
    .collection("subscription")
    .doc("data");
  const subSnapshot = await subRef.get();

  if (!subSnapshot.exists) {
    return {allowed: false, reason: "No active subscription"};
  }

  const subscription = subSnapshot.data();
  const expiresAt = subscription?.expiresAt?.toDate?.() || new Date(0);
  const isActive = subscription?.isGoldSubscriber && new Date() <= expiresAt;

  return {
    allowed: isActive,
    reason: isActive ? undefined : "Subscription expired or invalid",
  };
});

/**
 * Generates a presigned S3 upload URL for direct client-to-S3 uploads.
 * AWS credentials are stored in Firebase Secret Manager, never exposed.
 */
export const generateS3UploadUrl = onCall(async (request) => {
  const {path, contentType, idToken} = request.data as {
    path: string;
    contentType: string;
    idToken?: string;
  };

  let uid = request.auth?.uid;

  if (!uid && idToken && typeof idToken === "string") {
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      uid = decoded.uid;
    } catch (error) {
      console.error("Invalid fallback ID token for S3 upload:", error);
    }
  }

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "Must be signed in to upload files."
    );
  }

  if (!path || typeof path !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "path is required and must be a string"
    );
  }
  if (!contentType || typeof contentType !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "contentType is required and must be a string"
    );
  }

  if (!path.startsWith(`postMedia/${uid}/`) &&
      !path.startsWith(`profileMedia/${uid}/`) &&
      !path.startsWith(`productMedia/${uid}/`)) {
    throw new HttpsError(
      "permission-denied",
      "You can only upload to your own media path."
    );
  }

  try {
    const region = process.env.AWS_REGION || "us-east-1";
    const bucket = process.env.S3_BUCKET;
    const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

    if (!bucket || !accessKeyId || !secretAccessKey) {
      throw new HttpsError(
        "failed-precondition",
        "S3 upload is not configured on the server."
      );
    }

    const s3Client = new S3Client({
      region,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
    });

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: path,
      ContentType: contentType,
    });

    const presignedUrl = await getSignedUrl(s3Client, command, {
      expiresIn: 300,
    });
    const publicUrl =
      `https://${bucket}.s3.${region}.amazonaws.com/${path}`;

    return {
      presignedUrl,
      publicUrl,
    };
  } catch (error) {
    console.error("Error generating S3 upload URL:", error);
    throw new HttpsError("internal", "Failed to generate upload URL");
  }
});

export const generateS3UploadUrlHttp = onRequest({
  invoker: "public",
}, async (request, response) => {
  response.set("Access-Control-Allow-Origin", "*");
  response.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  response.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (request.method === "OPTIONS") {
    response.status(204).send("");
    return;
  }

  if (request.method !== "POST") {
    response.status(405).json({error: "Method not allowed"});
    return;
  }

  const authHeader = request.get("Authorization") || "";
  const bearerToken = authHeader.startsWith("Bearer ") ?
    authHeader.substring("Bearer ".length) :
    "";

  if (!bearerToken) {
    response.status(401).json({error: "Missing bearer token"});
    return;
  }

  try {
    const decoded = await admin.auth().verifyIdToken(bearerToken);
    const uid = decoded.uid;
    const {path, contentType} = request.body as {
      path?: string;
      contentType?: string;
    };

    if (!path || typeof path !== "string") {
      response.status(400).json({
        error: "path is required and must be a string",
      });
      return;
    }
    if (!contentType || typeof contentType !== "string") {
      response.status(400).json({
        error: "contentType is required and must be a string",
      });
      return;
    }

    if (!path.startsWith(`postMedia/${uid}/`) &&
        !path.startsWith(`profileMedia/${uid}/`) &&
        !path.startsWith(`productMedia/${uid}/`)) {
      response.status(403).json({error: "Forbidden upload path"});
      return;
    }

    const region = process.env.AWS_REGION || "us-east-1";
    const bucket = process.env.S3_BUCKET;
    const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

    if (!bucket || !accessKeyId || !secretAccessKey) {
      response.status(500).json({error: "S3 upload is not configured"});
      return;
    }

    const s3Client = new S3Client({
      region,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
    });

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: path,
      ContentType: contentType,
    });

    const presignedUrl = await getSignedUrl(s3Client, command, {
      expiresIn: 300,
    });
    const publicUrl = `https://${bucket}.s3.${region}.amazonaws.com/${path}`;

    response.status(200).json({
      presignedUrl,
      publicUrl,
    });
  } catch (error) {
    console.error("Error generating S3 upload URL via HTTP:", error);
    response.status(401).json({error: "Unauthenticated"});
  }
});
