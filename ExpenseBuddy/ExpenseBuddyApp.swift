//
//  ExpenseBuddyApp.swift
//  ExpenseBuddy
//
//  Created by Surajit Roy on 05/03/26.
//

import SwiftUI
import Combine
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    /// Shared notification service — set from the SwiftUI app entry point.
    var notificationService: NotificationService?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Register for FCM tokens
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // APNs token registration -> forward to Firebase
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error.localizedDescription)")
    }
    
    // Receive FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Firebase FCM Token received")
            notificationService?.saveDeviceToken(token)
        }
    }
}

@main
struct ExpenseBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()
    @StateObject private var dataService = DataService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var navigationRouter = NavigationRouter()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(showSplash: $showSplash)
                        .environmentObject(authService)
                        .transition(.opacity)
                } else if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(authService)
                        .environmentObject(dataService)
                        .environmentObject(notificationService)
                        .environmentObject(navigationRouter)
                        .environmentObject(CurrencyManager.shared)
                        .environmentObject(PremiumManager.shared)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    LoginView(authService: authService)
                        .environmentObject(authService)
                        .environmentObject(dataService)
                        .environmentObject(notificationService)
                        .environmentObject(navigationRouter)
                        .environmentObject(CurrencyManager.shared)
                        .environmentObject(PremiumManager.shared)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
                
                // In-app notification banner overlay
                if let notification = notificationService.latestNotification {
                    NotificationBannerView(
                        notification: notification,
                        onTap: {
                            // Navigate to expense if available
                            if let expenseId = notification.expenseId {
                                notificationService.navigateToExpense(expenseId)
                            }
                            notificationService.dismissBanner()
                        },
                        onDismiss: {
                            notificationService.dismissBanner()
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .animation(.easeInOut(duration: 0.4), value: showSplash)
            .animation(.easeInOut(duration: 0.4), value: authService.isAuthenticated)
            .onAppear {
                // Wire up services
                dataService.notificationService = notificationService
                delegate.notificationService = notificationService
                
                // Request notification permission on first launch
                notificationService.requestPermission()
                
                // Auto-create any past-due recurring expenses
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dataService.checkAndCreateDueExpenses()
                }
            }
        }
    }
}
