//
//  AuthViewModel.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var mobileNumber = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var hasAcceptedTerms = false
    
    let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    var isSignUpValid: Bool {
        !name.isEmpty && 
        Validator.isValidEmail(email) && 
        !mobileNumber.isEmpty && 
        Validator.isValidPassword(password).valid && 
        password == confirmPassword && 
        hasAcceptedTerms
    }
    
    var isLoginValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    func login() {
        Task {
            isLoading = true
            errorMessage = nil
            await authService.login(email: email, password: password)
            isLoading = false
            if let error = authService.errorMessage {
                errorMessage = error
            }
        }
    }
    
    func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        Task {
            isLoading = true
            errorMessage = nil
            await authService.signUp(name: name, email: email, mobileNumber: mobileNumber, password: password)
            isLoading = false
            if let error = authService.errorMessage {
                errorMessage = error
            }
        }
    }
    
    func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address to continue."
            return
        }
        
        guard Validator.isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            let success = await authService.resetPassword(email: trimmedEmail)
            isLoading = false
            if success {
                showSuccessAlert = true
            } else if let error = authService.errorMessage {
                errorMessage = error
            }
        }
    }
    
    #if canImport(UIKit)
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            self.errorMessage = "Unable to find the root view to present Google Sign-In."
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            await authService.signInWithGoogle(presenting: rootVC)
            isLoading = false
            if let error = authService.errorMessage {
                errorMessage = error
            }
        }
    }
    #endif
    
    func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
        errorMessage = nil
    }
}
