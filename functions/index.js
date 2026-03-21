/**
 * Firebase Cloud Function — ExpenseBuddy Push Notifications
 *
 * Triggers when a new expense document is created in Firestore.
 * Sends an FCM push notification to all participants (except the creator).
 *
 * Deploy: `firebase deploy --only functions`
 *
 * Prerequisites:
 * 1. `npm install firebase-admin firebase-functions` in /functions
 * 2. APNs key uploaded to Firebase Console → Project Settings → Cloud Messaging
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.notifyExpenseParticipants = functions.firestore
  .document("expenses/{expenseId}")
  .onCreate(async (snap, context) => {
    const expense = snap.data();
    const creatorId = expense.createdByUserId;
    const participantIds = expense.participantIds || [];
    const payerName = await getUserName(expense.paidByUserId);

    // Build the notification payload
    const notification = {
      title: "💰 New Expense Added",
      body: `${payerName} added "${expense.title}" for ₹${expense.amount.toFixed(2)}`,
    };

    // Collect FCM tokens for all participants except the creator
    const tokens = [];
    for (const userId of participantIds) {
      if (userId === creatorId) continue; // Don't notify the creator

      const userDoc = await db.collection("users").doc(userId).get();
      if (userDoc.exists) {
        const fcmToken = userDoc.data().fcmToken;
        if (fcmToken) {
          tokens.push(fcmToken);
        }
      }
    }

    if (tokens.length === 0) {
      console.log("No FCM tokens found for participants.");
      return null;
    }

    // Send push notifications
    const message = {
      notification,
      data: {
        expenseId: context.params.expenseId,
        type: "expense_added",
      },
      tokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        `Sent ${response.successCount} notifications, ${response.failureCount} failures.`
      );

      // Clean up invalid tokens
      response.responses.forEach((resp, idx) => {
        if (
          resp.error &&
          (resp.error.code === "messaging/invalid-registration-token" ||
            resp.error.code === "messaging/registration-token-not-registered")
        ) {
          // Remove stale token from Firestore
          const staleUserId = participantIds.filter(
            (id) => id !== creatorId
          )[idx];
          if (staleUserId) {
            db.collection("users")
              .doc(staleUserId)
              .update({ fcmToken: admin.firestore.FieldValue.delete() });
          }
        }
      });
    } catch (error) {
      console.error("Error sending notifications:", error);
    }

    return null;
  });

/**
 * Helper: Fetches a user's display name from Firestore.
 */
async function getUserName(userId) {
  try {
    const doc = await db.collection("users").doc(userId).get();
    return doc.exists ? doc.data().name || "Someone" : "Someone";
  } catch {
    return "Someone";
  }
}

exports.notifyReminder = functions.firestore
  .document("users/{userId}/reminders/{reminderId}")
  .onCreate(async (snap, context) => {
    const reminder = snap.data();
    const toUserId = context.params.userId;

    const userDoc = await db.collection("users").doc(toUserId).get();
    if (!userDoc.exists || !userDoc.data().fcmToken) {
      console.log("No FCM token found for user", toUserId);
      return null;
    }

    const fcmToken = userDoc.data().fcmToken;

    const message = {
      notification: {
        title: "⏰ Settle Up Reminder",
        body: reminder.message,
      },
      data: {
        type: "reminder",
        fromUserId: reminder.fromUserId
      },
      token: fcmToken,
    };

    try {
      await admin.messaging().send(message);
      console.log("Sent reminder notification to", toUserId);
    } catch (error) {
      console.error("Error sending reminder:", error);
      // Clean up token if invalid
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        await db.collection("users").doc(toUserId).update({
          fcmToken: admin.firestore.FieldValue.delete()
        });
      }
    }

    return null;
  });
