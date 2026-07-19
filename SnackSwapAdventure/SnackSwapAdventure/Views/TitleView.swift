import SwiftUI

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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.10, blue: 0.32),
                    Color(red: 0.35, green: 0.15, blue: 0.45),
                    Color(red: 0.55, green: 0.25, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft floating snack emojis
            ForEach(0..<8, id: \.self) { i in
                Text(SnackType.allCases[i % 6].emoji)
                    .font(.system(size: 28 + CGFloat(i % 3) * 8))
                    .opacity(0.18)
                    .offset(
                        x: CGFloat((i % 4) * 70 - 100),
                        y: CGFloat((i / 2) * 80 - 180)
                    )
                    .rotationEffect(.degrees(Double(i) * 12))
            }

            VStack(spacing: 28) {
                Spacer()

                Text("👾")
                    .font(.system(size: 88))
                    .scaleEffect(bounce ? 1.08 : 0.95)
                    .shadow(color: .purple.opacity(glow ? 0.7 : 0.2), radius: glow ? 24 : 8)
                    .animation(
                        .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                        value: bounce
                    )

                VStack(spacing: 8) {
                    Text("Snack Swap")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Adventure")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Match snacks. Feed monsters. Feel the yum.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        SoundManager.shared.playUITap()
                        onPlay()
                    } label: {
                        Text("Play")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.pink, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .pink.opacity(0.45), radius: 12, y: 6)
                    }

                    Button {
                        SoundManager.shared.playUITap()
                        onWorldMap()
                    } label: {
                        Text("World Map")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.12))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    }

                    HStack(spacing: 12) {
                        secondaryButton(title: "Ranks", emoji: "🏆", action: onLeaderboard)
                        secondaryButton(title: "Stats", emoji: "📊", action: onStats)
                    }
                    HStack(spacing: 12) {
                        secondaryButton(title: "Monsters", emoji: "👾", action: onMonsters)
                        secondaryButton(title: "Shop", emoji: "🛒", action: onShop)
                    }
                    Button {
                        SoundManager.shared.playUITap()
                        onInvite()
                    } label: {
                        HStack {
                            Text("🎁")
                            Text("Invite Friends · Free ⭐")
                                .font(.subheadline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [.yellow.opacity(0.35), .orange.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            bounce = true
            glow = true
        }
    }

    private func secondaryButton(title: String, emoji: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.playUITap()
            action()
        } label: {
            HStack {
                Text(emoji)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .foregroundStyle(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    TitleView(onPlay: {}, onWorldMap: {}, onLeaderboard: {}, onStats: {})
}
