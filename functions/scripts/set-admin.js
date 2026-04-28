const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function main() {
  const uid = process.argv[2];

  if (!uid) {
    console.error("Usage: node scripts/set-admin.js USER_UID");
    process.exit(1);
  }

  await admin.auth().setCustomUserClaims(uid, { admin: true });

  console.log(`Admin claim added to ${uid}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});