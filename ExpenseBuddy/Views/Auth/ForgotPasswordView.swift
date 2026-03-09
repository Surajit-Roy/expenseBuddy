//
//  ForgotPasswordView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Header text
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Enter your email and we'll send you\na link to reset your password")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(AppFonts.caption())
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppColors.textTertiary)
                            .frame(width: 20)
                        
                        TextField("Enter your email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    .textFieldStyle()
                }
                .padding(.horizontal, 24)
                
                // Error message
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.oweRed)
                        Text(error)
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.oweRed)
                    }
                }
                
                // Button
                Button(action: { viewModel.resetPassword() }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Reset Link")
                    }
                }
                .primaryButton()
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .alert("Email Sent", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Check your email for a password reset link.")
            }
        }
    }
}
