import SwiftUI

struct TermsAcceptanceOverlay: View {
    @EnvironmentObject var dataService: DataService
    @State private var isChecked = false
    @State private var isLoading = false
    @State private var showFullTerms = false
    
    // Animation states
    @State private var appear = false
    
    var body: some View {
        ZStack {
            // Background blur to dim the app content
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeOut(duration: 0.5)) {
                        appear = true
                    }
                }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.primaryLight)
                        .padding(.top, 20)
                    
                    Text("Terms of Service Update")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Please review and accept our updated terms to continue using ExpenseBuddy.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppColors.darkTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
                
                // Content area (Summary of terms)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        termBullet(icon: "shield.fill", title: "Privacy First", text: "We value your privacy and only collect data necessary to provide our services.")
                        termBullet(icon: "banknote.fill", title: "Financial Tracking", text: "ExpenseBuddy is for recording expenses only. We don't handle real money.")
                        termBullet(icon: "person.2.fill", title: "Shared Responsibility", text: "You are responsible for the accuracy of expenses you record with friends.")
                    }
                    .padding(20)
                }
                .frame(maxHeight: 280)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                
                // Checkbox and Accept Button
                VStack(spacing: 20) {
                    CheckboxField(
                        isChecked: $isChecked,
                        label: "I have read and agree to the",
                        linkText: "Terms & Conditions",
                        onLinkTap: { showFullTerms = true }
                    )
                    
                    Button(action: { acceptTerms() }) {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Accept & Continue")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                    }
                    .primaryButton()
                    .disabled(!isChecked || isLoading)
                    .opacity(isChecked ? 1 : 0.6)
                }
                .padding(24)
            }
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(AppColors.darkCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(20)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
        }
        .sheet(isPresented: $showFullTerms) {
            TermsAndConditionsView()
        }
    }
    
    private func termBullet(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primaryLight)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(text)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.darkTextSecondary)
                    .lineSpacing(2)
            }
        }
    }
    
    private func acceptTerms() {
        isLoading = true
        Task {
            await dataService.updateTermsAcceptance(accepted: true)
            isLoading = false
        }
    }
}

#Preview {
    TermsAcceptanceOverlay()
        .environmentObject(DataService())
}
