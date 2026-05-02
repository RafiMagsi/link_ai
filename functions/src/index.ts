import {onCall, HttpsError, onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {
  onDocumentCreated,
} from "firebase-functions/v2/firestore";

admin.initializeApp();

const db = admin.firestore();

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

  batch.update(ref, {
    [field]: admin.firestore.FieldValue.increment(-1),
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
 * Handles RevenueCat webhook for subscription updates.
 * Called by RevenueCat when a user makes a purchase.
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

  if (!userMessage || userMessage.trim().length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Message cannot be empty.",
    );
  }

  // Check if user is a gold subscriber
  const subRef = db
    .collection("users")
    .doc(uid)
    .collection("subscription")
    .doc("data");
  const subSnapshot = await subRef.get();

  if (!subSnapshot.exists) {
    throw new HttpsError(
      "permission-denied",
      "Gold subscription required.",
    );
  }

  const subscription = subSnapshot.data();
  const expiresAt = subscription?.expiresAt?.toDate?.() || new Date(0);

  if (!subscription?.isGoldSubscriber || new Date() > expiresAt) {
    throw new HttpsError(
      "permission-denied",
      "Gold subscription required.",
    );
  }

  try {
    // TODO: Integrate with Gemini API
    // For now, return a placeholder response
    const msg = userMessage.substring(0, 50);
    const response = "Thanks for the message! " +
        "This is a simulated response from @snow. " +
        "Gemini API integration coming soon. " +
        `Your message: "${msg}..."`;

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
