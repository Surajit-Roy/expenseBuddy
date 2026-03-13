//
//  ProfileView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct ProfileView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataService: DataService
    @State private var showLogoutAlert = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("currencySymbol") private var currencySymbol = "₹"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        NavigationLink(destination: ProfileDetailView(user: dataService.currentUser)) {
                            profileCard
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        statsSection
                        settingsSection
                        logoutButton
                        appInfo
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) { authService.logout() }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var profileCard: some View {
        HStack(spacing: 16) {
            AvatarView(name: dataService.currentUser.name, size: 70, base64String: dataService.currentUser.profileImage)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dataService.currentUser.name)
                    .font(AppFonts.title2())
                    .foregroundColor(AppColors.textPrimary)
                Text(dataService.currentUser.email)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.textSecondary)
                Text("Member since \(dataService.currentUser.createdAt.formattedWithStyle(.monthDay))")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            Button(action: { selectedTab = 0 }) {
                statCard(icon: "person.2.fill", value: "\(dataService.friends.count)", label: "Friends")
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { selectedTab = 1 }) {
                statCard(icon: "person.3.fill", value: "\(dataService.groups.count)", label: "Groups")
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { selectedTab = 2 }) {
                statCard(icon: "receipt.fill", value: "\(dataService.expenses.count)", label: "Expenses")
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
    }
    
    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.primary)
            Text(value)
                .font(AppFonts.title2())
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
    }
    
    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Dark mode toggle
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.purple)
                }
                Text("Dark Mode")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Toggle("", isOn: $isDarkMode)
                    .labelsHidden()
                    .tint(AppColors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider().padding(.leading, 52)
            
            // Notification toggle
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                Text("Notifications")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(AppColors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider().padding(.leading, 52)
            
            // Currency Picker
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
                Text("Currency")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Picker("Currency", selection: $currencySymbol) {
                    ForEach(AppCurrency.allCases) { currency in
                        Text(currency.displayName).tag(currency.symbol)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider().padding(.leading, 52)
            NavigationLink(destination: HelpSupportView()) {
                settingRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().padding(.leading, 52)
            
            NavigationLink(destination: PrivacyPolicyView()) {
                settingRow(icon: "shield.fill", title: "Privacy Policy", color: .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    private func settingRow(icon: String, title: String, value: String? = nil, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            if let value {
                Text(value)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var logoutButton: some View {
        Button(action: { showLogoutAlert = true }) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                Text("Log Out")
                    .font(AppFonts.headline())
            }
            .foregroundColor(AppColors.oweRed)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.oweRed.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 20)
    }
    
    private var appInfo: some View {
        VStack(spacing: 4) {
            Text("ExpenseBuddy v1.0")
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textTertiary)
            Text("Made with ❤️")
                .font(AppFonts.caption2())
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.top, 8)
    }
}
