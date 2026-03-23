//
//  MainTabView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var router: NavigationRouter
    @State private var selectedTab = 0
    @State private var showAddExpense = false
    
    init() {
        // Robust fix for hiding native tab bar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FriendsView()
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)

                GroupsListView()
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)

                ActivityView()
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)

                ProfileView(selectedTab: $selectedTab)
                    .tag(3)
                    .toolbar(.hidden, for: .tabBar)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            // Custom Dock-style Tab Bar
            if router.isRoot(for: selectedTab) {
                customTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: router.isRoot(for: selectedTab))
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView()
                .environmentObject(CurrencyManager.shared)
        }
        .onAppear {
            if let user = authService.currentUser {
                dataService.currentUser = user
                dataService.userCache.seed(user)
            }
        }
        .onChange(of: authService.currentUser) { newUser in
            if let user = newUser {
                dataService.currentUser = user
                dataService.userCache.seed(user)
            }
        }
        // Deep-link: when a notification tap sets pendingExpenseId, navigate to that expense
        .onChange(of: notificationService.pendingExpenseId) { expenseId in
            guard let expenseId = expenseId else { return }
            if let expense = dataService.expenses.first(where: { $0.id == expenseId }) {
                // Switch to Activity tab and navigate to expense detail
                selectedTab = 2
                // Append to path for programmatic navigation
                router.activityPath.append(expense)
                notificationService.clearPendingNavigation()
            } else {
                notificationService.clearPendingNavigation()
            }
        }
    }
    
    private var customTabBar: some View {
        ZStack(alignment: .top) {
            // Main Capsule
            HStack(spacing: 0) {
                tabItem(icon: "person.2", selectedIcon: "person.2.fill", label: "Friends", tag: 0)
                tabItem(icon: "person.3", selectedIcon: "person.3.fill", label: "Groups", tag: 1)
                
                // Centered hole/spacer for the plus button
                Spacer()
                    .frame(width: 70)
                
                tabItem(icon: "clock", selectedIcon: "clock.fill", label: "Activity", tag: 2)
                tabItem(icon: "person.circle", selectedIcon: "person.circle.fill", label: "Profile", tag: 3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(AppColors.cardBackground)
                    .shadow(color: AppColors.shadow.opacity(0.6), radius: 20, x: 0, y: 10)
            }
            .overlay {
                Capsule()
                    .stroke(AppColors.divider.opacity(0.5), lineWidth: 0.5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            // Detached Floating Plus Button
            Button(action: { 
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                showAddExpense = true 
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 8)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -25) // Detached effect
        }
    }
    
    private func tabItem(icon: String, selectedIcon: String, label: String, tag: Int) -> some View {
        Button(action: {
            if selectedTab != tag {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = tag
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tag ? selectedIcon : icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedTab == tag ? AppColors.primary : AppColors.textTertiary)
                    .frame(height: 24)
                
                Text(label)
                    .font(.system(size: 10, weight: selectedTab == tag ? .semibold : .medium, design: .rounded))
                    .foregroundColor(selectedTab == tag ? AppColors.primary : AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}
