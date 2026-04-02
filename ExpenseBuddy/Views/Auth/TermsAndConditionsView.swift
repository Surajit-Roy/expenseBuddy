import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animateItems = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Professional Dark Theme Background
                AppColors.darkBackground.ignoresSafeArea()
                AmbientGlowView()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // --- Header Section ---
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(AppColors.primaryGradient)
                                    .shadow(color: AppColors.primary.opacity(0.5), radius: 10, x: 0, y: 5)
                                
                                Spacer()
                                
                                Text("v1.2")
                                    .font(AppFonts.caption())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.primary.opacity(0.2))
                                    .foregroundColor(AppColors.primaryLight)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(AppColors.primaryLight.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Terms & Conditions")
                                    .font(AppFonts.largeTitle())
                                    .foregroundColor(.white)
                                
                                Text("Last Updated: March 15, 2026")
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.primaryLight)
                                    .kerning(0.5)
                            }
                        }
                        .padding(.top, 20)
                        .opacity(animateItems ? 1 : 0)
                        .offset(y: animateItems ? 0 : 20)
                        
                        // --- Introduction ---
                        Text("Please read these terms carefully before using ExpenseBuddy. These terms govern your access to and use of our application.")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.darkTextSecondary)
                            .lineSpacing(4)
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 20)
                        
                        // --- Terms Cards ---
                        VStack(spacing: 20) {
                            TermCard(
                                icon: "checkmark.shield.fill",
                                index: "01",
                                title: "Acceptance of Terms",
                                content: "By accessing or using ExpenseBuddy, you agree to be bound by these Terms and Conditions. If you do not agree to all terms, please do not use our service.",
                                delay: 0.1
                            )
                            
                            TermCard(
                                icon: "square.grid.2x2.fill",
                                index: "02",
                                title: "Service Description",
                                content: "ExpenseBuddy provides digital tools for expense tracking and group management. We are an informational service, not a financial transaction provider.",
                                delay: 0.2
                            )
                            
                            TermCard(
                                icon: "person.fill.checkmark",
                                index: "03",
                                title: "User Responsibilities",
                                content: "You are responsible for your account security and data accuracy. Financial arrangements made via ExpenseBuddy are between you and your peers.",
                                delay: 0.3
                            )
                            
                            TermCard(
                                icon: "lock.shield.fill",
                                index: "04",
                                title: "Privacy & Data",
                                content: "We respect your privacy. Our policy detail how we handle data. By using the app, you consent to information collection as outlined in our Privacy Policy.",
                                delay: 0.4
                            )
                            
                            TermCard(
                                icon: "exclamationmark.triangle.fill",
                                index: "05",
                                title: "Limitation of Liability",
                                content: "ExpenseBuddy is provided 'as is'. We are not liable for any damages, financial losses, or disputes arising from the use of this application.",
                                delay: 0.5
                            )
                        }
                        
                        // --- Contact Section ---
                        VStack(alignment: .center, spacing: 20) {
                            Text("Questions or Concerns?")
                                .font(AppFonts.headline())
                                .foregroundColor(.white)
                            
                            Button(action: {
                                // Action for support email
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                    Text("support@expensebuddy.app")
                                }
                                .font(AppFonts.headline())
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(AppColors.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: AppColors.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                            }
                            
                            Text("© 2026 ExpenseBuddy Team. All rights reserved.")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.darkTextSecondary)
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .opacity(animateItems ? 1 : 0)
                        .offset(y: animateItems ? 0 : 20)
                        
                    }
                    .padding(.horizontal, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.primaryLight)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateItems = true
            }
        }
    }
}

// MARK: - Helper Views

struct TermCard: View {
    let icon: String
    let index: String
    let title: String
    let content: String
    let delay: Double
    
    @State private var show = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Section Icon with Glow
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.12))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.primaryGradient)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(AppFonts.title3())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(index)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColors.primaryLight.opacity(0.7))
                    }
                    
                    Text(content)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.darkTextSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4) // Align text better with the 48pt icon
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(AppColors.darkCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(show ? 1 : 0)
        .offset(y: show ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay)) {
                show = true
            }
        }
    }
}

#Preview {
    TermsAndConditionsView()
}
