import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

/**
 * Builds a deterministic week key (used for weekly connect limits).
 * @param {Date} date date to evaluate
 * @return {string} week key like `2026-W17`
 */
function getWeekKey(date: Date): string {
  const oneJan = new Date(date.getFullYear(), 0, 1);
  const numberOfDays = Math.floor(
    (date.getTime() - oneJan.getTime()) / (24 * 60 * 60 * 1000)
  );
  const weekNumber = Math.ceil((date.getDay() + 1 + numberOfDays) / 7);

  return `${date.getFullYear()}-W${weekNumber}`;
}

/**
 * Loads a public profile doc for the given user.
 * @param {string} uid user id
 * @return {Promise<Record<string, unknown>>} profile data
 */
async function getProfile(uid: string) {
  const snapshot = await db.collection("profiles").doc(uid).get();

  if (!snapshot.exists) {
    throw new HttpsError("failed-precondition", "Profile not found.");
  }

  return snapshot.data() || {};
}

/**
 * Creates a connect request from the current user to another user.
 * Enforces a 50/week limit (per sender).
 */
export const sendConnectRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const senderUid = request.auth.uid;
  const receiverUid = request.data.receiverUid as string | undefined;
  const message = (request.data.message as string | undefined)?.trim() || "";

  if (!receiverUid) {
    throw new HttpsError("invalid-argument", "receiverUid is required.");
  }

  if (senderUid === receiverUid) {
    throw new HttpsError(
      "invalid-argument",
      "You cannot connect with yourself."
    );
  }

  if (message.length > 280) {
    throw new HttpsError(
      "invalid-argument",
      "Connect message must be 280 characters or less."
    );
  }

  const now = new Date();
  const weekKey = getWeekKey(now);

  const requestId = `${senderUid}_${receiverUid}`;
  const reverseRequestId = `${receiverUid}_${senderUid}`;
  const connectionId = `${senderUid}_${receiverUid}`;

  const requestRef = db.collection("connectRequests").doc(requestId);
  const reverseRequestRef = db
    .collection("connectRequests")
    .doc(reverseRequestId);
  const connectionRef = db.collection("connections").doc(connectionId);
  const statsRef = db.collection("userConnectionStats").doc(senderUid);

  const senderProfile = await getProfile(senderUid);
  const receiverProfile = await getProfile(receiverUid);

  await db.runTransaction(async (transaction) => {
    const [
      existingRequest,
      reverseRequest,
      existingConnection,
      statsSnapshot,
    ] = await Promise.all([
      transaction.get(requestRef),
      transaction.get(reverseRequestRef),
      transaction.get(connectionRef),
      transaction.get(statsRef),
    ]);

    if (existingConnection.exists) {
      throw new HttpsError("already-exists", "You are already connected.");
    }

    if (existingRequest.exists) {
      const status = existingRequest.data()?.status;

      if (status === "pending") {
        throw new HttpsError(
          "already-exists",
          "Connect request already sent."
        );
      }

      if (status === "accepted") {
        throw new HttpsError("already-exists", "You are already connected.");
      }
    }

    if (reverseRequest.exists) {
      const reverseStatus = reverseRequest.data()?.status;

      if (reverseStatus === "pending") {
        throw new HttpsError(
          "already-exists",
          "This user already sent you a request."
        );
      }

      if (reverseStatus === "accepted") {
        throw new HttpsError("already-exists", "You are already connected.");
      }
    }

    const stats = statsSnapshot.exists ? statsSnapshot.data() : null;
    const currentWeekKey = stats?.weekKey as string | undefined;
    const currentCount = currentWeekKey === weekKey ?
      (stats?.weeklyConnectCount as number || 0) :
      0;

    if (currentCount >= 50) {
      throw new HttpsError(
        "resource-exhausted",
        "Weekly connect request limit reached."
      );
    }

    transaction.set(requestRef, {
      id: requestId,
      senderUid,
      receiverUid,
      senderName: senderProfile.name || "",
      senderRole: senderProfile.role || "",
      senderAvatarUrl: senderProfile.avatarUrl || null,
      receiverName: receiverProfile.name || "",
      receiverRole: receiverProfile.role || "",
      receiverAvatarUrl: receiverProfile.avatarUrl || null,
      message,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.set(
      statsRef,
      {
        uid: senderUid,
        weekKey,
        weeklyConnectCount: currentCount + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
  });

  return {
    success: true,
    requestId,
  };
});

/**
 * Allows the receiver to accept/decline a connect request.
 * On accept, creates a mutual connection relationship.
 */
export const respondConnectRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const currentUid = request.auth.uid;
  const requestId = request.data.requestId as string | undefined;
  const action = request.data.action as string | undefined;

  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId is required.");
  }

  if (action !== "accept" && action !== "decline") {
    throw new HttpsError(
      "invalid-argument",
      "action must be accept or decline."
    );
  }

  const requestRef = db.collection("connectRequests").doc(requestId);

  await db.runTransaction(async (transaction) => {
    const requestSnapshot = await transaction.get(requestRef);

    if (!requestSnapshot.exists) {
      throw new HttpsError("not-found", "Connect request not found.");
    }

    const data = requestSnapshot.data() || {};

    if (data.receiverUid !== currentUid) {
      throw new HttpsError(
        "permission-denied",
        "Only the receiver can respond."
      );
    }

    if (data.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "Request is no longer pending."
      );
    }

    const senderUid = data.senderUid as string;
    const receiverUid = data.receiverUid as string;

    if (action === "decline") {
      transaction.update(requestRef, {
        status: "declined",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return;
    }

    const connectionOneId = `${senderUid}_${receiverUid}`;
    const connectionTwoId = `${receiverUid}_${senderUid}`;

    const connectionOneRef = db.collection("connections").doc(connectionOneId);
    const connectionTwoRef = db.collection("connections").doc(connectionTwoId);

    transaction.update(requestRef, {
      status: "accepted",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.set(connectionOneRef, {
      id: connectionOneId,
      userUid: senderUid,
      connectedUid: receiverUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.set(connectionTwoRef, {
      id: connectionTwoId,
      userUid: receiverUid,
      connectedUid: senderUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {
    success: true,
    action,
  };
});
