//
//  HelpSupportView.swift
//  ExpenseBuddy
//

import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Graphic
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .indigo.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.bubble.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text("How can we help?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Contact Row
                contactCard
                    .padding(.horizontal, 20)
                
                // FAQs
                VStack(alignment: .leading, spacing: 16) {
                    Text("Frequently Asked Questions")
                        .font(AppFonts.title2())
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        faqRow(
                            question: "How do I add a friend?",
                            answer: "Go to the Friends tab, tap the '+' icon in the top right, and search for their email address. If they use ExpenseBuddy, they will be added seamlessly."
                        )
                        faqRow(
                            question: "How are balances calculated?",
                            answer: "ExpenseBuddy automatically calculates who owes who. In groups, it balances all shared expenses, ensuring you clearly see your total outstanding balance across all transactions."
                        )
                        faqRow(
                            question: "Can I settle up outside a group?",
                            answer: "Yes! If you settle up from the Friends tab, your payment will automatically distribute across all shared groups where you owe that person."
                        )
                        faqRow(
                            question: "Can I send reminders for pending balances?",
                            answer: "Yes! You can send push notification reminders to friends who owe you money by tapping the 'Remind' button on their balance details page."
                        )
                        faqRow(
                            question: "How do I change my currency?",
                            answer: "You can change your default display currency right here in the Settings section of your Profile tab."
                        )
                        faqRow(
                            question: "I forgot my password, how can I reset it?",
                            answer: "On the login screen, tap 'Forgot Password?'. Enter your registered email address, and we will send you a secure link to reset your password."
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews
    
    private var contactCard: some View {
        Button(action: {
            if let url = URL(string: "mailto:surajitroy9064@gmail.com") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contact Support")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    Text("support@expensebuddy.app")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func faqRow(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
            
            Text(answer)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 4, x: 0, y: 1)
    }
}
