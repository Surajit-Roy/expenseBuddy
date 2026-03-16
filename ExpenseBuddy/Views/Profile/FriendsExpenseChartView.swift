//
//  FriendsExpenseChartView.swift
//  ExpenseBuddy
//
//  Created by Antigravity on 2026-03-16.
//

import SwiftUI
import Charts

struct FriendsExpenseChartView: View {
    @EnvironmentObject var dataService: DataService
    @State private var selectedChart: ChartType = .balances
    @State private var isAnimating = false
    
    enum ChartType: String, CaseIterable {
        case balances = "Balances"
        case categories = "Categories"
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Segmented Picker
                Picker("Chart Type", selection: $selectedChart) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        if selectedChart == .balances {
                            balanceChartSection
                        } else {
                            categoryChartSection
                        }
                        
                        summarySection
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Balance Chart Section
    
    private var balanceChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Friend Balances")
                .font(AppFonts.title3())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            let balances = calculateFriendBalances()
            
            if balances.isEmpty {
                emptyState(message: "No balances to display.")
            } else {
                Chart {
                    ForEach(balances) { item in
                        BarMark(
                            x: .value("Friend", item.name),
                            y: .value("Amount", isAnimating ? item.amount : 0)
                        )
                        .foregroundStyle(item.amount >= 0 ? AppColors.greenGradient : AppColors.redGradient)
                        .cornerRadius(8)
                        .annotation(position: .top) {
                            Text(CurrencyManager.shared.format(item.amount))
                                .font(AppFonts.caption2())
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    RuleMark(y: .value("Zero", 0))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .frame(height: 300)
                .padding(.horizontal, 20)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .font(AppFonts.caption())
                    }
                }
                .padding(20)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: AppColors.shadow, radius: 15, x: 0, y: 10)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Category Chart Section
    
    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(AppFonts.title3())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            let categoryData = calculateCategorySpending()
            
            if categoryData.isEmpty {
                emptyState(message: "No expenses found.")
            } else {
                Chart {
                    ForEach(categoryData) { item in
                        SectorMark(
                            angle: .value("Amount", isAnimating ? item.amount : 0),
                            innerRadius: .ratio(0.65),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                        .cornerRadius(6)
                    }
                }
                .frame(height: 300)
                .chartLegend(position: .bottom, alignment: .center, spacing: 16)
                .padding(20)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: AppColors.shadow, radius: 15, x: 0, y: 10)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(AppFonts.title3())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                summaryRow(title: "Total Expenses", value: dataService.expenses.reduce(0) { $0 + $1.amount }, color: AppColors.primary)
                
                let balance = dataService.overallBalance()
                summaryRow(
                    title: balance >= 0 ? "Others owe you" : "You owe total",
                    value: abs(balance),
                    color: balance >= 0 ? AppColors.owedGreen : AppColors.oweRed
                )
                
                summaryRow(title: "Active Friends", value: Double(dataService.friends.count), color: .orange, isCurrency: false)
            }
            .padding(20)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
        }
    }
    
    private func summaryRow(title: String, value: Double, color: Color, isCurrency: Bool = true) -> some View {
        HStack {
            Text(title)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(isCurrency ? CurrencyManager.shared.format(value) : "\(Int(value))")
                .font(AppFonts.headline())
                .foregroundColor(color)
        }
    }
    
    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            Text(message)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Calculations
    
    struct BalanceItem: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
    }
    
    private func calculateFriendBalances() -> [BalanceItem] {
        let balances = ExpenseCalculator.calculateBalances(
            expenses: dataService.expenses,
            settlements: dataService.settlements,
            currentUserId: dataService.currentUser.id,
            userNames: dataService.buildUserNames(for: dataService.friends.map { $0.id } + [dataService.currentUser.id])
        )
        
        var friendBalances: [String: Double] = [:]
        
        for entry in balances {
            if entry.toUserId == dataService.currentUser.id {
                // Someone owes user
                friendBalances[entry.fromUserName, default: 0] += entry.amount
            } else if entry.fromUserId == dataService.currentUser.id {
                // User owes someone
                friendBalances[entry.toUserName, default: 0] -= entry.amount
            }
        }
        
        return friendBalances.map { BalanceItem(name: $0.key, amount: $0.value) }
            .sorted { abs($0.amount) > abs($1.amount) }
    }
    
    struct CategoryItem: Identifiable {
        let id = UUID()
        let category: String
        let amount: Double
    }
    
    private func calculateCategorySpending() -> [CategoryItem] {
        let grouped = Dictionary(grouping: dataService.expenses) { $0.category.rawValue }
        return grouped.map { CategoryItem(category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
}

#Preview {
    NavigationStack {
        FriendsExpenseChartView()
            .environmentObject(DataService())
    }
}
