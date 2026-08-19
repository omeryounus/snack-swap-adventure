import SwiftUI

/// Compact hearts + countdown, shown in the title bar.
struct LivesPill: View {
    @ObservedObject var lives = LivesManager.shared
    /// Ticks the countdown without the manager republishing every second.
    @State private var now = Date()

    @Environment(\.adaptiveLayout) private var layout
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: lives.hasLife ? "heart.fill" : "heart.slash.fill")
                .font(.system(size: layout.isPad ? 18 : 15, weight: .bold))
                .foregroundStyle(lives.hasLife ? Color(hex: "FF3D8A") : SSATheme.textMuted)

            Text("\(lives.lives)")
                .font(.system(size: layout.topBarNameFont, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)

            if let seconds = lives.secondsUntilNextLife(now: now) {
                Text(Self.countdown(seconds))
                    .font(.system(size: layout.topBarDetailFont, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(SSATheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, layout.topBarChipPaddingH)
        .padding(.vertical, layout.topBarChipPaddingV)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        .onReceive(tick) { value in
            now = value
            lives.refresh(now: value)
        }
        .accessibilityLabel("\(lives.lives) of \(LivesManager.maxLives) lives")
    }

    static func countdown(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// Shown when the player tries to start a level with an empty tank.
struct OutOfLivesOverlay: View {
    let onWatchAd: () -> Void
    let onSpendStars: () -> Void
    let onClose: () -> Void

    @ObservedObject private var lives = LivesManager.shared
    @ObservedObject private var profile = PlayerProfile.shared
    @State private var now = Date()
    @State private var isWatchingAd = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
                .onTapGesture { onClose() }

            AdaptiveModalCard {
                VStack(spacing: 16) {
                    Text("💔")
                        .font(.system(size: 52))

                    Text("Out of Lives")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    if let seconds = lives.secondsUntilNextLife(now: now) {
                        VStack(spacing: 4) {
                            Text("Next life in")
                                .font(.caption.bold())
                                .foregroundStyle(SSATheme.textSecondary)
                            Text(LivesPill.countdown(seconds))
                                .font(.system(size: 30, weight: .black, design: .rounded).monospacedDigit())
                                .foregroundStyle(Color(hex: "FF3D8A"))
                        }
                    }

                    // Offered only when an ad can actually play. Without a
                    // network the button used to spin and then do nothing.
                    if AdConfig.adsEnabled {
                    Button {
                        isWatchingAd = true
                        onWatchAd()
                    } label: {
                        Label(isWatchingAd ? "Loading ad…" : "Watch Ad  ·  +1 ❤️", systemImage: "play.rectangle.fill")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isWatchingAd)
                    }

                    Button(action: onSpendStars) {
                        Label(
                            "Refill for \(LivesManager.refillStarCost) ⭐",
                            systemImage: "sparkles"
                        )
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .opacity(profile.stars >= LivesManager.refillStarCost ? 1 : 0.45)
                    }
                    .disabled(profile.stars < LivesManager.refillStarCost)

                    Text("You have \(profile.stars) ⭐")
                        .font(.caption)
                        .foregroundStyle(SSATheme.textSecondary)

                    Button("Not now", action: onClose)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SSATheme.textSecondary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onReceive(tick) { value in
            now = value
            lives.refresh(now: value)
            if lives.hasLife { onClose() }
        }
    }
}
