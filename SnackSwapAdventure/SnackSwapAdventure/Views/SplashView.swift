import SwiftUI

/// Screen 11: Splash / Loading screen with logo, ghost mascot, and smooth loading progress bar.
struct SplashView: View {
    let onFinished: () -> Void

    @State private var progress: Double = 0.0
    @State private var statusText: String = "Loading Delicious Snacks..."

    var body: some View {
        ZStack {
            WorldBackgroundPlate(themeColor: SSATheme.candyPink)

            VStack(spacing: 24) {
                Spacer()

                // Floating Ghost Mascot
                SnacklingMascot(
                    expression: .happy,
                    size: 110,
                    speechBubbleText: "Snack Swap Adventure!"
                )

                // Game Title Logo Block
                VStack(spacing: 8) {
                    Text("SNACK SWAP")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(SSATheme.goldGradient)
                        .shadow(color: SSATheme.candyPink.opacity(0.4), radius: 8, x: 0, y: 3)

                    Text("ADVENTURE")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(4)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                }

                Spacer()

                // Glass Loading Card & Progress Bar
                SSAGlassCard(padding: 20, cornerRadius: 24) {
                    VStack(spacing: 12) {
                        HStack {
                            Text(statusText)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(SSATheme.textSecondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(SSATheme.candyYellow)
                        }

                        // Progress Bar Container
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))

                                Capsule()
                                    .fill(SSATheme.primaryGradient)
                                    .frame(width: max(16, geo.size.width * progress))
                                    .shadow(color: SSATheme.candyPink.opacity(0.5), radius: 6, y: 0)
                            }
                        }
                        .frame(height: 14)
                    }
                }
                .frame(maxWidth: 380)
                .padding(.horizontal, 24)

                Text("v2.0 • Powered by Antigravity Engine")
                    .font(.caption2.bold())
                    .foregroundStyle(SSATheme.textMuted)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            simulateLoading()
        }
    }

    private func simulateLoading() {
        withAnimation(.easeInOut(duration: 0.6)) {
            progress = 0.35
            statusText = "Warming up Oven..."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) {
                progress = 0.75
                statusText = "Popcorn & Cookies Ready!"
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                progress = 1.0
                statusText = "Ready to Play!"
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            onFinished()
        }
    }
}
