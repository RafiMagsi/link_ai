const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const uid = process.argv[2];

if (!uid) {
  console.error("Usage: node functions/scripts/unset-admin.js <uid>");
  process.exit(1);
}

async function unsetAdmin() {
  const user = await admin.auth().getUser(uid);
  const existingClaims = user.customClaims || {};

  delete existingClaims.admin;

  await admin.auth().setCustomUserClaims(uid, existingClaims);

  console.log(`Admin claim removed from ${uid}`);
}

unsetAdmin().catch((error) => {
  console.error(error);
  process.exit(1);
});