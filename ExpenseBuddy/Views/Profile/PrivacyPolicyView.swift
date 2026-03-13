//
//  PrivacyPolicyView.swift
//  ExpenseBuddy
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    let policyText = """
    **1. Information We Collect**
    When you use ExpenseBuddy, we collect information you provide directly to us, such as your name, email address, profile picture, and any expense or group data you create. Authentication is securely handled via Firebase.

    **2. How We Use Your Information**
    We use the information we collect to provide, maintain, and improve our services. Specifically, your data is used to calculate shared expenses, sync groups across your devices, and match your email address with friends using the app.

    **3. Data Storage and Security**
    Your data is stored securely on Google Firestore. All rules strictly prohibit unauthorized access. You can only view groups and expenses that you are explicitly a participant or member of.

    **4. Sharing Your Information**
    We do not sell, trade, or rent your personal identification information to others. Your email address and name are only visible to your friends and participants in the groups you join.

    **5. Data Deletion**
    You have the right to request deletion of your account and associated data at any time. Because this is a shared expense app, deleting an account may anonymize your previous splits in groups to preserve ledger integrity for others.

    **6. Changes to this Policy**
    We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.
    """
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                ZStack {
                    LinearGradient(
                        colors: [.gray.opacity(0.8), .black.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkerboard")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text("Privacy Policy")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Policy Content
                VStack(alignment: .leading, spacing: 16) {
                    Text("Last Updated: October 2026")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(.init(policyText))
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textPrimary)
                        .lineSpacing(6)
                        .tint(AppColors.primary) // Affects markdown links
                }
                .padding(24)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
