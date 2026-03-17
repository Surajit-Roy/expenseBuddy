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
    
    @State private var appearAnimate = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernBackground()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(AppColors.primary)
                            }
                            .shadow(color: AppColors.primary.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            Text("Add a Friend")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.top, 20)
                        .offset(y: appearAnimate ? 0 : 20)
                        .opacity(appearAnimate ? 1 : 0)
                        
                        // Name field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Name")
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 24)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColors.primary)
                                TextField("Friend's name", text: $name)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                            }
                            .padding(18)
                            .glassStyle(cornerRadius: 18)
                            .padding(.horizontal, 24)
                        }
                        .offset(y: appearAnimate ? 0 : 20)
                        .opacity(appearAnimate ? 1 : 0)
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Email Address")
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(AppColors.primary)
                                    TextField("friend@example.com", text: $email)
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(18)
                                .glassStyle(cornerRadius: 18)
                                
                                if !email.isEmpty && !Validator.isValidEmail(email) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Please enter a valid email address")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(AppColors.oweRed)
                                    .padding(.horizontal, 4)
                                    .transition(.opacity)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .offset(y: appearAnimate ? 0 : 20)
                        .opacity(appearAnimate ? 1 : 0)
                        
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
                        
                        // Add button
                        Button(action: addFriend) {
                            HStack {
                                Spacer()
                                Text("Add Friend")
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
                        .disabled(!canAdd)
                        .opacity(canAdd ? 1 : 0.5)
                        .offset(y: appearAnimate ? 0 : 20)
                        .opacity(appearAnimate ? 1 : 0)
                    }
                    .padding(.bottom, 60)
                }
            }
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
            .alert("Friend Added!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(name.trimmingCharacters(in: .whitespacesAndNewlines)) has been added to your friends list.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appearAnimate = true
                }
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
        
        Task {
            await dataService.addFriend(name: trimmedName, email: trimmedEmail)
            
            await MainActor.run {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                showSuccess = true
            }
        }
    }
}
