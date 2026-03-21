//
//  NotificationBannerView.swift
//  ExpenseBuddy
//

import SwiftUI

/// A premium, animated drop-down banner for in-app expense notifications.
struct NotificationBannerView: View {
    let notification: NotificationPayload
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -120
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#3B82F6"), Color(hex: "#8B5CF6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: "receipt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(notification.body)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Close Button
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Glassmorphic background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppColors.cardBackground.opacity(0.85))
                    
                    // Subtle gradient border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#3B82F6").opacity(0.4),
                                    Color(hex: "#8B5CF6").opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
            .shadow(color: Color(hex: "#3B82F6").opacity(0.1), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .padding(.top, 8)
        .offset(y: offset)
        .opacity(opacity)
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -30 {
                        onDismiss()
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0.1)) {
                offset = 0
                opacity = 1
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notification: \(notification.title). \(notification.body)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to view expense, swipe up to dismiss")
    }
}
