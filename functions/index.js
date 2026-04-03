const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

/**
 * Sends a push notification to participants when a new expense is created.
 */
exports.notifyOnExpenseCreated = onDocumentCreated({
    document: "expenses/{expenseId}",
    region: "asia-south1"
}, async (event) => {
    const expense = event.data.data();
    if (!expense) return;

    const db = getFirestore();
    const messaging = getMessaging();

    // Fetch the creator's name
    const creatorDoc = await db.collection("users").doc(expense.createdByUserId).get();
    const creatorName = creatorDoc.exists ? creatorDoc.data().name : "Someone";

    const title = "💰 New Expense Added";
    const body = `${creatorName} added "${expense.title}" for ${expense.amount}`;
    const participantIds = expense.participantIds || [];

    // Filter out the creator to avoid notifying self
    const notifyUserIds = participantIds.filter(id => id !== expense.createdByUserId);

    if (notifyUserIds.length === 0) return;

    // Fetch tokens for all participants
    const tokens = [];
    console.log(`Searching for tokens for ${notifyUserIds.length} users: ${notifyUserIds.join(", ")}`);
    
    const userDocs = await Promise.all(
        notifyUserIds.map(id => db.collection("users").doc(id).get())
    );

    userDocs.forEach(doc => {
        if (doc.exists) {
            const userData = doc.data();
            
            // Check if notifications are enabled for this user
            // Default to true if the field is missing (backward compatibility)
            const notificationsEnabled = userData.notificationsEnabled !== false;
            
            if (notificationsEnabled) {
                // Handle both new array format and legacy single string format
                if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
                    tokens.push(...userData.fcmTokens);
                } else if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            } else {
                console.log(`Skipping notifications for user ${doc.id} as they have disabled notifications.`);
            }
        } else {
            console.warn(`User document not found for ID: ${doc.id}`);
        }
    });

    console.log(`Found ${tokens.length} total tokens to notify.`);

    if (tokens.length === 0) {
        console.warn("No valid FCM tokens found for any participants. Skipping notification.");
        return;
    }

    const message = {
        notification: {
            title: title,
            body: body,
        },
        data: {
            expenseId: expense.id,
            type: "expense_added"
        },
        tokens: tokens,
    };

    try {
        const response = await messaging.sendEachForMulticast(message);
        console.log(`Notification result: Successfully sent ${response.successCount} messages; ${response.failureCount} errors.`);
        
        // Log individual errors if any
        if (response.failureCount > 0) {
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    console.error(`Token at index ${idx} failed: ${resp.error.message}`);
                }
            });
        }
    } catch (error) {
        console.error("Error sending message:", error);
    }
});

/**
 * Sends a push notification when a reminder is sent to a friend.
 */
exports.notifyOnReminderCreated = onDocumentCreated({
    document: "users/{userId}/reminders/{reminderId}",
    region: "asia-south1"
}, async (event) => {
    const reminder = event.data.data();
    if (!reminder) return;

    console.log(`Processing reminder for user: ${event.params.userId}`);

    const db = getFirestore();
    const messaging = getMessaging();

    const recipientUserId = event.params.userId;
    const fromUserName = reminder.fromUserName || "A friend";

    // Fetch tokens for the recipient
    const recipientDoc = await db.collection("users").doc(recipientUserId).get();
    if (!recipientDoc.exists) {
        console.warn(`Recipient user ${recipientUserId} not found in Firestore.`);
        return;
    }

    const userData = recipientDoc.data();
    
    // Check if notifications are enabled for the recipient
    const notificationsEnabled = userData.notificationsEnabled !== false;
    if (!notificationsEnabled) {
        console.log(`Recipient ${recipientUserId} has disabled notifications. Skipping.`);
        return;
    }

    const tokens = [];
    if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
        tokens.push(...userData.fcmTokens);
    } else if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
    }

    console.log(`Found ${tokens.length} tokens for recipient.`);

    if (tokens.length === 0) return;

    const message = {
        notification: {
            title: "⏰ Reminder",
            body: reminder.message || `${fromUserName} is reminding you about a payment.`,
        },
        data: {
            type: "reminder"
        },
        tokens: tokens,
    };

    try {
        const response = await messaging.sendEachForMulticast(message);
        console.log(`Reminder result: Successfully sent ${response.successCount} messages; ${response.failureCount} errors.`);
    } catch (error) {
        console.error("Error sending message:", error);
    }
});
