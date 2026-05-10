const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkCommentsByAuthor(uid, limit = 50) {
  const snapshot = await db
    .collectionGroup('comments')
    .where('authorUid', '==', uid)
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();

  console.log(`Found ${snapshot.size} comments\n`);

  snapshot.docs.forEach((doc, index) => {
    const data = doc.data();
    console.log(`--- ${index + 1} ---`);
    console.log('path:', doc.ref.path);
    console.log('authorUid:', data.authorUid);
    console.log('postId:', data.postId);
    console.log('createdAt:', data.createdAt?.toDate?.() || data.createdAt);
    console.log('text:', data.text);
    console.log('');
  });
}

const uid = process.argv[2];

if (!uid) {
  console.error('Usage: node scripts/check_comments_by_author.js <uid>');
  process.exit(1);
}

checkCommentsByAuthor(uid).catch((e) => {
  console.error(e);
  process.exit(1);
});