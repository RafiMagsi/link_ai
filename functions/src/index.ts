import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";

admin.initializeApp();

function assertSuperAdmin(email?: string | null) {
  const allowedAdminEmails = [
    "mrafi.stonixtech@gmail.com",
  ];

  if (!email || !allowedAdminEmails.includes(email)) {
    throw new HttpsError(
      "permission-denied",
      "Only the project owner can assign admin access."
    );
  }
}

export const setAdminClaim = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  assertSuperAdmin(request.auth.token.email);

  const uid = request.data.uid as string | undefined;

  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  await admin.auth().setCustomUserClaims(uid, {
    admin: true,
  });

  return {
    success: true,
    uid,
    admin: true,
  };
});

export const removeAdminClaim = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  assertSuperAdmin(request.auth.token.email);

  const uid = request.data.uid as string | undefined;

  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  await admin.auth().setCustomUserClaims(uid, {
    admin: false,
  });

  return {
    success: true,
    uid,
    admin: false,
  };
});
