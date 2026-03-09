//
//  FriendDetailView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct FriendDetailView: View {
    let friend: User
    @EnvironmentObject var dataService: DataService
    @State private var showSettleUp = false
    @State private var showRemoveAlert = false
    @Environment(\.dismiss) private var dismiss
    
    private var balance: Double {
        dataService.balanceWithFriend(friend.id)
    }
    
    private var sharedExpenses: [Expense] {
        dataService.expensesWithFriend(friend.id)
    }
    
    private var sharedGroups: [ExpenseGroup] {
        dataService.sharedGroups(with: friend.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Friend header
                friendHeader
                
                // Balance card
                BalanceSummaryCard(
                    title: "Balance with \(friend.name.components(separatedBy: " ").first ?? "")",
                    amount: balance
                )
                .padding(.horizontal, 20)
                
                // Quick actions
                quickActions
                
                // Shared groups
                if !sharedGroups.isEmpty {
                    sharedGroupsSection
                }
                
                // Shared expenses
                sharedExpensesSection
            }
            .padding(.bottom, 100)
        }
        .background(AppColors.background)
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: { showRemoveAlert = true }) {
                        Label("Remove Friend", systemImage: "person.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showSettleUp) {
            SettleUpView(groupId: nil, members: [dataService.currentUser, friend])
        }
        .alert("Remove Friend", isPresented: $showRemoveAlert) {
            if dataService.canDeleteFriend(friend.id) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    dataService.removeFriend(friend)
                    dismiss()
                }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            if dataService.canDeleteFriend(friend.id) {
                Text("Are you sure you want to remove \(friend.name)? This won't delete shared expenses.")
            } else {
                Text("You cannot remove a friend with an outstanding balance. Please settle up first.")
            }
        }
    }
    
    private var friendHeader: some View {
        VStack(spacing: 14) {
            AvatarView(name: friend.name, size: 80)
            
            VStack(spacing: 4) {
                Text(friend.name)
                    .font(AppFonts.title2())
                    .foregroundColor(AppColors.textPrimary)
                Text(friend.email)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text("Friends since \(friend.createdAt.formatted(as: .monthDay))")
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var quickActions: some View {
        HStack(spacing: 16) {
            Button(action: { showSettleUp = true }) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppColors.owedGreen.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.owedGreen)
                    }
                    Text("Settle Up")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            
            Button(action: {
                // Remind feature placeholder
            }) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.primary)
                    }
                    Text("Remind")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 40)
    }
    
    private var sharedGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared Groups")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sharedGroups) { group in
                        NavigationLink(destination: GroupDetailView(groupId: group.id)) {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.primary.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: group.groupIcon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppColors.primary)
                                }
                                Text(group.name)
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(width: 80)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var sharedExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Shared Expenses")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(sharedExpenses.count) total")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 20)
            
            if sharedExpenses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "receipt")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No shared expenses")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(sharedExpenses) { expense in
                        NavigationLink(destination: ExpenseDetailView(expense: expense, currentUserId: dataService.currentUser.id)) {
                            ExpenseRow(expense: expense, currentUserId: dataService.currentUser.id)
                                .padding(.horizontal, 16)
                        }
                        
                        if expense.id != sharedExpenses.last?.id {
                            Divider().padding(.leading, 76).padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
                .padding(.horizontal, 20)
            }
        }
    }
}
