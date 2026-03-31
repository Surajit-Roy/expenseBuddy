//
//  RecurringExpenseView.swift
//  ExpenseBuddy
//

import SwiftUI

struct RecurringExpenseView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var appearAnimate = false
    
    // Alert States
    @State private var recurringToPause: RecurringExpense?
    @State private var recurringToDelete: RecurringExpense?
    
    var body: some View {
        ZStack {
            ModernBackground()
            
            if dataService.recurringExpenses.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise.circle",
                    title: "No Recurring Expenses",
                    subtitle: "Add a recurring expense when creating a new expense by enabling 'Make Recurring'"
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(dataService.recurringExpenses) { recurring in
                            recurringCard(recurring)
                                .offset(y: appearAnimate ? 0 : 20)
                                .opacity(appearAnimate ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationTitle("Recurring Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimate = true
            }
        }
        .alert("Pause Recurring Expense", isPresented: Binding(
            get: { recurringToPause != nil },
            set: { if !$0 { recurringToPause = nil } }
        )) {
            Button("Cancel", role: .cancel) { recurringToPause = nil }
            Button(recurringToPause?.isActive == true ? "Pause" : "Resume") {
                if let recurring = recurringToPause {
                    dataService.toggleRecurringExpense(recurring)
                }
                recurringToPause = nil
            }
        } message: {
            if let recurring = recurringToPause {
                Text(recurring.isActive ? "Are you sure you want to pause this recurring expense? It will no longer generate new expenses automatically." : "Are you sure you want to resume this recurring expense?")
            }
        }
        .alert("Delete Recurring Expense", isPresented: Binding(
            get: { recurringToDelete != nil },
            set: { if !$0 { recurringToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { recurringToDelete = nil }
            Button("Delete", role: .destructive) {
                if let recurring = recurringToDelete {
                    dataService.deleteRecurringExpense(recurring.id)
                }
                recurringToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this recurring template? Future expenses will not be automatically created.")
        }
    }
    
    private func recurringCard(_ recurring: RecurringExpense) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: recurring.category.colorHex).opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: recurring.category.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: recurring.category.colorHex))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(recurring.title)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(currencyManager.format(recurring.amount))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primary)
                }
                
                Spacer()
                
                // Active/Paused badge
                Text(recurring.isActive ? "Active" : "Paused")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(recurring.isActive ? AppColors.owedGreen : AppColors.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(recurring.isActive ? AppColors.owedGreen.opacity(0.12) : AppColors.secondaryBackground)
                    .clipShape(Capsule())
            }
            
            Divider().foregroundColor(AppColors.divider)
            
            // Details row
            HStack(spacing: 16) {
                // Frequency
                HStack(spacing: 6) {
                    Image(systemName: recurring.frequency.icon)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                    Text(recurring.frequency.rawValue)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Next due
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                    Text("Next: \(recurring.nextDueDate.formattedWithStyle(.monthDay))")
                        .font(AppFonts.caption())
                        .foregroundColor(
                            recurring.nextDueDate <= Date() ? AppColors.oweRed : AppColors.textSecondary
                        )
                }
                
                Spacer()
                
                // Group name
                if let group = dataService.groups.first(where: { $0.id == recurring.groupId }) {
                    HStack(spacing: 4) {
                        Image(systemName: group.groupIcon)
                            .font(.system(size: 12))
                        Text(group.name)
                            .font(AppFonts.caption())
                    }
                    .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Actions
            if recurring.createdByUserId == dataService.currentUser.id {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Button(action: {
                            recurringToPause = recurring
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: recurring.isActive ? "pause.fill" : "play.fill")
                                    .font(.system(size: 12))
                                Text(recurring.isActive ? "Pause" : "Resume")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(recurring.isActive ? .orange : AppColors.owedGreen)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(recurring.isActive ? Color.orange.opacity(0.1) : AppColors.owedGreen.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Button(action: {
                            recurringToDelete = recurring
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12))
                                Text("Delete")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(AppColors.oweRed)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppColors.oweRed.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    // Show participant statuses to the creator
                    let otherParticipants = recurring.participantIds.filter { $0 != dataService.currentUser.id }
                    if !otherParticipants.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Participant Status:")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                                .fontWeight(.medium)
                            
                            ForEach(otherParticipants, id: \.self) { pid in
                                let status = recurring.participantStatuses?[pid] ?? .pending
                                let name = dataService.userCache.name(for: pid)
                                HStack {
                                    Text(name.components(separatedBy: " ").first ?? name)
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text(status.rawValue)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: status.colorHex))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: status.colorHex).opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(12)
                        .background(AppColors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                VStack(spacing: 12) {
                    let creatorName = dataService.userCache.name(for: recurring.createdByUserId)
                    let currentStatus = recurring.participantStatuses?[dataService.currentUser.id] ?? .pending
                    
                    if currentStatus == .pending {
                        Text("\(creatorName.components(separatedBy: " ").first ?? creatorName) wants to add this recurring expense. Do you approve?")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                dataService.updateRecurringExpenseApprovalStatus(recurringId: recurring.id, userId: dataService.currentUser.id, status: .approved)
                            }) {
                                Text("Approve")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.owedGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppColors.owedGreen.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                            Button(action: {
                                dataService.declineRecurringExpense(recurring, userId: dataService.currentUser.id)
                            }) {
                                Text("Decline")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.oweRed)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppColors.oweRed.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    } else {
                        HStack {
                            Text("Created by \(creatorName.components(separatedBy: " ").first ?? creatorName)")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textTertiary)
                            
                            Spacer()
                            
                            Text("You \(currentStatus.rawValue.lowercased())")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: currentStatus.colorHex))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: currentStatus.colorHex).opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 3)
    }
}
