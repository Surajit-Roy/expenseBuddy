//
//  CreateGroupView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct CreateGroupView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName = ""
    @State private var selectedType: GroupType = .home
    @State private var selectedFriendIds = Set<String>()
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    @State private var appearAnimate = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernBackground()
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        nameSection
                        typeSection
                        membersSection
                        footerSection
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(AppColors.primary)
            }
            .shadow(color: AppColors.primary.opacity(0.2), radius: 10, x: 0, y: 5)
            
            Text("Create a Group")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.top, 20)
        .offset(y: appearAnimate ? 0 : 20)
        .opacity(appearAnimate ? 1 : 0)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Group Name")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(groupName.count)/50")
                    .font(AppFonts.caption2())
                    .foregroundColor(groupName.count > 50 ? AppColors.oweRed : AppColors.textTertiary)
            }
            .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primary)
                TextField("e.g., Roommates, Trip to Goa", text: $groupName)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .onChange(of: groupName) { _, newValue in
                        if newValue.count > 50 { groupName = String(newValue.prefix(50)) }
                    }
            }
            .padding(18)
            .glassStyle(cornerRadius: 18)
            .padding(.horizontal, 24)
        }
        .offset(y: appearAnimate ? 0 : 20)
        .opacity(appearAnimate ? 1 : 0)
    }
    
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Group Type")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(GroupType.allCases, id: \.self) { type in
                        Button(action: { selectedType = type }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    if selectedType == type {
                                        Circle()
                                            .fill(AppColors.primary.opacity(0.15))
                                    } else {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    }
                                    
                                    Image(systemName: type.icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(selectedType == type ? AppColors.primary : AppColors.textTertiary)
                                }
                                .frame(width: 52, height: 52)
                                .shadow(color: selectedType == type ? AppColors.primary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                                
                                Text(type.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedType == type ? AppColors.textPrimary : AppColors.textTertiary)
                            }
                            .frame(width: 70)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            }
        }
        .offset(y: appearAnimate ? 0 : 20)
        .opacity(appearAnimate ? 1 : 0)
    }
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Add Members")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(selectedFriendIds.count) selected")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            
            if dataService.friends.isEmpty {
                emptyFriendsView
            } else {
                friendsListView
            }
        }
        .offset(y: appearAnimate ? 0 : 20)
        .opacity(appearAnimate ? 1 : 0)
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(AppColors.textTertiary)
            Text("Add some friends first to include them in the group")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 40)
    }
    
    private var friendsListView: some View {
        VStack(spacing: 12) {
            ForEach(dataService.friends) { friend in
                let isSelected = selectedFriendIds.contains(friend.id)
                
                Button(action: {
                    if isSelected { selectedFriendIds.remove(friend.id) }
                    else { selectedFriendIds.insert(friend.id) }
                }) {
                    HStack(spacing: 14) {
                        let resolvedFriend = dataService.userCache.userOrPlaceholder(for: friend.id)
                        AvatarView(name: resolvedFriend.name, size: 44, base64String: resolvedFriend.profileImage)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resolvedFriend.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                            Text(resolvedFriend.email)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
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
    
    private var footerSection: some View {
        VStack(spacing: 24) {
            // Error message
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(AppFonts.caption())
                .foregroundColor(AppColors.oweRed)
                .padding(.horizontal, 24)
            }
            
            // Create button
            Button(action: createGroup) {
                HStack {
                    Spacer()
                    Text("Create Group")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(height: 60)
                .background(
                    LinearGradient(colors: [AppColors.primary, AppColors.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 24)
            .disabled(!canCreate)
            .opacity(canCreate ? 1 : 0.5)
            .offset(y: appearAnimate ? 0 : 20)
            .opacity(appearAnimate ? 1 : 0)
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
            .alert("Group Created!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\"\(groupName.trimmingCharacters(in: .whitespacesAndNewlines))\" has been created with \(selectedFriendIds.count + 1) members.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appearAnimate = true
                }
            }
        }
    }
    
    private var canCreate: Bool {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !selectedFriendIds.isEmpty
    }
    
    private func createGroup() {
        errorMessage = nil
        
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Name validation
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a group name."
            return
        }
        guard trimmedName.count >= 2 else {
            errorMessage = "Group name must be at least 2 characters."
            return
        }
        
        // Member validation
        guard !selectedFriendIds.isEmpty else {
            errorMessage = "Please select at least 1 member."
            return
        }
        
        // Duplicate name check
        if dataService.groups.contains(where: {
            $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == trimmedName.lowercased()
        }) {
            errorMessage = "A group with this name already exists."
            return
        }
        
        // Build memberIds: current user + selected friends
        var memberIds = [dataService.currentUser.id]
        memberIds.append(contentsOf: Array(selectedFriendIds))
        
        let group = ExpenseGroup(
            id: UUID().uuidString,
            name: trimmedName,
            memberIds: memberIds,
            createdByUserId: dataService.currentUser.id,
            createdAt: Date(),
            updatedAt: nil,
            groupIcon: selectedType.icon,
            groupType: selectedType
        )
        
        dataService.addGroup(group)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showSuccess = true
    }
}
