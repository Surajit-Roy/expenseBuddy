//
//  SplashView.swift
//  ExpenseBuddy
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showTitle = false
    @State private var navigateToLogin = false
    @Binding var showSplash: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#5B5EA6"),
                    Color(hex: "#9B59B6"),
                    Color(hex: "#6C5CE7")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App icon
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                    
                    // Inner circle
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    // Icon
                    VStack(spacing: 4) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1.0 : 0.0)
                
                // App name
                VStack(spacing: 8) {
                    Text("ExpenseBuddy")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Split expenses effortlessly")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(showTitle ? 1.0 : 0.0)
                .offset(y: showTitle ? 0 : 20)
            }
            
            // Bottom loading indicator
            VStack {
                Spacer()
                
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.bottom, 60)
                    .opacity(showTitle ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                showTitle = true
            }
            
            // Auto-navigate after splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}
