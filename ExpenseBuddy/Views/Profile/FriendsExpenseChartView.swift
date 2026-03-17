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
    
    @State private var appearAnimate = false
    
    var body: some View {
        ZStack {
            ModernBackground()
            
            VStack(spacing: 0) {
                // Custom Segmented Picker
                HStack(spacing: 4) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedChart = type
                            }
                        }) {
                            Text(type.rawValue)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(selectedChart == type ? AppColors.primary : Color.clear)
                                .foregroundColor(selectedChart == type ? .white : AppColors.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .offset(y: appearAnimate ? 0 : -10)
                .opacity(appearAnimate ? 1 : 0)
                
                ScrollView {
                    VStack(spacing: 32) {
                        if selectedChart == .balances {
                            balanceChartSection
                                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                        } else {
                            categoryChartSection
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        }
                        
                        summarySection
                            .offset(y: appearAnimate ? 0 : 20)
                            .opacity(appearAnimate ? 1 : 0)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Spending Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimate = true
            }
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Balance Chart Section
    
    private var balanceChartSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Friend Balances")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            let balances = calculateFriendBalances()
            
            if balances.isEmpty {
                emptyState(message: "No balances to display.")
            } else {
                VStack(spacing: 20) {
                    Chart {
                        ForEach(balances) { item in
                            BarMark(
                                x: .value("Friend", item.name),
                                y: .value("Amount", isAnimating ? item.amount : 0)
                            )
                            .foregroundStyle(item.amount >= 0 ? AppColors.primary.gradient : Color.red.gradient)
                            .cornerRadius(10)
                            .annotation(position: .top) {
                                Text(CurrencyManager.shared.format(item.amount))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.bottom, 4)
                            }
                        }
                        
                        RuleMark(y: .value("Zero", 0))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .foregroundStyle(Color.gray.opacity(0.3))
                    }
                    .frame(height: 250)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine().foregroundStyle(Color.gray.opacity(0.1))
                            AxisValueLabel().font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel().font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .padding(24)
                .glassStyle(cornerRadius: 30)
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Category Chart Section
    
    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Spending by Category")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            let categoryData = calculateCategorySpending()
            
            if categoryData.isEmpty {
                emptyState(message: "No expenses found.")
            } else {
                VStack(spacing: 20) {
                    Chart {
                        ForEach(categoryData) { item in
                            SectorMark(
                                angle: .value("Amount", isAnimating ? item.amount : 0),
                                innerRadius: .ratio(0.7),
                                angularInset: 3
                            )
                            .foregroundStyle(by: .value("Category", item.category))
                            .cornerRadius(8)
                        }
                    }
                    .frame(height: 250)
                    .chartLegend(position: .bottom, alignment: .center, spacing: 16)
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            let total = categoryData.reduce(0) { $0 + $1.amount }
                            VStack {
                                Text("Total")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.textTertiary)
                                Text(CurrencyManager.shared.format(total))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 10)
                        }
                    }
                }
                .padding(24)
                .glassStyle(cornerRadius: 30)
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Quick Summary")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                summaryRow(title: "Total Expenses", value: dataService.expenses.reduce(0) { $0 + $1.amount }, color: AppColors.primary, icon: "cart.fill")
                
                Divider().padding(.leading, 56).opacity(0.3)
                
                let balance = dataService.overallBalance()
                summaryRow(
                    title: balance >= 0 ? "Others Owe You" : "You Owe Total",
                    value: abs(balance),
                    color: balance >= 0 ? AppColors.owedGreen : AppColors.oweRed,
                    icon: balance >= 0 ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill"
                )
                
                Divider().padding(.leading, 56).opacity(0.3)
                
                summaryRow(title: "Active Friends", value: Double(dataService.friends.count), color: .orange, icon: "person.2.fill", isCurrency: false, isLast: true)
            }
            .glassStyle(cornerRadius: 24)
            .padding(.horizontal, 24)
        }
    }
    
    private func summaryRow(title: String, value: Double, color: Color, icon: String, isCurrency: Bool = true, isLast: Bool = false) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(isCurrency ? CurrencyManager.shared.format(value) : "\(Int(value))")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(16)
    }
    
    private func emptyState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary.gradient.opacity(0.3))
            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .glassStyle(cornerRadius: 30)
        .padding(.horizontal, 24)
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
