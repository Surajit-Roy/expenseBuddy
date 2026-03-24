//
//  PrivacyPolicyView.swift
//  ExpenseBuddy
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    let policyText = """
    **1. Information We Collect**
    When you use ExpenseBuddy, we collect information you provide directly to us, including your name, email address, profile picture, and any expense, group, or friend data you create. Authentication is securely handled via Firebase. We also collect device tokens for delivering push notifications (Reminders) about pending balances.

    **2. How We Use Your Information**
    Your data is used to calculate shared expenses, synchronize groups and balances across your devices, match your email address with friends, and deliver important push notifications regarding new expenses and settlement reminders.

    **3. Data Storage and Security**
    Your data is stored securely in the cloud using Google Firestore. We employ strict security rules to prohibit unauthorized access. You can only view groups, expenses, and friend connections that you are explicitly a participant in.

    **4. Sharing Your Information**
    We do not sell, trade, or rent your personal information to third parties. Your email address, name, and profile picture are only visible to your added friends and participants in the groups you join.

    **5. Account & Data Deletion**
    You have the right to request the deletion of your account at any time. To preserve financial integrity within shared groups, you cannot delete your profile if you have any outstanding balances (owed or owing). Once all balances are fully settled, you may delete your account. Upon deletion, your personal authentication data is removed, and your previous interactions in shared groups and expenses are anonymized to preserve the ledger history for remaining members.

    **6. Changes to this Policy**
    We may update our Privacy Policy periodically. We will notify you of significant changes by posting the new Privacy Policy within the app.
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
                    Text("Last Updated: April 2026")
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
