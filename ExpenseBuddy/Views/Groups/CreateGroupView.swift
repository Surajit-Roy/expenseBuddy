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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryGradient)
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Text("Create a Group")
                            .font(AppFonts.title2())
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.top, 12)
                    
                    // Group name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Group Name")
                                .font(AppFonts.caption())
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("\(groupName.count)/50")
                                .font(AppFonts.caption2())
                                .foregroundColor(groupName.count > 50 ? AppColors.oweRed : AppColors.textTertiary)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "pencil")
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 20)
                            TextField("e.g., Roommates, Trip to Goa", text: $groupName)
                                .onChange(of: groupName) { _, newValue in
                                    if newValue.count > 50 {
                                        groupName = String(newValue.prefix(50))
                                    }
                                }
                        }
                        .textFieldStyle()
                    }
                    .padding(.horizontal, 24)
                    
                    // Group type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Group Type")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(GroupType.allCases, id: \.self) { type in
                                    Button(action: { selectedType = type }) {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedType == type ? AppColors.primary.opacity(0.2) : AppColors.secondaryBackground)
                                                    .frame(width: 48, height: 48)
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(selectedType == type ? AppColors.primary : AppColors.textTertiary)
                                            }
                                            Text(type.rawValue)
                                                .font(AppFonts.caption2())
                                                .foregroundColor(selectedType == type ? AppColors.primary : AppColors.textSecondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Members
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Add Members")
                                .font(AppFonts.caption())
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("\(selectedFriendIds.count) selected")
                                .font(AppFonts.caption())
                                .foregroundColor(selectedFriendIds.isEmpty ? AppColors.textTertiary : AppColors.primary)
                        }
                        .padding(.horizontal, 24)
                        
                        if dataService.friends.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundColor(AppColors.textTertiary)
                                Text("Add some friends first")
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(dataService.friends) { friend in
                                    let isSelected = selectedFriendIds.contains(friend.id)
                                    
                                    Button(action: {
                                        if isSelected { selectedFriendIds.remove(friend.id) }
                                        else { selectedFriendIds.insert(friend.id) }
                                    }) {
                                        HStack(spacing: 14) {
                                            AvatarView(name: friend.name, size: 40)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(friend.name)
                                                    .font(AppFonts.headline())
                                                    .foregroundColor(AppColors.textPrimary)
                                                Text(friend.email)
                                                    .font(AppFonts.caption())
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 24))
                                                .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                    }
                                    
                                    if friend.id != dataService.friends.last?.id {
                                        Divider().padding(.leading, 70)
                                    }
                                }
                            }
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }
                    }
                    
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
                    
                    // Create button
                    Button(action: createGroup) {
                        Text("Create Group")
                    }
                    .primaryButton()
                    .padding(.horizontal, 24)
                    .disabled(!canCreate)
                    .opacity(canCreate ? 1 : 0.5)
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
            .alert("Group Created!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\"\(groupName.trimmingCharacters(in: .whitespacesAndNewlines))\" has been created with \(selectedFriendIds.count + 1) members.")
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
