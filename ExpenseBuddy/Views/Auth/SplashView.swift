import SwiftUI

struct SplashView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    @State private var isAnimating = false
    @State private var showTitle = false
    @State private var showOfflineMessage = false
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @Binding var showSplash: Bool
    
    var body: some View {
        ZStack {
            // Premium dark background
            Color(hex: "#0F172A")
                .ignoresSafeArea()
            
            // Animated ambient glows
            AmbientGlowView()
            
            VStack(spacing: 40) {
                // 3D Animated Logo
                ZStack {
                    // Outer soft glow
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(hex: "#5B5EA6").opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        ))
                        .frame(width: 250, height: 250)
                        .scaleEffect(isAnimating ? 1.2 : 0.9)
                        .opacity(isAnimating ? 0.6 : 0.3)
                    
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 15)
                        .rotation3DEffect(
                            .degrees(rotation),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                // App name and tagline
                VStack(spacing: 12) {
                    Text("ExpenseBuddy")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("Split expenses effortlessly")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .kerning(1.2)
                }
                .opacity(showTitle ? 1.0 : 0.0)
                .offset(y: showTitle ? 0 : 20)
                
                if showOfflineMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("No Internet Connection")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Button(action: checkState) {
                            Text("Retry Connection")
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#0F172A"))
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 20)
                }
            }
            
            // Bottom loading indicator
            if !showOfflineMessage && showTitle {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.bottom, 60)
                }
                .transition(.opacity)
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
        // Logo entry
        withAnimation(.interpolatingSpring(stiffness: 60, damping: 10)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Continuous 3D tilt
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            rotation = 20
        }
        
        // Ambient pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
        
        // Text display
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            showTitle = true
        }
    }
    
    private func checkState() {
        let minimumTime = DispatchTime.now() + 2.5
        
        DispatchQueue.main.asyncAfter(deadline: minimumTime) {
            if !networkMonitor.isConnected {
                withAnimation {
                    showOfflineMessage = true
                }
                return
            }
            
            if authService.isInitialCheckDone {
                dismissSplash()
            } else {
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
        withAnimation(.easeInOut(duration: 0.5)) {
            showSplash = false
        }
    }
}

// MARK: - Helper Views

struct AmbientGlowView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#5B5EA6").opacity(0.15))
                .frame(width: 450, height: 450)
                .offset(x: animate ? 100 : -100, y: animate ? -150 : 150)
                .blur(radius: 80)
            
            Circle()
                .fill(Color(hex: "#6C5CE7").opacity(0.15))
                .frame(width: 350, height: 350)
                .offset(x: animate ? -150 : 150, y: animate ? 100 : -100)
                .blur(radius: 70)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
