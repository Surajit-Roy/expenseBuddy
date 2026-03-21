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
    
    /// When app is in foreground, suppress system banner (we show our own in-app banner instead).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Don't show system banner in foreground — our in-app banner handles it
        completionHandler([])
    }
    
    /// Handle taps on notifications (from background/lock screen).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
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
        db.collection("users").document(userId).updateData([
            "fcmToken": tokenString
        ]) { error in
            if let error = error {
                print("NotificationService: Failed to save device token — \(error.localizedDescription)")
            }
        }
    }
    
    /// Clears the device token from Firestore on logout.
    func clearDeviceToken() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).updateData([
            "fcmToken": FieldValue.delete()
        ])
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedules a notification for a new expense created by another user.
    /// In foreground: shows only the in-app banner (no system notification).
    /// In background: schedules a system UNNotification (banner + sound).
    func scheduleExpenseNotification(expense: Expense, payerName: String) {
        let title = "💰 New Expense Added"
        let body = "\(payerName) added \"\(expense.title)\" for \(CurrencyManager.shared.format(expense.amount))"
        
        let isActive = UIApplication.shared.applicationState == .active
        
        if isActive {
            // App is in foreground — show only the in-app banner (no system notification)
            publishInAppNotification(title: title, body: body, expenseId: expense.id)
        } else {
            // App is in background or inactive — schedule a system notification
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.userInfo = ["expenseId": expense.id]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request = UNNotificationRequest(identifier: "expense_\(expense.id)", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("NotificationService: Failed to schedule notification — \(error.localizedDescription)")
                }
            }
        }
    }
    
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
