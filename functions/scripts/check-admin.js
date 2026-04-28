const admin = require("firebase-admin");

const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function main() {
  const uid = process.argv[2];

  if (!uid) {
    console.error("Usage: node scripts/check-admin.js USER_UID");
    process.exit(1);
  }

  try {
    const user = await admin.auth().getUser(uid);

    console.log("User UID:", uid);
    console.log("Email:", user.email);
    console.log("Display Name:", user.displayName);
    console.log("\nCustom Claims:", JSON.stringify(user.customClaims, null, 2));

    if (user.customClaims?.admin === true) {
      console.log("\n✅ Admin claim IS SET");
    } else {
      console.log("\n❌ Admin claim is NOT SET or is false");
    }
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

main();
