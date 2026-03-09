//
//  AuthService.swift
//  ExpenseBuddy
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                Task {
                    await self.fetchUserDocument(uid: user.uid)
                }
            } else {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    private func fetchUserDocument(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if let data = document.data() {
                let user = User(
                    id: uid,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    mobileNumber: data["mobileNumber"] as? String ?? "",
                    profileImage: data["profileImage"] as? String ?? "person.circle.fill",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
                self.currentUser = user
                self.isAuthenticated = true
            } else if let authUser = Auth.auth().currentUser {
                let fallbackUser = User(
                    id: uid,
                    name: authUser.displayName ?? "User",
                    email: authUser.email ?? "",
                    mobileNumber: "",
                    profileImage: "person.circle.fill",
                    createdAt: Date()
                )
                self.currentUser = fallbackUser
                self.isAuthenticated = true
            }
        } catch {
            print("Error fetching user document: \(error)")
        }
    }
    
    // MARK: - Login
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        guard Validator.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            isLoading = false
            return
        }
        
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            // Session handled by addStateDidChangeListener
        } catch let error as NSError {
            if error.domain == AuthErrorDomain {
                let code = error.code
                if code == AuthErrorCode.invalidCredential.rawValue ||
                   code == AuthErrorCode.wrongPassword.rawValue ||
                   code == AuthErrorCode.userNotFound.rawValue {
                    do {
                        let methods = try await Auth.auth().fetchSignInMethods(forEmail: email)
                        if methods.contains("google.com") {
                            self.errorMessage = "This email is registered with Google. Please use 'Continue with Google' to sign in."
                            isLoading = false
                            return
                        }
                    } catch {
                        // Fall through to default error
                    }
                }
            }
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up
    
    func signUp(name: String, email: String, mobileNumber: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2 else {
            errorMessage = "Name must be at least 2 characters."
            isLoading = false
            return
        }
        
        let trimmedMobile = mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard Validator.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            isLoading = false
            return
        }
        
        let passwordCheck = Validator.isValidPassword(password)
        guard passwordCheck.valid else {
            errorMessage = passwordCheck.message
            isLoading = false
            return
        }
        
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = authResult.user.uid
            
            let user = User(
                id: uid,
                name: trimmedName,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                mobileNumber: trimmedMobile,
                profileImage: "person.circle.fill",
                createdAt: Date()
            )
            
            try await createUserDocument(user: user, uid: uid)
        } catch let error as NSError {
            if error.domain == AuthErrorDomain {
                let code = error.code
                if code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    do {
                        let methods = try await Auth.auth().fetchSignInMethods(forEmail: email)
                        if methods.contains("google.com") {
                            self.errorMessage = "This email is already registered with Google. Please use 'Continue with Google' instead."
                            isLoading = false
                            return
                        } else {
                            self.errorMessage = "This email is already registered. Please go to the Login screen to sign in."
                            isLoading = false
                            return
                        }
                    } catch {
                        // Fall through to default error
                    }
                }
            }
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func createUserDocument(user: User, uid: String) async throws {
        let userData: [String: Any] = [
            "id": uid,
            "name": user.name,
            "email": user.email,
            "mobileNumber": user.mobileNumber,
            "profileImage": user.profileImage,
            "createdAt": Timestamp(date: user.createdAt)
        ]
        try await db.collection("users").document(uid).setData(userData)
    }
    
    // MARK: - Logout
    
    func logout() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sign in with Google
    
    #if canImport(UIKit)
    func signInWithGoogle(presenting viewController: UIViewController) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else { 
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Google Client ID"])
            }
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID Token found"])
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: result.user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let uid = authResult.user.uid
            
            // Check if user exists in Firestore, if not create one
            let docSnapshot = try await db.collection("users").document(uid).getDocument()
            if !docSnapshot.exists {
                let user = User(
                    id: uid,
                    name: result.user.profile?.name ?? "User",
                    email: result.user.profile?.email ?? "",
                    mobileNumber: "",
                    profileImage: "person.circle.fill",
                    createdAt: Date()
                )
                try await createUserDocument(user: user, uid: uid)
            }
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    #endif
    
    // MARK: - Reset Password
    
    func resetPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        guard Validator.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            isLoading = false
            return false
        }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
