//
//  MainTabView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataService: DataService
    @State private var selectedTab = 0
    @State private var showAddExpense = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FriendsView()
                    .tag(0)

                GroupsListView()
                    .tag(1)

                ActivityView()
                    .tag(2)

                ProfileView(selectedTab: $selectedTab)
                    .tag(3)
            }
            
            customTabBar
        }
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
        .onChange(of: authService.currentUser) { _, newUser in
            if let user = newUser {
                dataService.currentUser = user
                dataService.userCache.seed(user)
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "person.2.fill", label: "Friends", tag: 0)
            tabItem(icon: "person.3.fill", label: "Groups", tag: 1)
            
            Button(action: { showAddExpense = true }) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 10, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(y: -16)
            }
            .frame(maxWidth: .infinity)
            
            tabItem(icon: "clock.fill", label: "Activity", tag: 2)
            tabItem(icon: "person.circle.fill", label: "Profile", tag: 3)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            AppColors.cardBackground
                .shadow(color: AppColors.shadow, radius: 16, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tag
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: selectedTab == tag ? .semibold : .regular))
                    .foregroundColor(selectedTab == tag ? AppColors.primary : AppColors.textTertiary)
                    .scaleEffect(selectedTab == tag ? 1.1 : 1.0)
                Text(label)
                    .font(.system(size: 10, weight: selectedTab == tag ? .semibold : .regular, design: .rounded))
                    .foregroundColor(selectedTab == tag ? AppColors.primary : AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
