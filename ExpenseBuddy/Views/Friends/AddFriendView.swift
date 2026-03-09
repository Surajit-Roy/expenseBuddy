//
//  AddFriendView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct AddFriendView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header icon
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    Text("Add a Friend")
                        .font(AppFonts.title2())
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 20)
                            TextField("Friend's name", text: $name)
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }
                        .textFieldStyle()
                    }
                    .padding(.horizontal, 24)
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 20)
                            TextField("friend@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .textFieldStyle()
                        
                        // Inline email validation hint
                        if !email.isEmpty && !Validator.isValidEmail(email) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("Enter a valid email address")
                                    .font(AppFonts.caption())
                            }
                            .foregroundColor(AppColors.oweRed)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    
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
                    
                    // Add button
                    Button(action: addFriend) {
                        Text("Add Friend")
                    }
                    .primaryButton()
                    .padding(.horizontal, 24)
                    .disabled(!canAdd)
                    .opacity(canAdd ? 1 : 0.5)
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
            .alert("Friend Added!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(name.trimmingCharacters(in: .whitespacesAndNewlines)) has been added to your friends list.")
            }
        }
    }
    
    private var canAdd: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && Validator.isValidEmail(trimmedEmail)
    }
    
    private func addFriend() {
        errorMessage = nil
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Validate name
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name."
            return
        }
        guard trimmedName.count >= 2 else {
            errorMessage = "Name must be at least 2 characters."
            return
        }
        
        // Validate email
        guard Validator.isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        // Cannot add yourself
        guard trimmedEmail != dataService.currentUser.email.lowercased() else {
            errorMessage = "You cannot add yourself as a friend."
            return
        }
        
        // Duplicate check
        if dataService.friends.contains(where: { $0.email.lowercased() == trimmedEmail }) {
            errorMessage = "A friend with this email already exists."
            return
        }
        
        let friend = User(
            id: UUID().uuidString,
            name: trimmedName,
            email: trimmedEmail,
            profileImage: "person.circle.fill",
            createdAt: Date()
        )
        
        dataService.addFriend(friend)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showSuccess = true
    }
}
