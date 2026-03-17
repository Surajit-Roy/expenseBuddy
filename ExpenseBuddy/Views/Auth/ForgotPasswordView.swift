import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Animation States
    @State private var appearContent = false
    
    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.darkBackground.ignoresSafeArea()
                AmbientGlowView()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGradient.opacity(0.8))
                            .frame(width: 80, height: 80)
                            .blur(radius: 20)
                        
                        Image(systemName: "key.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(appearContent ? 1 : 0.8)
                    
                    // Header text
                    VStack(spacing: 12) {
                        Text("Reset Password")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Enter your email and we'll send you a link to reset your password")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.darkTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Email input
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 20)
                            
                            TextField("", text: $viewModel.email, prompt: Text("Email Address").foregroundColor(.white.opacity(0.3)))
                                .foregroundColor(.white)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        .glassStyle()
                        
                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.oweRed)
                                .padding(.horizontal, 4)
                        }
                        
                        // Button
                        Button(action: { viewModel.resetPassword() }) {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                        }
                        .primaryButton()
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    Spacer()
                }
                .opacity(appearContent ? 1 : 0)
                .offset(y: appearContent ? 0 : 20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .alert("Email Sent", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Check your email for a password reset link.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appearContent = true
                }
            }
        }
    }
}
