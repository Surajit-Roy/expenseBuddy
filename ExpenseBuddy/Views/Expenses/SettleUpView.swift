//
//  SettleUpView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct SettleUpView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    let groupId: String?
    let memberIds: [String]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedUserId: String = ""
    @State private var amountText = ""
    @State private var note = ""
    @State private var showConfirmation = false
    @State private var errorMessage: String?
    
    private var otherMembers: [User] {
        memberIds
            .filter { $0 != dataService.currentUser.id }
            .map { dataService.userCache.userOrPlaceholder(for: $0) }
    }
    
    private var amount: Double {
        Double(amountText) ?? 0
    }
    
    /// Balance between current user and selected friend.
    /// Positive = friend owes you, negative = you owe friend.
    private var selectedBalance: Double {
        guard !selectedUserId.isEmpty else { return 0 }
        return contextBalance(for: selectedUserId)
    }
    
    /// Returns the group-specific balance if within a group, otherwise the global balance.
    private func contextBalance(for friendId: String) -> Double {
        if let groupId = groupId {
            let groupExpenses = dataService.expensesForGroup(groupId)
            let groupSettlements = dataService.settlementsForGroup(groupId)
            return ExpenseCalculator.balanceBetween(
                currentUserId: dataService.currentUser.id,
                friendId: friendId,
                expenses: groupExpenses,
                settlements: groupSettlements
            )
        } else {
            return dataService.balanceWithFriend(friendId)
        }
    }
    
    /// True = I owe the selected person (I should pay them).
    /// False = They owe me (they should pay me / I record their payment).
    private var iOweSelected: Bool {
        selectedBalance < -0.01
    }
    
    /// The suggested settlement amount (always positive, regardless of direction).
    private var suggestedAmount: Double {
        abs(selectedBalance)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppColors.greenGradient)
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    Text("Settle Up")
                        .font(AppFonts.title2())
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Select person
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Person")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            ForEach(otherMembers) { member in
                                let resolvedMember = dataService.userCache.userOrPlaceholder(for: member.id)
                                Button(action: { selectMember(member) }) {
                                    HStack(spacing: 14) {
                                        AvatarView(name: resolvedMember.name, size: 42, base64String: resolvedMember.profileImage)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(resolvedMember.name)
                                                .font(AppFonts.headline())
                                                .foregroundColor(AppColors.textPrimary)
                                            
                                            let bal = contextBalance(for: member.id)
                                            if abs(bal) > 0.01 {
                                                if bal > 0 {
                                                    Text("owes you \(currencyManager.format(bal))")
                                                        .font(AppFonts.caption())
                                                        .foregroundColor(AppColors.owedGreen)
                                                } else {
                                                    Text("you owe \(currencyManager.format(abs(bal)))")
                                                        .font(AppFonts.caption())
                                                        .foregroundColor(AppColors.oweRed)
                                                }
                                            } else {
                                                Text("Settled up")
                                                    .font(AppFonts.caption())
                                                    .foregroundColor(AppColors.settled)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedUserId == member.id ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 24))
                                            .foregroundColor(selectedUserId == member.id ? AppColors.owedGreen : AppColors.textTertiary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                
                                if member.id != otherMembers.last?.id {
                                    Divider().padding(.leading, 72)
                                }
                            }
                        }
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    }
                    
                    // Direction indicator (shows who pays whom)
                    if !selectedUserId.isEmpty && suggestedAmount > 0.01 {
                        let friendName = otherMembers.first(where: { $0.id == selectedUserId })?.name.components(separatedBy: " ").first ?? ""
                        
                        HStack(spacing: 12) {
                            Image(systemName: iOweSelected ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(iOweSelected ? AppColors.oweRed : AppColors.owedGreen)
                            
                            if iOweSelected {
                                Text("You pay \(friendName)")
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.textPrimary)
                            } else {
                                Text("\(friendName) pays you")
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            (iOweSelected ? AppColors.oweRed : AppColors.owedGreen).opacity(0.1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                    }
                    
                    // Amount with auto-fill
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Amount")
                                .font(AppFonts.caption())
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            
                            // Auto-fill button
                            if !selectedUserId.isEmpty && suggestedAmount > 0.01 {
                                Button(action: {
                                    amountText = String(format: "%.2f", currencyManager.convert(suggestedAmount))
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 10))
                                        Text("Full amount: \(currencyManager.format(suggestedAmount))")
                                            .font(AppFonts.caption2())
                                    }
                                    .foregroundColor(AppColors.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppColors.primary.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text(currencyManager.symbol)
                                .font(AppFonts.title2())
                                .foregroundColor(AppColors.textSecondary)
                            TextField("0.00", text: $amountText)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .onChange(of: amountText) { _, newValue in
                                    let sanitized = Validator.sanitizeAmountInput(newValue)
                                    if sanitized != newValue { amountText = sanitized }
                                }
                        }
                        .padding(16)
                        .background(AppColors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Overpay warning
                        if !selectedUserId.isEmpty && amount > 0 && suggestedAmount > 0.01 {
                            if amount > suggestedAmount + 0.01 {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                    Text("This exceeds the outstanding balance (\(currencyManager.format(suggestedAmount)))")
                                        .font(AppFonts.caption())
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                        HStack(spacing: 12) {
                            Image(systemName: "note.text")
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 20)
                            TextField("Add a note...", text: $note)
                        }
                        .textFieldStyle()
                    }
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.oweRed)
                        .padding(.horizontal, 24)
                    }
                    
                    // Settle button
                    Button(action: settleUp) {
                        Text("Record Payment")
                    }
                    .primaryButton()
                    .padding(.horizontal, 24)
                    .disabled(selectedUserId.isEmpty || amount <= 0)
                    .opacity(selectedUserId.isEmpty || amount <= 0 ? 0.5 : 1)
                }
                .padding(.bottom, 40)
            }
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
            .alert("Payment Recorded!", isPresented: $showConfirmation) {
                Button("Done") { dismiss() }
            } message: {
                Text("The settlement has been recorded successfully.")
            }
        }
    }
    
    private func selectMember(_ member: User) {
        selectedUserId = member.id
        errorMessage = nil
        
        // Auto-fill the amount with the outstanding balance in the currently selected currency
        let bal = contextBalance(for: member.id)
        if abs(bal) > 0.01 {
            amountText = String(format: "%.2f", currencyManager.convert(abs(bal)))
        } else {
            amountText = ""
        }
    }
    
    private func settleUp() {
        errorMessage = nil
        
        guard !selectedUserId.isEmpty else {
            errorMessage = "Please select a person."
            return
        }
        
        guard amount > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }
        
        guard amount <= 9_999_999.99 else {
            errorMessage = "Amount too large."
            return
        }
        
        let balance = contextBalance(for: selectedUserId)
        
        // Determine the correct direction:
        // If balance < 0 (I owe them): fromUser = me, toUser = them (I pay them)
        // If balance > 0 (they owe me): fromUser = them, toUser = me (they pay me)
        let fromUserId: String
        let toUserId: String
        
        if balance < -0.01 {
            // I owe them → I pay them
            fromUserId = dataService.currentUser.id
            toUserId = selectedUserId
        } else {
            // They owe me → they pay me
            fromUserId = selectedUserId
            toUserId = dataService.currentUser.id
        }
        
        // Convert the input amount back to INR before saving
        dataService.recordSettlement(
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: currencyManager.convertToINR(amount),
            groupId: groupId,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showConfirmation = true
    }
}
