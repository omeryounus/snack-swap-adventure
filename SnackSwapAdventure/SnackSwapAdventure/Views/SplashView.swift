import SwiftUI

/// Screen 11: Splash / Loading — scales type and mascot for SE through iPad, portrait and landscape.
struct SplashView: View {
    let onFinished: () -> Void

    @Environment(\.adaptiveLayout) private var layout
    @State private var progress: Double = 0.0
    @State private var statusText: String = "Loading Delicious Snacks..."

    var body: some View {
        ZStack {
            WorldBackgroundPlate(themeColor: SSATheme.candyPink)

            VStack(spacing: layout.isCompactHeight ? 12 : 24) {
                if !layout.isCompactHeight { Spacer() }

                if layout.isLandscape && layout.isPhone {
                    HStack(spacing: 28) {
                        mascotAndTitle
                        loadingCard
                            .frame(maxWidth: 360)
                    }
                    .padding(.horizontal, layout.screenPadding)
                } else {
                    mascotAndTitle
                    Spacer()
                    loadingCard
                        .frame(maxWidth: min(380, layout.overlayMaxWidth))
                        .padding(.horizontal, layout.screenPadding)
                }

                Text("v2.0 • Powered by Antigravity Engine")
                    .font(.caption2.bold())
                    .foregroundStyle(SSATheme.textMuted)
                    .padding(.bottom, 12)
            }
            .adaptiveSafeAreaPadding(layout)
        }
        .onAppear {
            simulateLoading()
        }
    }

    private var mascotAndTitle: some View {
        VStack(spacing: layout.isCompactHeight ? 8 : 16) {
            SnacklingMascot(
                expression: .happy,
                size: layout.splashMascotSize,
                speechBubbleText: "Snack Swap Adventure!"
            )

            VStack(spacing: 8) {
                Text("SNACK SWAP")
                    .font(.system(size: layout.titleHeroFont, weight: .black, design: .rounded))
                    .foregroundStyle(SSATheme.goldGradient)
                    .shadow(color: SSATheme.candyPink.opacity(0.4), radius: 8, x: 0, y: 3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                Text("ADVENTURE")
                    .font(.system(size: layout.titleSecondaryFont, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
    }

    private var loadingCard: some View {
        SSAGlassCard(padding: 20, cornerRadius: 24) {
            VStack(spacing: 12) {
                HStack {
                    Text(statusText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(SSATheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(SSATheme.candyYellow)
                }

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
