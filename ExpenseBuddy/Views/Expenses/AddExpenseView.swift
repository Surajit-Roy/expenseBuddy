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
    
    @State private var appearAnimate = false
    
    init(groupId: String? = nil) {
        _viewModel = StateObject(wrappedValue: ExpenseViewModel(groupId: groupId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernBackground()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Amount Section (Always first)
                        amountSection
                            .offset(y: appearAnimate ? 0 : 20)
                            .opacity(appearAnimate ? 1 : 0)
                        
                        VStack(spacing: 24) {
                            // Group picker
                            if viewModel.groupId == nil {
                                groupPickerSection
                            }
                            
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
                        .offset(y: appearAnimate ? 0 : 30)
                        .opacity(appearAnimate ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: appearAnimate)
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveExpense() }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
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
                withAnimation(.easeOut(duration: 0.6)) {
                    appearAnimate = true
                }
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
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                if viewModel.groupId == group.id {
                                    AppColors.primary.opacity(0.15)
                                } else {
                                    Color.clear.background(.ultraThinMaterial)
                                }
                            }
                            .foregroundColor(
                                viewModel.groupId == group.id
                                    ? AppColors.primary
                                    : AppColors.textSecondary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(viewModel.groupId == group.id ? AppColors.primary.opacity(0.5) : .clear, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Sections
    
    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("How much?")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            
            HStack(alignment: .center, spacing: 8) {
                Text(currencyManager.symbol)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("0.00", text: $viewModel.amountText)
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 20)
            .glassStyle(cornerRadius: 24, opacity: 0.1)
        }
        .padding(.top, 20)
        .padding(.horizontal, 24)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primary)
                TextField("What was this for?", text: $viewModel.title)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
            }
            .padding(18)
            .glassStyle(cornerRadius: 18)
            .padding(.horizontal, 24)
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Category")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button(action: { viewModel.selectedCategory = category }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    if viewModel.selectedCategory == category {
                                        Circle()
                                            .fill(Color(hex: category.colorHex).opacity(0.15))
                                    } else {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    }
                                    
                                    Image(systemName: category.icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(
                                            viewModel.selectedCategory == category
                                                ? Color(hex: category.colorHex)
                                                : AppColors.textTertiary
                                        )
                                }
                                .frame(width: 52, height: 52)
                                .shadow(color: viewModel.selectedCategory == category ? Color(hex: category.colorHex).opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                                
                                Text(category.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(
                                        viewModel.selectedCategory == category ? AppColors.textPrimary : AppColors.textTertiary
                                    )
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            }
        }
    }
    
    private var paidBySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Paid by")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableMembers) { member in
                        let resolvedMember = dataService.userCache.userOrPlaceholder(for: member.id)
                        Button(action: { viewModel.paidByUserId = member.id }) {
                            HStack(spacing: 10) {
                                AvatarView(name: resolvedMember.name, size: 32, base64String: resolvedMember.profileImage)
                                Text(resolvedMember.name.components(separatedBy: " ").first ?? "")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                if viewModel.paidByUserId == member.id {
                                    AppColors.primary.opacity(0.15)
                                } else {
                                    Color.clear.background(.ultraThinMaterial)
                                }
                            }
                            .foregroundColor(
                                viewModel.paidByUserId == member.id
                                    ? AppColors.primary : AppColors.textSecondary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    viewModel.paidByUserId == member.id ? AppColors.primary.opacity(0.5) : .clear, lineWidth: 1
                                )
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var splitTypeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Split Type")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            HStack(spacing: 10) {
                ForEach(SplitType.allCases, id: \.self) { type in
                    Button(action: { viewModel.splitType = type }) {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.system(size: 20))
                            Text(type.rawValue)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if viewModel.splitType == type {
                                AppColors.primary.opacity(0.15)
                            } else {
                                Color.clear.background(.ultraThinMaterial)
                            }
                        }
                        .foregroundColor(
                            viewModel.splitType == type ? AppColors.primary : AppColors.textSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.splitType == type ? AppColors.primary.opacity(0.5) : .clear, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Split between")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(viewModel.selectedParticipantIds.count) selected")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(viewModel.availableMembers) { member in
                    let isSelected = viewModel.selectedParticipantIds.contains(member.id)
                    
                    Button(action: {
                        if isSelected { viewModel.selectedParticipantIds.remove(member.id) }
                        else { viewModel.selectedParticipantIds.insert(member.id) }
                    }) {
                        let resolvedMember = dataService.userCache.userOrPlaceholder(for: member.id)
                        HStack(spacing: 14) {
                            AvatarView(name: resolvedMember.name, size: 44, base64String: resolvedMember.profileImage)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                            
                            Text(resolvedMember.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            if viewModel.splitType == .equal && isSelected {
                                Text(currencyManager.formatInput(viewModel.equalSplitAmount))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)
                        }
                        .padding(14)
                        .glassStyle(cornerRadius: 18, opacity: isSelected ? 0.15 : 0.05)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var splitDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(viewModel.splitType == .percentage ? "Percentages" : "Amounts")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                
                if viewModel.splitType == .percentage {
                    let total = viewModel.selectedParticipants.reduce(0.0) { $0 + (Double(viewModel.percentages[$1.id] ?? "0") ?? 0) }
                    Text("\(Int(total))% of 100%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(abs(total - 100) < 0.01 ? AppColors.owedGreen : AppColors.oweRed)
                } else {
                    let total = viewModel.selectedParticipants.reduce(0.0) { $0 + (Double(viewModel.unequalAmounts[$1.id] ?? "0") ?? 0) }
                    Text("\(currencyManager.formatInput(total)) / \(currencyManager.formatInput(viewModel.amount))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(abs(total - viewModel.amount) < 0.01 ? AppColors.owedGreen : AppColors.oweRed)
                }
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(viewModel.selectedParticipants) { participant in
                    let resolvedParticipant = dataService.userCache.userOrPlaceholder(for: participant.id)
                    HStack(spacing: 12) {
                        AvatarView(name: resolvedParticipant.name, size: 36, base64String: resolvedParticipant.profileImage)
                        
                        Text(resolvedParticipant.name.components(separatedBy: " ").first ?? "")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        if viewModel.splitType == .percentage {
                            HStack(spacing: 8) {
                                TextField("0", text: Binding(
                                    get: { viewModel.percentages[participant.id] ?? "" },
                                    set: { viewModel.percentages[participant.id] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                Text("%")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Text(currencyManager.symbol)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("0", text: Binding(
                                    get: { viewModel.unequalAmounts[participant.id] ?? "" },
                                    set: { viewModel.unequalAmounts[participant.id] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(12)
                    .glassStyle(cornerRadius: 16)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note (optional)")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textTertiary)
                TextField("Add a note...", text: $viewModel.note)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
            }
            .padding(18)
            .glassStyle(cornerRadius: 18)
            .padding(.horizontal, 24)
        }
    }
}
