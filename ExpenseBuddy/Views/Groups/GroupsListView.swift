//
//  GroupsListView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct GroupsListView: View {
    @EnvironmentObject var dataService: DataService
    @State private var searchText = ""
    @State private var showCreateGroup = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    private var filteredGroups: [ExpenseGroup] {
        if searchText.isEmpty { return dataService.groups }
        return dataService.groups.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var overallGroupBalance: Double {
        dataService.groups.reduce(0) { $0 + dataService.groupBalance($1) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Balance card
                        BalanceSummaryCard(title: "Groups Balance", amount: overallGroupBalance)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // Search
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textTertiary)
                            TextField("Search groups...", text: $searchText)
                                .font(AppFonts.body())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        
                        // Groups
                        if filteredGroups.isEmpty {
                            EmptyStateView(
                                icon: "person.3",
                                title: searchText.isEmpty ? "No Groups" : "No Results",
                                subtitle: searchText.isEmpty
                                    ? "Create a group to start splitting expenses"
                                    : "No groups match \"\(searchText)\"",
                                buttonTitle: searchText.isEmpty ? "Create Group" : nil,
                                action: { showCreateGroup = true }
                            )
                            .frame(height: 300)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredGroups) { group in
                                    NavigationLink(destination: GroupDetailView(groupId: group.id)) {
                                        GroupCard(group: group, balance: dataService.groupBalance(group))
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        let group = filteredGroups[index]
                                        if dataService.canDeleteGroup(group) {
                                            dataService.deleteGroup(group.id)
                                        } else {
                                            deleteErrorMessage = "You cannot delete a group with unsettled balances."
                                            showDeleteError = true
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                // FAB
                FloatingActionButton(icon: "plus") {
                    showCreateGroup = true
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Groups")
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView()
            }
            .alert("Cannot Delete Group", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }
}

// MARK: - Group Card

struct GroupCard: View {
    let group: ExpenseGroup
    let balance: Double
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(groupColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: group.groupIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(groupColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textTertiary)
                    Text("\(group.members.count) members")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            BalanceAmountView(amount: balance, fontSize: AppFonts.subheadline())
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
    }
    
    private var groupColor: Color {
        switch group.groupType {
        case .home: return .blue
        case .trip: return .orange
        case .office: return .purple
        case .couple: return .pink
        case .other: return .gray
        }
    }
}
