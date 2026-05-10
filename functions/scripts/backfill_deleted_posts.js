const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function loadCredential() {
  const candidatePaths = [
    process.env.GOOGLE_APPLICATION_CREDENTIALS,
    path.join(__dirname, "serviceAccountKey.json"),
  ].filter(Boolean);

  for (const candidatePath of candidatePaths) {
    if (fs.existsSync(candidatePath)) {
      const serviceAccount = require(candidatePath);
      return admin.credential.cert(serviceAccount);
    }
  }

  return admin.credential.applicationDefault();
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: loadCredential(),
  });
}

const db = admin.firestore();
const PAGE_SIZE = 400;
const isDryRun = process.argv.includes("--dry-run");

async function backfillDeletedField() {
  console.log(
    `Starting deleted=false backfill for all posts${isDryRun ? " (dry run)" : ""}...`,
  );

  let lastDoc = null;
  let scanned = 0;
  let updated = 0;
  let page = 0;

  while (true) {
    let query = db
      .collection("posts")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    page += 1;
    scanned += snapshot.size;

    const docsToUpdate = snapshot.docs.filter(
      (doc) => doc.get("deleted") === undefined,
    );

    if (docsToUpdate.length > 0 && !isDryRun) {
      const batch = db.batch();
      for (const doc of docsToUpdate) {
        batch.update(doc.ref, { deleted: false });
      }
      await batch.commit();
    }

    updated += docsToUpdate.length;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    console.log(
      `Page ${page}: scanned ${snapshot.size}, ${isDryRun ? "would update" : "updated"} ${docsToUpdate.length}. Totals: scanned ${scanned}, ${isDryRun ? "would update" : "updated"} ${updated}.`,
    );
  }

  console.log(
    `Backfill complete. Scanned ${scanned} posts, ${isDryRun ? "would update" : "updated"} ${updated} posts.`,
  );
}

backfillDeletedField()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Backfill failed:", error);
    process.exit(1);
  });
