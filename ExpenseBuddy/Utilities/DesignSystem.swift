//
//  DesignSystem.swift
//  ExpenseBuddy
//

import SwiftUI
import Combine
import UIKit

// MARK: - App Colors (Adaptive Dark/Light)

struct AppColors {
    // Primary palette
    static let primary = Color(hex: "#5B5EA6")
    static let primaryLight = Color(hex: "#8183C4")
    static let primaryDark = Color(hex: "#3D4076")
    
    // Accent
    static let accent = Color(hex: "#1DB954")
    static let accentSecondary = Color(hex: "#FF6B6B")
    
    // Balance colors
    static let owedGreen = Color(hex: "#10B981")
    static let oweRed = Color(hex: "#EF4444")
    static let settled = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.56, green: 0.60, blue: 0.67, alpha: 1) // #8F99AB
            : UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1) // #6B7280
    })
    
    // Backgrounds — fully adaptive
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1) // #0F172A
            : UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1) // #F8FAFC
    })
    
    static let cardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1) // #1E293B
            : UIColor.white
    })
    
    static let secondaryBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.22, blue: 0.31, alpha: 1) // #2C3849
            : UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1) // #F1F5F9
    })
    
    // Text — fully adaptive
    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1) // #F1F5F9
            : UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1) // #1E293B
    })
    
    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.65, blue: 0.74, alpha: 1) // #94A3BC
            : UIColor(red: 0.39, green: 0.45, blue: 0.55, alpha: 1) // #64748B
    })
    
    static let textTertiary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.47, blue: 0.57, alpha: 1) // #667891
            : UIColor(red: 0.58, green: 0.64, blue: 0.72, alpha: 1) // #94A3B8
    })
    
    // Misc
    static let divider = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.25, blue: 0.35, alpha: 1) // #334059
            : UIColor(red: 0.89, green: 0.91, blue: 0.94, alpha: 1) // #E2E8F0
    })
    
    static let shadow = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.clear
            : UIColor.black.withAlphaComponent(0.06)
    })
    
    // Gradient
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#5B5EA6"), Color(hex: "#9B59B6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let greenGradient = LinearGradient(
        colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let redGradient = LinearGradient(
        colors: [Color(hex: "#EF4444"), Color(hex: "#DC2626")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let settledGradient = LinearGradient(
        colors: [Color(hex: "#6B7280"), Color(hex: "#4B5563")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

struct AppFonts {
    static func largeTitle() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func title2() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func title3() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func body() -> Font { .system(size: 17, weight: .regular, design: .rounded) }
    static func callout() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func subheadline() -> Font { .system(size: 15, weight: .regular, design: .rounded) }
    static func footnote() -> Font { .system(size: 13, weight: .regular, design: .rounded) }
    static func caption() -> Font { .system(size: 12, weight: .regular, design: .rounded) }
    static func caption2() -> Font { .system(size: 11, weight: .regular, design: .rounded) }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
    }
}

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFonts.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFonts.headline())
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.primary, lineWidth: 2)
            )
    }
}

struct TextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFonts.body())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    func primaryButton() -> some View {
        modifier(PrimaryButtonModifier())
    }
    
    func secondaryButton() -> some View {
        modifier(SecondaryButtonModifier())
    }
    
    func textFieldStyle() -> some View {
        modifier(TextFieldModifier())
    }
}

