import SwiftUI

struct SplashView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    @State private var isAnimating = false
    @State private var showTitle = false
    @State private var showOfflineMessage = false
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
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                    
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
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
                
                if showOfflineMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text("No Internet Connection")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Please check your network settings and try again.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: checkState) {
                            Text("Retry")
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#6C5CE7"))
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        .padding(.top, 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 40)
                }
            }
            
            // Bottom loading indicator
            VStack {
                Spacer()
                
                if !showOfflineMessage {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.bottom, 60)
                        .opacity(showTitle ? 1.0 : 0.0)
                }
            }
        }
        .onAppear {
            startAnimations()
            checkState()
        }
        .onChange(of: networkMonitor.isConnected) { connected in
            if connected {
                showOfflineMessage = false
                checkState()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            isAnimating = true
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            showTitle = true
        }
    }
    
    private func checkState() {
        // Minimum logo display time
        let minimumTime = DispatchTime.now() + 2.0
        
        DispatchQueue.main.asyncAfter(deadline: minimumTime) {
            if !networkMonitor.isConnected {
                withAnimation {
                    showOfflineMessage = true
                }
                return
            }
            
            // Wait for auth check if needed
            if authService.isInitialCheckDone {
                dismissSplash()
            } else {
                // Poll or wait for property change - for simplicity here we just check again soon
                // A better way would be a Published property observer
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                    if authService.isInitialCheckDone {
                        timer.invalidate()
                        dismissSplash()
                    }
                }
            }
        }
    }
    
    private func dismissSplash() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSplash = false
        }
    }
}
