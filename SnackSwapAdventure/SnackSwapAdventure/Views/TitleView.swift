import SwiftUI

/// High-contrast candy landing page with clear CTAs and readable hierarchy.
struct TitleView: View {
    let onPlay: () -> Void
    let onWorldMap: () -> Void
    let onLeaderboard: () -> Void
    let onStats: () -> Void
    var onMonsters: () -> Void = {}
    var onShop: () -> Void = {}
    var onInvite: () -> Void = {}

    @State private var bounce = false
    @State private var glow = false
    @State private var floatSnacks = false

    private let candyPink = Color(red: 1.0, green: 0.32, blue: 0.55)
    private let candyOrange = Color(red: 1.0, green: 0.55, blue: 0.18)
    private let candyYellow = Color(red: 1.0, green: 0.88, blue: 0.25)
    private let deepInk = Color(red: 0.07, green: 0.04, blue: 0.14)
    private let panel = Color(red: 0.14, green: 0.09, blue: 0.22)

    var body: some View {
        ZStack {
            // High-contrast background: deep ink + vivid candy glows
            deepInk.ignoresSafeArea()

            // Radial candy lights for depth without washing out text
            Circle()
                .fill(candyPink.opacity(0.35))
                .frame(width: 340, height: 340)
                .blur(radius: 70)
                .offset(x: -120, y: -260)

            Circle()
                .fill(candyOrange.opacity(0.28))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 140, y: -180)

            Circle()
                .fill(Color(red: 0.45, green: 0.2, blue: 0.95).opacity(0.30))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: 40, y: 320)

            // Floating snack accents (subtle, not competing with text)
            ForEach(0..<6, id: \.self) { i in
                Image(SnackType.allCases[i].textureName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42 + CGFloat(i % 2) * 10, height: 42 + CGFloat(i % 2) * 10)
                    .opacity(0.22)
                    .offset(
                        x: CGFloat((i % 3) * 110 - 110) + (floatSnacks ? 6 : -6),
                        y: CGFloat((i / 2) * 90 - 200) + (floatSnacks ? -8 : 8)
                    )
                    .rotationEffect(.degrees(Double(i) * 14 + (floatSnacks ? 4 : -4)))
                    .animation(
                        .easeInOut(duration: 2.2 + Double(i) * 0.15).repeatForever(autoreverses: true),
                        value: floatSnacks
                    )
            }

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                // Hero card
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [candyYellow.opacity(0.55), .clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(glow ? 1.15 : 0.9)

                        Text("👾")
                            .font(.system(size: 84))
                            .scaleEffect(bounce ? 1.08 : 0.96)
                            .shadow(color: candyPink.opacity(0.7), radius: glow ? 22 : 10)
                    }
                    .animation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true), value: bounce)

                    VStack(spacing: 6) {
                        Text("SNACK SWAP")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [candyYellow, candyOrange, candyPink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black.opacity(0.55), radius: 2, y: 2)

                        Text("ADVENTURE")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)

                        Text("Match snacks. Feed monsters. Beat the clock.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.top, 2)
                    }
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(panel.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [candyPink.opacity(0.7), candyYellow.opacity(0.45)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                )
                .padding(.horizontal, 22)

                Spacer(minLength: 20)

                // CTA panel — high contrast buttons
                VStack(spacing: 12) {
                    primaryButton(title: "Play", action: onPlay)

                    secondaryFilledButton(title: "World Map", systemImage: "map.fill", action: onWorldMap)

                    HStack(spacing: 10) {
                        gridButton(title: "Ranks", emoji: "🏆", action: onLeaderboard)
                        gridButton(title: "Stats", emoji: "📊", action: onStats)
                    }
                    HStack(spacing: 10) {
                        gridButton(title: "Monsters", emoji: "👾", action: onMonsters)
                        gridButton(title: "Shop", emoji: "🛒", action: onShop)
                    }

                    Button {
                        SoundManager.shared.playUITap()
                        onInvite()
                    } label: {
                        HStack(spacing: 8) {
                            Text("🎁")
                            Text("Invite Friends · Free ⭐")
                                .font(.subheadline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [candyYellow, candyOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(Color(red: 0.2, green: 0.08, blue: 0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: candyOrange.opacity(0.4), radius: 10, y: 4)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            bounce = true
            glow = true
            floatSnacks = true
        }
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.playUITap()
            action()
        } label: {
            Text(title)
                .font(.title2.weight(.heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [candyPink, candyOrange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                )
                .shadow(color: candyPink.opacity(0.55), radius: 14, y: 6)
        }
    }

    private func secondaryFilledButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.playUITap()
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.14))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
        }
    }

    private func gridButton(title: String, emoji: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.playUITap()
            action()
        } label: {
            HStack(spacing: 8) {
                Text(emoji)
                Text(title)
                    .font(.subheadline.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(panel.opacity(0.95))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    TitleView(onPlay: {}, onWorldMap: {}, onLeaderboard: {}, onStats: {})
}
