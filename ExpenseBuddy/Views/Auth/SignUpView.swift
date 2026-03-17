import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Animation States
    @State private var appearHeader = false
    @State private var appearForm = false
    @State private var appearFooter = false
    
    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.darkBackground.ignoresSafeArea()
            AmbientGlowView()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryGradient.opacity(0.8))
                                .frame(width: 80, height: 80)
                                .blur(radius: 20)
                            
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 6) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Join ExpenseBuddy today")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.darkTextSecondary)
                        }
                    }
                    .opacity(appearHeader ? 1 : 0)
                    .offset(y: appearHeader ? 0 : 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Fields
                        Group {
                            authField(icon: "person.fill", placeholder: "Full Name", text: $viewModel.name)
                            authField(icon: "envelope.fill", placeholder: "Email", text: $viewModel.email, keyboardType: .emailAddress)
                            authField(icon: "phone.fill", placeholder: "Mobile Number", text: $viewModel.mobileNumber, keyboardType: .phonePad)
                            authSecureField(icon: "lock.fill", placeholder: "Password", text: $viewModel.password)
                            authSecureField(icon: "lock.fill", placeholder: "Confirm Password", text: $viewModel.confirmPassword)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.oweRed)
                                .padding(.top, 4)
                        }
                        
                        Button(action: { viewModel.signUp() }) {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                        }
                        .primaryButton()
                        .disabled(viewModel.isLoading)
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appearForm ? 1 : 0)
                    .offset(y: appearForm ? 0 : 30)
                    
                    // Footer
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(AppColors.darkTextSecondary)
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(AppColors.primaryLight)
                        .fontWeight(.bold)
                    }
                    .font(.system(size: 15, design: .rounded))
                    .padding(.bottom, 40)
                    .opacity(appearFooter ? 1 : 0)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appearHeader = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { appearForm = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) { appearFooter = true }
        }
    }
    
    @ViewBuilder
    private func authField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 20)
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .glassStyle()
    }
    
    @ViewBuilder
    private func authSecureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 20)
            SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)))
                .foregroundColor(.white)
        }
        .glassStyle()
    }
}
