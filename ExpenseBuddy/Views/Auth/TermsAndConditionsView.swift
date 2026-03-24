    import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.darkBackground.ignoresSafeArea()
                AmbientGlowView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Terms & Conditions")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Effective Date: March 24, 2026")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.primaryLight)
                        }
                        .padding(.top, 30)
                        
                        // Content Sections
                        VStack(spacing: 28) {
                            termsSection(
                                number: "1",
                                title: "Acceptance of Terms",
                                content: "By accessing or using ExpenseBuddy, you agree to be bound by these Terms and Conditions. If you do not agree to all terms, please do not use our service."
                            )
                            
                            divider()
                            
                            termsSection(
                                number: "2",
                                title: "Description of Service",
                                content: "ExpenseBuddy provides users with tools to track, manage, and split expenses among friends and groups. We provide an information management service, not a financial transaction service."
                            )
                            
                            divider()
                            
                            termsSection(
                                number: "3",
                                title: "User Responsibilities",
                                content: "You are responsible for maintaining the security of your account and the accuracy of all data entered. Any financial arrangements made based on ExpenseBuddy data are between you and your peers."
                            )
                            
                            divider()
                            
                            termsSection(
                                number: "4",
                                title: "Privacy & Data",
                                content: "Our Privacy Policy describes how we handle the information you provide. By using ExpenseBuddy, you consent to the collection and use of this information as set forth therein."
                            )
                            
                            divider()
                            
                            termsSection(
                                number: "5",
                                title: "Limitation of Liability",
                                content: "ExpenseBuddy is provided 'as is' without warranties. We are not liable for any damages, financial losses, or disputes arising from the use of our application."
                            )
                        }
                        
                        // Footer Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Thank you for using ExpenseBuddy.")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("If you have any questions regarding these terms, please contact us at support@expensebuddy.app")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(AppColors.darkTextSecondary)
                                .lineSpacing(4)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryLight)
                }
            }
        }
    }
    
    @ViewBuilder
    private func termsSection(number: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(number)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(AppColors.primaryGradient.opacity(0.8))
                    )
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(content)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AppColors.darkTextSecondary)
                .lineSpacing(6)
                .padding(.leading, 40)
        }
    }
    
    private func divider() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 40)
    }
}

#Preview {
    TermsAndConditionsView()
}
