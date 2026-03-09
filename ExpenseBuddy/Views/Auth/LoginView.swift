//
//  LoginView.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryGradient)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "indianrupeesign.circle.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 6) {
                            Text("Welcome Back")
                                .font(AppFonts.title())
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Sign in to continue tracking expenses")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    // Form
                    VStack(spacing: 16) {
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
                                
                                SecureField("Enter your password", text: $viewModel.password)
                                    .textContentType(.password)
                            }
                            .textFieldStyle()
                        }
                        
                        // Forgot password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.primary)
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
                    
                    // Login button
                    VStack(spacing: 16) {
                        Button(action: { viewModel.login() }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                            }
                        }
                        .primaryButton()
                        .disabled(viewModel.isLoading)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(AppColors.divider)
                                .frame(height: 1)
                            Text("OR")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textTertiary)
                            Rectangle()
                                .fill(AppColors.divider)
                                .frame(height: 1)
                        }
                        
                        // Social login buttons
                        Button(action: { 
                            #if canImport(UIKit)
                            viewModel.signInWithGoogle() 
                            #endif
                        }) {
                            HStack(spacing: 12) {
                                Image("google")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                Text("Continue with Google")
                            }
                        }
                        .secondaryButton()
                    }
                    .padding(.horizontal, 24)
                    
                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.textSecondary)
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .font(AppFonts.subheadline())
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(AppColors.background)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(authService: authService)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(authService: authService)
            }
        }
    }
}
