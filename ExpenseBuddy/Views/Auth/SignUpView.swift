//
//  SignUpView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 6) {
                        Text("Create Account")
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Start splitting expenses with friends")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Form
                VStack(spacing: 16) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 20)
                            
                            TextField("Enter your name", text: $viewModel.name)
                                .textContentType(.name)
                        }
                        .textFieldStyle()
                    }
                    
                    // Email
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
                    
                    // Mobile Number
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mobile Number")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 20)
                            
                            TextField("Enter your mobile number", text: $viewModel.mobileNumber)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                        }
                        .textFieldStyle()
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 20)
                            
                            SecureField("Create a password", text: $viewModel.password)
                                .textContentType(.newPassword)
                        }
                        .textFieldStyle()
                    }
                    
                    // Confirm Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 20)
                            
                            SecureField("Re-enter your password", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                        }
                        .textFieldStyle()
                    }
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
                    .padding(.horizontal, 24)
                }
                
                // Sign Up button
                Button(action: { viewModel.signUp() }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                    }
                }
                .primaryButton()
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 24)
                
                // Sign in link
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                    Button("Sign In") {
                        dismiss()
                    }
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                }
                .padding(.bottom, 32)
            }
        }
        .background(AppColors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
}
