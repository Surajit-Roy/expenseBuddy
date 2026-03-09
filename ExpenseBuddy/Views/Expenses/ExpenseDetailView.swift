//
//  ExpenseDetailView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct ExpenseDetailView: View {
    let expense: Expense
    let currentUserId: String
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    private var payerName: String {
        dataService.userCache.name(for: expense.paidByUserId)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard
                detailsCard
                splitsCard
                deleteButton
            }
            .padding(.bottom, 40)
        }
        .background(AppColors.background)
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataService.deleteExpense(expense.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(expense.title)\"? This cannot be undone.")
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: expense.category.colorHex).opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: expense.category.icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(Color(hex: expense.category.colorHex))
            }
            Text(expense.title)
                .font(AppFonts.title2())
                .foregroundColor(AppColors.textPrimary)
            Text(currencyManager.format(expense.amount))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Text(expense.createdAt.formatted(as: .full))
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "person.fill", label: "Paid by", value: payerName)
            Divider().padding(.leading, 52)
            detailRow(icon: "person.2.fill", label: "Split between", value: "\(expense.participantIds.count) people")
            Divider().padding(.leading, 52)
            detailRow(icon: "equal.circle", label: "Split type", value: expense.splitType.rawValue)
            Divider().padding(.leading, 52)
            detailRow(icon: "tag.fill", label: "Category", value: expense.category.rawValue)
            if let note = expense.note {
                Divider().padding(.leading, 52)
                detailRow(icon: "note.text", label: "Note", value: note)
            }
        }
        .padding(.vertical, 4)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            Text(label)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.subheadline())
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var splitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Split Details")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(expense.splits) { split in
                    let splitUserName = dataService.userCache.name(for: split.userId)
                    
                    HStack(spacing: 14) {
                        AvatarView(name: splitUserName, size: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(splitUserName)
                                .font(AppFonts.subheadline())
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                            if split.userId == expense.paidByUserId {
                                Text("Paid \(currencyManager.format(expense.amount))")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.owedGreen)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(currencyManager.format(split.amountOwed))
                                .font(AppFonts.subheadline())
                                .fontWeight(.bold)
                                .foregroundColor(split.userId == expense.paidByUserId ? AppColors.owedGreen : AppColors.oweRed)
                            Text(split.userId == expense.paidByUserId ? "gets back" : "owes")
                                .font(AppFonts.caption2())
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if split.userId != expense.splits.last?.userId {
                        Divider().padding(.leading, 70)
                    }
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
    
    private var deleteButton: some View {
        Button(action: { showDeleteAlert = true }) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Delete Expense")
                    .font(AppFonts.headline())
            }
            .foregroundColor(AppColors.oweRed)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.oweRed.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
    }
}
