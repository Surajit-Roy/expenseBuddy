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
    
    @State private var appearAnimate = false
    
    private var payerName: String {
        dataService.userCache.name(for: expense.paidByUserId)
    }
    
    var body: some View {
        ZStack {
            ModernBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                        .offset(y: appearAnimate ? 0 : 20)
                        .opacity(appearAnimate ? 1 : 0)
                        .animation(.easeOut(duration: 0.6), value: appearAnimate)
                    
                    detailsCard
                        .offset(y: appearAnimate ? 0 : 20)
                        .opacity(appearAnimate ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: appearAnimate)
                    
                    splitsCard
                        .offset(y: appearAnimate ? 0 : 20)
                        .opacity(appearAnimate ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: appearAnimate)
                    
                    deleteButton
                        .offset(y: appearAnimate ? 0 : 20)
                        .opacity(appearAnimate ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: appearAnimate)
                }
                .padding(.bottom, 60)
            }
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataService.deleteExpense(  expense.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(expense.title)\"? This cannot be undone.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimate = true
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: expense.category.colorHex).opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: expense.category.icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(Color(hex: expense.category.colorHex))
            }
            .shadow(color: Color(hex: expense.category.colorHex).opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text(expense.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text(currencyManager.format(expense.amount))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text(expense.createdAt.formattedWithStyle(.full))
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .glassStyle(cornerRadius: 24)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "person.fill", label: "Paid by", value: payerName, color: .blue)
            Divider().padding(.leading, 62).opacity(0.3)
            detailRow(icon: "person.2.fill", label: "Split between", value: "\(expense.participantIds.count) people", color: .purple)
            Divider().padding(.leading, 62).opacity(0.3)
            detailRow(icon: "equal.circle", label: "Split type", value: expense.splitType.rawValue, color: .orange)
            Divider().padding(.leading, 62).opacity(0.3)
            detailRow(icon: "tag.fill", label: "Category", value: expense.category.rawValue, color: .green)
            if let note = expense.note {
                Divider().padding(.leading, 62).opacity(0.3)
                detailRow(icon: "note.text", label: "Note", value: note, color: .gray)
            }
        }
        .padding(.vertical, 8)
        .glassStyle(cornerRadius: 18)
        .padding(.horizontal, 20)
    }
    
    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var splitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Split Details")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(expense.splits) { split in
                    let splitUserName = dataService.userCache.name(for: split.userId)
                    
                    HStack(spacing: 14) {
                        AvatarView(name: splitUserName, size: 44, base64String: dataService.userCache.user(for: split.userId)?.profileImage)
                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(splitUserName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                            if split.userId == expense.paidByUserId {
                                Text("Paid total")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.owedGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(AppColors.owedGreen.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(currencyManager.format(split.amountOwed))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(split.userId == expense.paidByUserId ? AppColors.owedGreen : AppColors.oweRed)
                            Text(split.userId == expense.paidByUserId ? "gets back" : "owes")
                                .font(AppFonts.caption2())
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassStyle(cornerRadius: 14)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var deleteButton: some View {
        Button(action: { showDeleteAlert = true }) {
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Delete Expense")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(AppColors.oweRed)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .glassStyle(cornerRadius: 14, opacity: 0.1)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.oweRed.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }
}
