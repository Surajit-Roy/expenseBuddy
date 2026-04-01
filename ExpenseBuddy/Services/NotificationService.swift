//
//  NotificationService.swift
//  ExpenseBuddy
//

import Foundation
import Combine
import SwiftUI
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

// MARK: - UNUserNotificationCenter Delegate (must be NSObject)

/// Handles foreground notification display and notification tap responses.
class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    weak var notificationService: NotificationService?
    
    /// When app is in foreground, print the payload and show a banner for debugging.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("Notification Received (Foreground): \(userInfo)")
        
        // During debugging, we enable system banners in foreground to verify delivery
        completionHandler([.banner, .sound, .list])
    }
    
    /// Handle taps on notifications (from background/lock screen).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("Notification Tapped: \(userInfo)")
        
        if let expenseId = userInfo["expenseId"] as? String {
            Task { @MainActor [weak self] in
                self?.notificationService?.navigateToExpense(expenseId)
            }
        }
        completionHandler()
    }
}

// MARK: - NotificationService

/// Manages local notification permissions, in-app notification publishing,
/// and deep-link navigation from notification taps.
@MainActor
class NotificationService: ObservableObject {
    
    // MARK: - Published State
    
    /// The latest notification payload for the in-app banner overlay.
    @Published var latestNotification: NotificationPayload?
    
    /// Whether the user has granted notification permissions.
    @Published var isPermissionGranted = false
    
    /// When set, the app should navigate to this expense ID.
    @Published var pendingExpenseId: String?
    
    // MARK: - Private
    
    private let db = Firestore.firestore()
    private let center = UNUserNotificationCenter.current()
    private let centerDelegate = NotificationCenterDelegate()
    
    // MARK: - Lifecycle
    
    init() {
        centerDelegate.notificationService = self
        center.delegate = centerDelegate
        checkCurrentPermission()
    }
    
    // MARK: - Permission
    
    /// Requests notification authorization from the user.
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            if let error = error {
                print("NotificationService: Permission error — \(error.localizedDescription)")
            }
            Task { @MainActor in
                self?.isPermissionGranted = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    /// Checks the current notification authorization status without prompting.
    private func checkCurrentPermission() {
        center.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Device Token Management
    
    /// Saves a device token string to Firestore for the authenticated user.
    func saveDeviceToken(_ tokenString: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        print("NotificationService: Saving FCM token to Firestore — \(tokenString)")
        db.collection("users").document(userId).setData([
            "fcmTokens": FieldValue.arrayUnion([tokenString])
        ], merge: true) { error in
            if let error = error {
                print("NotificationService: Failed to save device token — \(error.localizedDescription)")
            }
        }
    }
    
    /// Clears the current device token from Firestore on logout.
    func clearDeviceToken(_ tokenString: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).setData([
            "fcmTokens": FieldValue.arrayRemove([tokenString])
        ], merge: true)
    }
    
    // MARK: - Notification Scheduling
    
    /// Sends a "Remind" notification to a friend who owes money.
    /// Creates a Firestore document in the friend's `reminders` subcollection
    /// so the Cloud Function (or their listener) can pick it up.
    func sendReminder(to friendId: String, friendName: String, amount: Double, fromUserName: String) {
        // 1. Create a reminder document in Firestore for the friend
        let reminderData: [String: Any] = [
            "fromUserId": Auth.auth().currentUser?.uid ?? "",
            "fromUserName": fromUserName,
            "toUserId": friendId,
            "amount": amount,
            "message": "\(fromUserName) is reminding you that you owe \(CurrencyManager.shared.format(abs(amount)))",
            "createdAt": Timestamp(date: Date()),
            "read": false
        ]
        
        db.collection("users").document(friendId)
            .collection("reminders").addDocument(data: reminderData) { error in
                if let error = error {
                    print("NotificationService: Failed to send reminder — \(error.localizedDescription)")
                }
            }
        
        // 2. Show confirmation to current user as in-app banner
        publishInAppNotification(
            title: "✅ Reminder Sent",
            body: "Reminded \(friendName) about \(CurrencyManager.shared.format(abs(amount)))"
        )
    }
    
    // MARK: - Deep Link Navigation
    
    /// Triggers navigation to a specific expense from a notification tap.
    func navigateToExpense(_ expenseId: String) {
        pendingExpenseId = expenseId
    }
    
    /// Clears the pending navigation after it has been consumed.
    func clearPendingNavigation() {
        pendingExpenseId = nil
    }
    
    // MARK: - In-App Banner
    
    /// Publishes a notification payload for the in-app floating banner.
    func publishInAppNotification(title: String, body: String, expenseId: String? = nil) {
        let payload = NotificationPayload(
            title: title,
            body: body,
            expenseId: expenseId
        )
        
        SwiftUI.withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            latestNotification = payload
        }
        
        // Auto-dismiss after 4 seconds
        let payloadId = payload.id
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if self.latestNotification?.id == payloadId {
                SwiftUI.withAnimation(.easeOut(duration: 0.3)) {
                    self.latestNotification = nil
                }
            }
        }
    }
    
    /// Dismisses the current in-app notification banner.
    func dismissBanner() {
        SwiftUI.withAnimation(.easeOut(duration: 0.3)) {
            latestNotification = nil
        }
    }
}
