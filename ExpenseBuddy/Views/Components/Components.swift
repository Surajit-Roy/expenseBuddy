//
//  Components.swift
//  ExpenseBuddy
//

import SwiftUI

// MARK: - Avatar Image Cache
private class AvatarImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var base64String: String? = nil
    var backgroundColor: Color = AppColors.primary
    
    @State private var decodedImage: UIImage? = nil
    
    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
    
    private var gradientColors: [Color] {
        let hash = abs(name.hashValue)
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = (hue1 + 0.1).truncatingRemainder(dividingBy: 1.0)
        return [
            Color(hue: hue1, saturation: 0.6, brightness: 0.8),
            Color(hue: hue2, saturation: 0.7, brightness: 0.7)
        ]
    }
    
    var body: some View {
        Group {
            if let uiImage = decodedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Text(initials)
                        .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear {
            decodeImageIfNeeded()
        }
        .onChange(of: base64String) { _ in
            decodeImageIfNeeded()
        }
    }
    
    private func decodeImageIfNeeded() {
        guard let base64 = base64String, !base64.isEmpty else {
            decodedImage = nil
            return
        }
        
        // 2. Decode on a background thread to prevent UI hang
        Task {
            // Use a hash of the base64 string as a more efficient cache key
            let cacheKey = "\(base64.hashValue)"
            
            // 1. Check cache again inside task
            if let cached = AvatarImageCache.shared.object(forKey: cacheKey as NSString) {
                await MainActor.run {
                    self.decodedImage = cached
                }
                return
            }
            
            let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                guard let data = Data(base64Encoded: base64),
                      let uiImage = UIImage(data: data) else {
                    return nil
                }
                AvatarImageCache.shared.setObject(uiImage, forKey: cacheKey as NSString)
                return uiImage
            }.value
            
            await MainActor.run {
                // Ensure the base64 string hasn't changed while we were decoding
                if self.base64String == base64 {
                    self.decodedImage = image
                }
            }
        }
    }
}

// MARK: - Balance Amount View

struct BalanceAmountView: View {
    let amount: Double
    let fontSize: Font
    @EnvironmentObject var currencyManager: CurrencyManager
    
    init(amount: Double, fontSize: Font = AppFonts.headline()) {
        self.amount = amount
        self.fontSize = fontSize
    }
    
    var body: some View {
        if abs(amount) < 0.01 {
            Text("settled up")
                .font(fontSize)
                .foregroundColor(AppColors.settled)
        } else if amount > 0 {
            VStack(alignment: .trailing, spacing: 2) {
                Text("you are owed")
                    .font(AppFonts.caption2())
                    .foregroundColor(AppColors.owedGreen)
                Text(currencyManager.format(amount))
                    .font(fontSize)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.owedGreen)
            }
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                Text("you owe")
                    .font(AppFonts.caption2())
                    .foregroundColor(AppColors.oweRed)
                Text(currencyManager.format(amount))
                    .font(fontSize)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.oweRed)
            }
        }
    }
}

// MARK: - Expense Row

struct ExpenseRow: View {
    let expense: Expense
    let currentUserId: String
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    
    private var userSplit: Double {
        expense.splits.first { $0.userId == currentUserId }?.amountOwed ?? 0
    }
    
    private var isCurrentUserPayer: Bool {
        expense.paidByUserId == currentUserId
    }
    
    private var balanceAmount: Double {
        if isCurrentUserPayer {
            return expense.amount - userSplit
        } else {
            return -userSplit
        }
    }
    
    private var payerName: String {
        dataService.userCache.name(for: expense.paidByUserId)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: expense.category.colorHex).opacity(0.15))
                    .frame(width: 46, height: 46)
                
                Image(systemName: expense.category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: expense.category.colorHex))
            }
            
            // Title and details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(payerName)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                    Text("paid")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textTertiary)
                    Text(currencyManager.format(expense.amount))
                        .font(AppFonts.caption())
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Balance
            BalanceAmountView(amount: balanceAmount, fontSize: AppFonts.subheadline())
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(AppColors.textTertiary)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.title3())
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(AppFonts.headline())
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(AppColors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 64, height: 64)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Balance Summary Card

struct BalanceSummaryCard: View {
    let title: String
    let amount: Double
    @EnvironmentObject var currencyManager: CurrencyManager
    
    private var isSettled: Bool {
        abs(amount) < 0.01
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.caption())
                .foregroundColor(.white.opacity(0.8))
            
            if isSettled {
                Text("All settled up!")
                    .font(AppFonts.title2())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("No balances")
                        .font(AppFonts.caption2())
                }
                .foregroundColor(.white.opacity(0.7))
            } else {
                Text(currencyManager.format(amount))
                    .font(AppFonts.title2())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: amount > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(amount > 0 ? "You are owed" : "You owe")
                        .font(AppFonts.caption2())
                }
                .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSettled
                ? AnyShapeStyle(AppColors.settledGradient)
                : (amount > 0 ? AnyShapeStyle(AppColors.greenGradient) : AnyShapeStyle(AppColors.redGradient))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var showSeeAll: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFonts.title3())
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            if showSeeAll, let action = action {
                Button(action: action) {
                    Text("See All")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.white)
                
                Text("Loading...")
                    .font(AppFonts.subheadline())
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
