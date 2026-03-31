//
//  PremiumBannerView.swift
//  ExpenseBuddy
//

import SwiftUI

enum PremiumBannerStyle {
    case compact
    case large
}

struct PremiumBannerView: View {
    let style: PremiumBannerStyle
    var featureName: String? = nil
    var iconName: String? = nil
    
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    @State private var showPremiumSheet = false
    
    var body: some View {
        Button(action: {
            showPremiumSheet = true
        }) {
            if style == .compact {
                compactBanner
            } else {
                largeBanner
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulse = 1.05
            }
        }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumPaywallMockView()
        }
    }
    
    private var compactBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName ?? "crown.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("PREMIUM")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .kerning(1.2)
                }
                
                Text(featureName ?? "Unlock Premium")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(14)
        .background(
            ZStack {
                // Creative Mesh-like Background
                AngularGradient(
                    gradient: Gradient(colors: [.purple, .blue, .purple.opacity(0.8), .indigo, .purple]),
                    center: .center,
                    angle: .degrees(rotation)
                )
                .scaleEffect(1.5)
                .blur(radius: 10)
                
                // Flowing light effect
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80, height: 120)
                    .rotationEffect(.degrees(30))
                    .offset(x: pulse > 1.02 ? 200 : -200)
                
                // Subtle glass darkening
                Color.black.opacity(0.15)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear, .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.purple.opacity(0.4), radius: pulse > 1.02 ? 12 : 6, x: 0, y: 4)
        .scaleEffect(pulse)
    }
    
    private var largeBanner: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("EXPENSEBUDDY PREMIUM")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                            .kerning(1.5)
                    }
                    
                    Text("Unlock Your Full Potential")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                premiumFeatureRow(icon: "doc.text.viewfinder", text: "AI Receipt Scanner")
                premiumFeatureRow(icon: "chart.bar.fill", text: "Spending Budgets")
                premiumFeatureRow(icon: "arrow.clockwise.circle.fill", text: "Recurring Expenses")
                premiumFeatureRow(icon: "doc.richtext", text: "Export PDF Reports")
            }
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Upgrade Now")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.top, 8)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
        .padding(20)
        .background(
            ZStack {
                // Rich Background with rotating mesh
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "6366F1"), // Indigo
                        Color(hex: "A855F7"), // Purple
                        Color(hex: "EC4899"), // Pink
                        Color(hex: "3B82F6"), // Blue
                        Color(hex: "6366F1")
                    ]),
                    center: .center,
                    angle: .degrees(rotation)
                )
                .scaleEffect(2)
                .blur(radius: 20)
                
                // Floating animated blobs
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 150)
                            .blur(radius: 30)
                            .offset(x: pulse > 1.02 ? 40 : -40, y: pulse > 1.02 ? -30 : 30)
                        
                        Circle()
                            .fill(Color.cyan.opacity(0.2))
                            .frame(width: 180)
                            .blur(radius: 40)
                            .offset(x: pulse > 1.02 ? -60 : 60, y: pulse > 1.02 ? 50 : -50)
                        
                        // Sparkles
                        ForEach(0..<6) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: CGFloat.random(in: 10...20)))
                                .foregroundColor(.white.opacity(0.6))
                                .offset(
                                    x: CGFloat.random(in: 0...geo.size.width),
                                    y: CGFloat.random(in: 0...geo.size.height)
                                )
                                .opacity(pulse > 1.02 ? 0.8 : 0.2)
                                .scaleEffect(pulse > 1.02 ? 1.2 : 0.8)
                        }
                    }
                }
                
                // Premium Gloss
                LinearGradient(
                    colors: [.white.opacity(0.2), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.purple.opacity(0.5), radius: pulse > 1.02 ? 20 : 10, x: 0, y: 10)
        .scaleEffect(pulse)
    }
    
    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// Temporary Mock View for when they tap the ad
struct PremiumPaywallMockView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var rotation: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Creative Background
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "6366F1").opacity(0.4),
                        Color(hex: "A855F7").opacity(0.4),
                        Color(hex: "EC4899").opacity(0.4),
                        Color(hex: "3B82F6").opacity(0.4),
                        Color(hex: "6366F1").opacity(0.4)
                    ]),
                    center: .center,
                    angle: .degrees(rotation)
                )
                .scaleEffect(2)
                .blur(radius: 50)
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 10)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text("ExpenseBuddy Premium")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                        
                        Text("Unlock everything and take control of your finances like never before.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        premiumFeatureRow(icon: "doc.text.viewfinder", text: "AI Receipt Scanner")
                        premiumFeatureRow(icon: "chart.bar.fill", text: "Spending Budgets")
                        premiumFeatureRow(icon: "arrow.clockwise.circle.fill", text: "Recurring Expenses")
                        premiumFeatureRow(icon: "doc.richtext", text: "Unlimited Data Export")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            premiumManager.isPremiumEnabled = true
                            dismiss()
                        }) {
                            Text("Unlock Professional Features")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "3B82F6")], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 30)
                        
                        Button("Maybe Later") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .padding(.bottom, 20)
                    }
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.secondary.opacity(0.8))
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.purple)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}
