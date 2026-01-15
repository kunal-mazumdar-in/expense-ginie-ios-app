import SwiftUI

struct SplashScreenView: View {
    @State private var isPounding = false
    @State private var isActive = false
    
    // Same gradient as HomeView header
    private let gradient = LinearGradient(
        colors: [
            Color(red: 0/255, green: 111/255, blue: 161/255),
            Color(red: 0/255, green: 188/255, blue: 212/255),
            Color(red: 0/255, green: 150/255, blue: 136/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        if isActive {
            MainTabView()
        } else {
            ZStack {
                // Full screen gradient background
                gradient
                    .ignoresSafeArea()
                
                // App name with pounding animation
                VStack(spacing: 16) {
                    Text("Expense Ginie")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(.secondarySystemGroupedBackground))
                        .scaleEffect(isPounding ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                            value: isPounding
                        )
                }
            }
            .onAppear {
                // Start pounding animation
                isPounding = true
                
                // Transition to main app after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(ThemeSettings.shared)
}

