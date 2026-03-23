//
//  ActivityView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct ActivityView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var router: NavigationRouter
    
    var body: some View {
        NavigationStack(path: $router.activityPath) {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if dataService.activities.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Activity Yet",
                        subtitle: "Your expense activity will appear here"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(dataService.groupedActivities, id: \.0) { section, items in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(section)
                                        .font(AppFonts.headline())
                                        .foregroundColor(AppColors.textPrimary)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 0) {
                                        ForEach(items) { item in
                                            if item.type == .expenseAdded, 
                                               let expenseId = item.relatedExpenseId,
                                               let expense = dataService.expenses.first(where: { $0.id == expenseId }) {
                                                NavigationLink(value: expense) {
                                                    activityRow(item)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            } else {
                                                activityRow(item)
                                            }
                                            
                                            if item.id != items.last?.id {
                                                Divider()
                                                    .padding(.leading, 72)
                                                    .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                    .background(AppColors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationDestination(for: Expense.self) { expense in
                ExpenseDetailView(expense: expense, currentUserId: dataService.currentUser.id)
            }
        }
    }
    
    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: item.type.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: item.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: item.type.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let groupName = item.groupName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 8))
                            Text(groupName)
                        }
                        .font(AppFonts.caption2())
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    Text(item.date.formattedWithStyle(.relative))
                        .font(AppFonts.caption2())
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            if let amount = item.amount {
                Text(currencyManager.format(amount))
                    .font(AppFonts.subheadline())
                    .fontWeight(.bold)
                    .foregroundColor(
                        item.type == .settlement ? AppColors.owedGreen : AppColors.textPrimary
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
