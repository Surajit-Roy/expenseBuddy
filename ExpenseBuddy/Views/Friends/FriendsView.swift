//
//  FriendsView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct FriendsView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var router: NavigationRouter
    @State private var searchText = ""
    @State private var showAddFriend = false
    
    private var filteredFriends: [User] {
        if searchText.isEmpty { return dataService.friends }
        return dataService.friends.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.friendsPath) {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Overall balance card
                        BalanceSummaryCard(title: "Overall Balance", amount: dataService.overallBalance())
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // Search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textTertiary)
                            TextField("Search friends...", text: $searchText)
                                .font(AppFonts.body())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        
                        // Friends list
                        if filteredFriends.isEmpty {
                            EmptyStateView(
                                icon: "person.2.slash",
                                title: searchText.isEmpty ? "No Friends Yet" : "No Results",
                                subtitle: searchText.isEmpty
                                    ? "Add friends to start splitting expenses"
                                    : "No friends match \"\(searchText)\"",
                                buttonTitle: searchText.isEmpty ? "Add Friend" : nil,
                                action: { showAddFriend = true }
                            )
                            .frame(height: 300)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredFriends) { friend in
                                    NavigationLink(value: friend) {
                                        friendRow(friend)
                                    }
                                    
                                    if friend.id != filteredFriends.last?.id {
                                        Divider().padding(.leading, 76).padding(.horizontal, 20)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Friends")
            .navigationDestination(for: User.self) { friend in
                FriendDetailView(friend: friend)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFriend = true }) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
            }
        }
    }
    
    private func friendRow(_ friend: User) -> some View {
        let resolvedUser = dataService.userCache.userOrPlaceholder(for: friend.id)
        
        return HStack(spacing: 5) {
            AvatarView(name: resolvedUser.name, size: 48, base64String: resolvedUser.profileImage)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(resolvedUser.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Text(resolvedUser.email)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.leading, 5)
            
            Spacer()
            
            BalanceAmountView(amount: dataService.balanceWithFriend(friend.id), fontSize: AppFonts.subheadline())
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
