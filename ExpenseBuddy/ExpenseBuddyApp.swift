//
//  ExpenseBuddyApp.swift
//  ExpenseBuddy
//
//  Created by Surajit Roy on 05/03/26.
//

import SwiftUI
import Combine
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct ExpenseBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()
    @StateObject private var dataService = DataService()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(showSplash: $showSplash)
                        .transition(.opacity)
                } else if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(authService)
                        .environmentObject(dataService)
                        .environmentObject(CurrencyManager.shared)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    LoginView(authService: authService)
                        .environmentObject(authService)
                        .environmentObject(dataService)
                        .environmentObject(CurrencyManager.shared)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .animation(.easeInOut(duration: 0.4), value: showSplash)
            .animation(.easeInOut(duration: 0.4), value: authService.isAuthenticated)
        }
    }
}