// MARK: - Currency Formatter

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @AppStorage("currencySymbol") var symbol: String = "₹" {
        didSet {
            objectWillChange.send()
        }
    }
    
    /// Returns the current AppCurrency based on the stored symbol
    var currentCurrency: AppCurrency {
        AppCurrency(rawValue: symbol) ?? .inr
    }
    
    /// Convert an amount from INR (base) to the user's selected currency
    func convert(_ amount: Double) -> Double {
        let rate = currentCurrency.rateFromINR
        return (amount * rate * 100).rounded() / 100.0
    }
    
    /// Convert an amount from the user's selected currency back to INR (base)
    func convertToINR(_ amount: Double) -> Double {
        let rate = currentCurrency.rateToINR
        return (amount * rate * 100).rounded() / 100.0
    }
    
    /// Format an amount (stored in INR) into the user's selected currency with symbol
    func format(_ amount: Double) -> String {
        let converted = convert(abs(amount))
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: converted)) ?? "0.00"
        return "\(symbol)\(formatted)"
    }
    
    /// Format an amount that is ALREADY in the user's selected currency (e.g. user input)
    func formatInput(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "0.00"
        return "\(symbol)\(formatted)"
    }
    
    func formatSigned(_ amount: Double) -> String {
        if amount > 0 {
            return "+\(format(amount))"
        } else if amount < 0 {
            return "-\(format(amount))"
        }
        return format(0)
    }
}

// MARK: - Supported Currencies

enum AppCurrency: String, CaseIterable, Identifiable {
    case inr = "₹"
    case usd = "$"
    case eur = "€"
    case gbp = "£"
    case jpy = "¥"
    
    var id: String { rawValue }
    
    var symbol: String { rawValue }
    
    /// Exchange rate: 1 INR = X of this currency (approximate rates)
    var rateFromINR: Double {
        switch self {
        case .inr: return 1.0
        case .usd: return 0.012       // 1 INR ≈ 0.012 USD
        case .eur: return 0.011       // 1 INR ≈ 0.011 EUR
        case .gbp: return 0.0095      // 1 INR ≈ 0.0095 GBP
        case .jpy: return 1.78        // 1 INR ≈ 1.78 JPY
        }
    }
    
    /// Exchange rate: 1 of this currency = X INR (for input conversion)
    var rateToINR: Double {
        return 1.0 / rateFromINR
    }
    
    var code: String {
        switch self {
        case .inr: return "INR"
        case .usd: return "USD"
        case .eur: return "EUR"
        case .gbp: return "GBP"
        case .jpy: return "JPY"
        }
    }
    
    var displayName: String {
        "\(code) (\(symbol))"
    }
}

// MARK: - Validation Helpers

struct Validator {
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }
    
    static func isValidPassword(_ password: String) -> (valid: Bool, message: String) {
        if password.count < 6 {
            return (false, "Password must be at least 6 characters")
        }
        if !password.contains(where: { $0.isNumber }) {
            return (false, "Password must contain at least 1 digit")
        }
        return (true, "")
    }
    
    static func isValidAmount(_ text: String) -> Bool {
        guard let amount = Double(text) else { return false }
        return amount > 0 && amount <= 9_999_999.99
    }
    
    static func sanitizeAmountInput(_ text: String) -> String {
        // Allow only digits and one decimal point, max 2 decimal places
        var result = ""
        var hasDecimal = false
        var decimalPlaces = 0
        
        for char in text {
            if char.isNumber {
                if hasDecimal {
                    if decimalPlaces < 2 {
                        result.append(char)
                        decimalPlaces += 1
                    }
                } else {
                    result.append(char)
                }
            } else if char == "." && !hasDecimal {
                result.append(char)
                hasDecimal = true
            }
        }
        return result
    }
}

// MARK: - Date Formatters

extension Date {
    func formatted(as style: DateFormatStyle) -> String {
        let formatter = DateFormatter()
        switch style {
        case .short:
            formatter.dateStyle = .short
        case .medium:
            formatter.dateStyle = .medium
        case .long:
            formatter.dateStyle = .long
        case .relative:
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .short
            return relative.localizedString(for: self, relativeTo: Date())
        case .monthDay:
            formatter.dateFormat = "MMM d"
        case .full:
            formatter.dateFormat = "MMMM d, yyyy"
        }
        return formatter.string(from: self)
    }
    
    enum DateFormatStyle {
        case short, medium, long, relative, monthDay, full
    }
}
