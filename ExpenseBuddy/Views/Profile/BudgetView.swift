//
//  BudgetView.swift
//  ExpenseBuddy
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var showAddBudget = false
    @State private var appearAnimate = false
    @State private var budgetToDelete: Budget?
    
    var body: some View {
        ZStack {
            ModernBackground()
            
            if dataService.budgets.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.fill",
                    title: "No Budgets Yet",
                    subtitle: "Set monthly spending limits to keep your expenses in check",
                    buttonTitle: "Create Budget",
                    action: { showAddBudget = true }
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Overall spending summary
                        overallSummary
                            .offset(y: appearAnimate ? 0 : 15)
                            .opacity(appearAnimate ? 1 : 0)
                        
                        // Budget cards
                        ForEach(dataService.budgets) { budget in
                            budgetCard(budget)
                                .offset(y: appearAnimate ? 0 : 20)
                                .opacity(appearAnimate ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
        }
        .navigationTitle("Spending Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddBudget = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.primaryGradient)
                }
            }
        }
        .sheet(isPresented: $showAddBudget) {
            AddBudgetView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimate = true
            }
        }
        .alert("Delete Budget", isPresented: Binding(
            get: { budgetToDelete != nil },
            set: { if !$0 { budgetToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { budgetToDelete = nil }
            Button("Delete", role: .destructive) {
                if let budget = budgetToDelete {
                    dataService.deleteBudget(budget.id)
                }
                budgetToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this budget?")
        }
    }
    
    // MARK: - Overall Summary
    
    private var overallSummary: some View {
        let totalBudget = dataService.budgets.reduce(0.0) { $0 + $1.monthlyLimit }
        let totalSpent = dataService.budgets.reduce(0.0) { $0 + dataService.budgetSpending(for: $1) }
        let overallPct = totalBudget > 0 ? totalSpent / totalBudget : 0
        
        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(AppFonts.caption())
                        .foregroundColor(.white.opacity(0.7))
                    Text(currencyManager.format(totalSpent))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Budget")
                        .font(AppFonts.caption())
                        .foregroundColor(.white.opacity(0.7))
                    Text(currencyManager.format(totalBudget))
                        .font(AppFonts.title3())
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(.white)
                        .frame(width: min(geo.size.width * overallPct, geo.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(overallPct * 100))% used")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(currencyManager.format(max(0, totalBudget - totalSpent))) remaining")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(AppColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: - Budget Card
    
    private func budgetCard(_ budget: Budget) -> some View {
        let spent = dataService.budgetSpending(for: budget)
        let pct = budget.monthlyLimit > 0 ? spent / budget.monthlyLimit : 0
        let statusColor = budgetStatusColor(pct)
        
        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(statusColor.opacity(0.15), lineWidth: 5)
                        .frame(width: 52, height: 52)
                    
                    Circle()
                        .trim(from: 0, to: min(pct, 1.0))
                        .stroke(statusColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(min(pct, 1.0) * 100))%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(budgetLabel(budget))
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Text(currencyManager.format(spent))
                            .foregroundColor(statusColor)
                        Text("of")
                            .foregroundColor(AppColors.textTertiary)
                        Text(currencyManager.format(budget.monthlyLimit))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                
                Spacer()
                
                // Status indicator
                if pct >= 1.0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.oweRed)
                } else if pct >= 0.8 {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
                
                Button(action: {
                    budgetToDelete = budget
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Linear progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.secondaryBackground)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(statusColor)
                        .frame(width: min(geo.size.width * min(pct, 1.0), geo.size.width), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(18)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(pct >= 1.0 ? AppColors.oweRed.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - Helpers
    
    private func budgetLabel(_ budget: Budget) -> String {
        if let category = budget.category {
            return category.rawValue
        } else if let groupId = budget.groupId,
                  let group = dataService.groups.first(where: { $0.id == groupId }) {
            return group.name
        }
        return "Overall Budget"
    }
    
    private func budgetStatusColor(_ pct: Double) -> Color {
        if pct >= 1.0 { return AppColors.oweRed }
        if pct >= 0.8 { return .orange }
        if pct >= 0.6 { return .yellow }
        return AppColors.owedGreen
    }
}

// MARK: - Add Budget Sheet

struct AddBudgetView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var budgetType: BudgetType = .group
    @State private var selectedGroupId: String?
    @State private var selectedCategory: ExpenseCategory?
    @State private var limitText: String = ""
    @State private var errorMessage: String?
    
    enum BudgetType: String, CaseIterable {
        case group = "Group"
        case category = "Category"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernBackground()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Amount
                        VStack(spacing: 8) {
                            Text("Monthly Limit")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack(alignment: .center, spacing: 8) {
                                Text(currencyManager.symbol)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("0.00", text: $limitText)
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(AppColors.textPrimary)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 200)
                            }
                            .padding(.horizontal, 20)
                            .glassStyle(cornerRadius: 24, opacity: 0.1)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 24)
                        
                        // Budget type
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Budget For")
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 24)
                            
                            HStack(spacing: 10) {
                                ForEach(BudgetType.allCases, id: \.self) { type in
                                    Button(action: { budgetType = type }) {
                                        Text(type.rawValue)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(
                                                Group {
                                                    if budgetType == type {
                                                        AppColors.primary.opacity(0.15)
                                                    } else {
                                                        Color.clear.background(.ultraThinMaterial)
                                                    }
                                                }
                                            )
                                            .foregroundColor(budgetType == type ? AppColors.primary : AppColors.textSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(budgetType == type ? AppColors.primary.opacity(0.5) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Selection based on type
                        if budgetType == .group {
                            groupSelection
                        } else {
                            categorySelection
                        }
                        
                        // Error
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                            }
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.oweRed)
                            .padding(.horizontal, 24)
                        }
                        
                        // Save button
                        Button(action: saveBudget) {
                            Text("Create Budget")
                                .primaryButton()
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textPrimary)
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
        }
    }
    
    private var groupSelection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Group")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dataService.groups) { group in
                        Button(action: { selectedGroupId = group.id }) {
                            HStack(spacing: 8) {
                                Image(systemName: group.groupIcon)
                                    .font(.system(size: 14))
                                Text(group.name)
                                    .font(AppFonts.subheadline())
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Group {
                                    if selectedGroupId == group.id {
                                        AppColors.primary.opacity(0.15)
                                    } else {
                                        Color.clear.background(.ultraThinMaterial)
                                    }
                                }
                            )
                            .foregroundColor(selectedGroupId == group.id ? AppColors.primary : AppColors.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedGroupId == group.id ? AppColors.primary.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var categorySelection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Category")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Group {
                                        if selectedCategory == category {
                                            Circle()
                                                .fill(Color(hex: category.colorHex).opacity(0.15))
                                        } else {
                                            Circle()
                                                .fill(Color.clear)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Circle())
                                        }
                                    }
                                    .frame(width: 48, height: 48)
                                    Image(systemName: category.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(
                                            selectedCategory == category
                                            ? Color(hex: category.colorHex) : AppColors.textTertiary
                                        )
                                }
                                Text(category.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedCategory == category ? AppColors.textPrimary : AppColors.textTertiary)
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func saveBudget() {
        guard let limit = Double(Validator.sanitizeAmountInput(limitText)), limit > 0 else {
            errorMessage = "Please enter a valid budget amount"
            return
        }
        
        let budget = Budget(
            id: UUID().uuidString,
            userId: dataService.currentUser.id,
            groupId: budgetType == .group ? selectedGroupId : nil,
            categoryRaw: budgetType == .category ? selectedCategory?.rawValue : nil,
            monthlyLimit: CurrencyManager.shared.convertToINR(limit),
            createdAt: Date()
        )
        
        // Validate: need a group or category selected
        if budgetType == .group && selectedGroupId == nil {
            errorMessage = "Please select a group"
            return
        }
        if budgetType == .category && selectedCategory == nil {
            errorMessage = "Please select a category"
            return
        }
        
        dataService.addBudget(budget)
        dismiss()
    }
}
