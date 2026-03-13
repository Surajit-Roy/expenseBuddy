//
//  AddExpenseView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct AddExpenseView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    @StateObject private var viewModel: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    
    init(groupId: String? = nil) {
        _viewModel = StateObject(wrappedValue: ExpenseViewModel(groupId: groupId))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Group picker (when no group pre-selected)
                    if viewModel.groupId == nil {
                        groupPickerSection
                    }
                    
                    amountSection
                    titleSection
                    categorySection
                    paidBySection
                    splitTypeSection
                    participantsSection
                    
                    if viewModel.splitType != .equal {
                        splitDetailsSection
                    }
                    
                    noteSection
                    
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.oweRed)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(AppColors.background)
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveExpense() }
                        .font(.headline)
                        .foregroundColor(viewModel.isValid ? AppColors.primary : AppColors.textTertiary)
                        .disabled(!viewModel.isValid)
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
            .onAppear {
                viewModel.setDataService(dataService)
            }
            .alert("Expense Added!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\"\(viewModel.title)\" has been added successfully.")
            }
        }
    }
    
    private func saveExpense() {
        if viewModel.addExpense() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            showSuccess = true
        }
    }
    
    // MARK: - Group Picker
    
    private var groupPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group")
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(dataService.groups) { group in
                        Button(action: {
                            viewModel.groupId = group.id
                            viewModel.setDataService(dataService)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: group.groupIcon)
                                    .font(.system(size: 14))
                                Text(group.name)
                                    .font(AppFonts.subheadline())
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.groupId == group.id
                                    ? AppColors.primary.opacity(0.15)
                                    : AppColors.secondaryBackground
                            )
                            .foregroundColor(
                                viewModel.groupId == group.id
                                    ? AppColors.primary
                                    : AppColors.textSecondary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(viewModel.groupId == group.id ? AppColors.primary : .clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            if dataService.groups.isEmpty {
                Text("Create a group first to add expenses")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Sections
    
    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("How much?")
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencyManager.symbol)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                TextField("0.00", text: $viewModel.amountText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 12) {
                Image(systemName: "pencil")
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 20)
                TextField("What was this for?", text: $viewModel.title)
            }
            .textFieldStyle()
        }
        .padding(.horizontal, 24)
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button(action: { viewModel.selectedCategory = category }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            viewModel.selectedCategory == category
                                                ? Color(hex: category.colorHex).opacity(0.2)
                                                : AppColors.secondaryBackground
                                        )
                                        .frame(width: 44, height: 44)
                                    Image(systemName: category.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(
                                            viewModel.selectedCategory == category
                                                ? Color(hex: category.colorHex)
                                                : AppColors.textTertiary
                                        )
                                }
                                Text(category.rawValue.components(separatedBy: " ").first ?? "")
                                    .font(AppFonts.caption2())
                                    .foregroundColor(
                                        viewModel.selectedCategory == category ? AppColors.textPrimary : AppColors.textTertiary
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var paidBySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paid by")
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.availableMembers) { member in
                        let resolvedMember = dataService.userCache.userOrPlaceholder(for: member.id)
                        Button(action: { viewModel.paidByUserId = member.id }) {
                            HStack(spacing: 8) {
                                AvatarView(name: resolvedMember.name, size: 28, base64String: resolvedMember.profileImage)
                                Text(resolvedMember.name.components(separatedBy: " ").first ?? "")
                                    .font(AppFonts.subheadline())
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.paidByUserId == member.id
                                    ? AppColors.primary.opacity(0.15) : AppColors.secondaryBackground
                            )
                            .foregroundColor(
                                viewModel.paidByUserId == member.id
                                    ? AppColors.primary : AppColors.textSecondary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    viewModel.paidByUserId == member.id ? AppColors.primary : .clear, lineWidth: 1.5
                                )
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var splitTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Split Type")
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 24)
            
            HStack(spacing: 8) {
                ForEach(SplitType.allCases, id: \.self) { type in
                    Button(action: { viewModel.splitType = type }) {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 18))
                            Text(type.rawValue)
                                .font(AppFonts.caption2())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.splitType == type
                                ? AppColors.primary.opacity(0.15) : AppColors.secondaryBackground
                        )
                        .foregroundColor(
                            viewModel.splitType == type ? AppColors.primary : AppColors.textSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.splitType == type ? AppColors.primary : .clear, lineWidth: 1.5)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Split between")
                    .font(AppFonts.caption())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("\(viewModel.selectedParticipantIds.count) selected")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.primary)
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                ForEach(viewModel.availableMembers) { member in
                    let isSelected = viewModel.selectedParticipantIds.contains(member.id)
                    
                    Button(action: {
                        if isSelected { viewModel.selectedParticipantIds.remove(member.id) }
                        else { viewModel.selectedParticipantIds.insert(member.id) }
                    }) {
                        let resolvedMember = dataService.userCache.userOrPlaceholder(for: member.id)
                        HStack(spacing: 12) {
                            AvatarView(name: resolvedMember.name, size: 36, base64String: resolvedMember.profileImage)
                            Text(resolvedMember.name)
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if viewModel.splitType == .equal && isSelected {
                                Text(currencyManager.formatInput(viewModel.equalSplitAmount))
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    
                    if member.id != viewModel.availableMembers.last?.id {
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
    
    private var splitDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.splitType == .percentage ? "Percentages" : "Amounts")
                    .font(AppFonts.caption())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                
                if viewModel.splitType == .percentage {
                    let total = viewModel.selectedParticipants.reduce(0.0) { $0 + (Double(viewModel.percentages[$1.id] ?? "0") ?? 0) }
                    Text("\(Int(total))% of 100%")
                        .font(AppFonts.caption())
                        .foregroundColor(abs(total - 100) < 0.01 ? AppColors.owedGreen : AppColors.oweRed)
                } else {
                    let total = viewModel.selectedParticipants.reduce(0.0) { $0 + (Double(viewModel.unequalAmounts[$1.id] ?? "0") ?? 0) }
                    Text("\(currencyManager.formatInput(total)) of \(currencyManager.formatInput(viewModel.amount))")
                        .font(AppFonts.caption())
                        .foregroundColor(abs(total - viewModel.amount) < 0.01 ? AppColors.owedGreen : AppColors.oweRed)
                }
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(viewModel.selectedParticipants) { participant in
                    let resolvedParticipant = dataService.userCache.userOrPlaceholder(for: participant.id)
                    HStack(spacing: 12) {
                        AvatarView(name: resolvedParticipant.name, size: 32, base64String: resolvedParticipant.profileImage)
                        Text(resolvedParticipant.name.components(separatedBy: " ").first ?? "")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 70, alignment: .leading)
                        Spacer()
                        
                        if viewModel.splitType == .percentage {
                            HStack(spacing: 4) {
                                TextField("0", text: Binding(
                                    get: { viewModel.percentages[participant.id] ?? "" },
                                    set: { viewModel.percentages[participant.id] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .font(AppFonts.body())
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppColors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                Text("%")
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Text(currencyManager.symbol)
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.textSecondary)
                                TextField("0", text: Binding(
                                    get: { viewModel.unequalAmounts[participant.id] ?? "" },
                                    set: { viewModel.unequalAmounts[participant.id] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .font(AppFonts.body())
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppColors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (optional)")
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 20)
                TextField("Add a note...", text: $viewModel.note)
            }
            .textFieldStyle()
        }
        .padding(.horizontal, 24)
    }
}
