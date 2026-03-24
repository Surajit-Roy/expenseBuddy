import SwiftUI

struct CheckboxField: View {
    @Binding var isChecked: Bool
    var label: String
    var linkText: String? = nil
    var onLinkTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isChecked.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isChecked ? AppColors.primaryLight : Color.white.opacity(0.3), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isChecked ? AppColors.primaryLight : Color.clear)
                        )
                        .frame(width: 24, height: 24)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.darkTextSecondary)
                
                if let linkText = linkText {
                    Button(action: {
                        onLinkTap?()
                    }) {
                        Text(linkText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryLight)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        AppColors.darkBackground.ignoresSafeArea()
        CheckboxField(isChecked: .constant(true), label: "I agree to the", linkText: "Terms & Conditions")
    }
}
