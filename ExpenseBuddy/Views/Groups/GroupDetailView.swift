//
//  GroupDetailView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct GroupDetailView: View {
    let groupId: String
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var showAddExpense = false
    @State private var showSettleUp = false
    @State private var showDeleteGroupAlert = false
    @State private var showSimplifiedDebts = false
    @Environment(\.dismiss) private var dismiss
    
    private var group: ExpenseGroup? {
        dataService.groups.first { $0.id == groupId }
    }
    
    private var groupExpenses: [Expense] {
        dataService.expensesForGroup(groupId)
    }
    
    private var balanceEntries: [BalanceEntry] {
        guard let group else { return [] }
        return dataService.groupBalanceEntries(group)
    }
    
    private var simplifiedDebts: [SimplifiedDebt] {
        guard let group else { return [] }
        return dataService.simplifiedGroupDebts(group)
    }
    
    private var groupBalance: Double {
        guard let group else { return 0 }
        return dataService.groupBalance(group)
    }
    
    var body: some View {
        if let group {
            ZStack(alignment: .bottomTrailing) {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        groupHeader(group)
                        
                        BalanceSummaryCard(title: "Your Balance", amount: groupBalance)
                            .padding(.horizontal, 20)
                        
                        if !balanceEntries.isEmpty {
                            balanceBreakdownSection
                        }
                        
                        if !simplifiedDebts.isEmpty {
                            simplifiedDebtsSection
                        }
                        
                        membersSection(group)
                        
                        expensesSection
                    }
                    .padding(.bottom, 100)
                }
                
                HStack(spacing: 12) {
                    FloatingActionButton(icon: "checkmark.circle") {
                        showSettleUp = true
                    }
                    FloatingActionButton(icon: "plus") {
                        showAddExpense = true
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: { showDeleteGroupAlert = true }) {
                            Label("Delete Group", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(groupId: group.id)
            }
            .sheet(isPresented: $showSettleUp) {
                SettleUpView(groupId: group.id, members: group.members)
            }
            .alert("Delete Group", isPresented: $showDeleteGroupAlert) {
                if dataService.canDeleteGroup(group) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        dataService.deleteGroup(groupId)
                        dismiss()
                    }
                } else {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                if dataService.canDeleteGroup(group) {
                    Text("This will delete the group and all its expenses. This cannot be undone.")
                } else {
                    Text("You cannot delete a group with unsettled balances. Please settle up all balances first.")
                }
            }
        } else {
            Text("Group not found")
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Subviews
    
    private func groupHeader(_ group: ExpenseGroup) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(groupColor(group).opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: group.groupIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(groupColor(group))
            }
            Text(group.name)
                .font(AppFonts.title2())
                .foregroundColor(AppColors.textPrimary)
            HStack(spacing: 16) {
                Label("\(group.members.count) members", systemImage: "person.2.fill")
                Label("\(groupExpenses.count) expenses", systemImage: "receipt")
            }
            .font(AppFonts.caption())
            .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var balanceBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who Owes Who")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                ForEach(balanceEntries) { entry in
                    HStack(spacing: 12) {
                        AvatarView(name: entry.fromUserName, size: 36)
                        
                        HStack(spacing: 4) {
                            Text(entry.fromUserName.components(separatedBy: " ").first ?? "")
                                .font(AppFonts.subheadline())
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(AppColors.textTertiary)
                            Text(entry.toUserName.components(separatedBy: " ").first ?? "")
                                .font(AppFonts.subheadline())
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text(currencyManager.format(entry.amount))
                            .font(AppFonts.subheadline())
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.oweRed)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
    
    /// Simplified debts: minimum transactions to settle all group debts
    private var simplifiedDebtsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Suggested Settlements")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.primary)
            }
            .padding(.horizontal, 20)
            
            Text("Fewest transactions to settle all debts")
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(simplifiedDebts) { debt in
                    HStack(spacing: 12) {
                        AvatarView(name: debt.fromUserName, size: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(debt.fromUserName.components(separatedBy: " ").first ?? "")
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textTertiary)
                                Text(debt.toUserName.components(separatedBy: " ").first ?? "")
                                    .fontWeight(.medium)
                            }
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.textPrimary)
                            
                            Text("should pay")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(currencyManager.format(debt.amount))
                            .font(AppFonts.subheadline())
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.owedGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if debt.id != simplifiedDebts.last?.id {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
    
    private func membersSection(_ group: ExpenseGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members (\(group.members.count))")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(group.members) { member in
                        VStack(spacing: 6) {
                            AvatarView(name: member.name, size: 50)
                            Text(member.name.components(separatedBy: " ").first ?? "")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(width: 70)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Expenses")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if !groupExpenses.isEmpty {
                    let total = groupExpenses.reduce(0.0) { $0 + $1.amount }
                    Text("Total: \(currencyManager.format(total))")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            
            if groupExpenses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "receipt")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No expenses yet")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                    Text("Tap + to add an expense")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(groupExpenses) { expense in
                        NavigationLink(destination: ExpenseDetailView(expense: expense, currentUserId: dataService.currentUser.id)) {
                            ExpenseRow(expense: expense, currentUserId: dataService.currentUser.id)
                                .padding(.horizontal, 16)
                        }
                        
                        if expense.id != groupExpenses.last?.id {
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
    
    private func groupColor(_ group: ExpenseGroup) -> Color {
        switch group.groupType {
        case .home: return .blue
        case .trip: return .orange
        case .office: return .purple
        case .couple: return .pink
        case .other: return .gray
        }
    }
}
