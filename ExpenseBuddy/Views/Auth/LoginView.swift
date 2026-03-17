import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    // Animation States
    @State private var appearLogo = false
    @State private var appearTitle = false
    @State private var appearForm = false
    @State private var appearFooter = false
    
    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.darkBackground.ignoresSafeArea()
                AmbientGlowView()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Header
                        VStack(spacing: 20) {
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
                                .scaleEffect(appearLogo ? 1 : 0.8)
                                .opacity(appearLogo ? 1 : 0)
                            
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Sign in to track your expenses")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.darkTextSecondary)
                            }
                            .offset(y: appearTitle ? 0 : 20)
                            .opacity(appearTitle ? 1 : 0)
                        }
                        .padding(.top, 60)
                        
                        // Form
                        VStack(spacing: 24) {
                            VStack(spacing: 16) {
                                // Email
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
                                
                                // Password
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 20)
                                    SecureField("", text: $viewModel.password, prompt: Text("Password").foregroundColor(.white.opacity(0.3)))
                                        .foregroundColor(.white)
                                        .textContentType(.password)
                                }
                                .glassStyle()
                            }
                            
                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.primaryLight)
                            }
                            
                            // Error Message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.oweRed)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // Sign In Button
                            Button(action: { viewModel.login() }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                }
                            }
                            .primaryButton()
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.horizontal, 24)
                        .offset(y: appearForm ? 0 : 30)
                        .opacity(appearForm ? 1 : 0)
                        
                        // Footer
                        VStack(spacing: 24) {
                            HStack {
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                                Text("OR").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.3))
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                            }
                            
                            Button(action: { viewModel.signInWithGoogle() }) {
                                HStack(spacing: 12) {
                                    Image("google")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                            
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(AppColors.darkTextSecondary)
                                Button("Sign Up") {
                                    showSignUp = true
                                }
                                .foregroundColor(AppColors.primaryLight)
                                .fontWeight(.bold)
                            }
                            .font(.system(size: 15, design: .rounded))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        .opacity(appearFooter ? 1 : 0)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(authService: authService)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(authService: authService)
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            appearLogo = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            appearTitle = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            appearForm = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            appearFooter = true
        }
    }
}
