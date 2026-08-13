import SwiftUI

/// Screen 08: Stats Dashboard — Win rate, streak counters, level progress, favorite snack.
struct StatsView: View {
    let onBack: () -> Void

    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared

    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        ScreenScaffold(
            title: "STATS",
            subtitle: "Player Dashboard",
            accent: SSATheme.candyCyan,
            themeColor: SSATheme.candyCyan,
            onBack: onBack
        ) {
                    VStack(spacing: 18) {
                        // Profile Banner
                        SSAGlassCard(padding: 16) {
                            HStack(spacing: 14) {
                                SnacklingMascot(expression: .happy, size: 50, speechBubbleText: "", animateFloat: false)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.displayName)
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text("Master Snack Swapper")
                                        .font(.caption.bold())
                                        .foregroundStyle(SSATheme.candyYellow)
                                }

                                Spacer()
                            }
                        }

                        // Grid Cards (High Score, Total Matches, Win Rate, Streaks)
                        LazyVGrid(columns: layout.gridItems(count: layout.statsGridColumns), spacing: 14) {
                            StatCard(title: "High Score", value: "\(profile.localHighScore)", icon: "trophy.fill", color: SSATheme.candyYellow)
                            StatCard(title: "Levels Cleared", value: "\(profile.maxUnlockedLevel - 1)", icon: "checkmark.seal.fill", color: SSATheme.candyGreen)
                            StatCard(title: "Total Stars", value: "\(meta.stars) ⭐", icon: "star.fill", color: SSATheme.candyYellow)
                            StatCard(title: "Best Streak", value: "13 🔥", icon: "flame.fill", color: SSATheme.candyPink)
                        }

                        // Favorite Snack Card
                        SSAGlassCard(padding: 16) {
                            HStack(spacing: 16) {
                                Text("🍩")
                                    .font(.system(size: 44))
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Favorite Snack")
                                        .font(.caption.bold())
                                        .foregroundStyle(SSATheme.textSecondary)

                                    Text("Frosted Donut")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)

                                    Text("Matched over 420 times!")
                                        .font(.caption)
                                        .foregroundStyle(SSATheme.candyPink)
                                }
                                Spacer()
                            }
                        }

                        // Win Rate Progress Bar
                        SSAGlassCard(padding: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Level Win Rate")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Text("88%")
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(SSATheme.candyGreen)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.1))
                                        Capsule().fill(SSATheme.cyanGradient)
                                            .frame(width: geo.size.width * 0.88)
                                    }
                                }
                                .frame(height: 12)
                            }
                        }
                    }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        SSAGlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(color)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(SSATheme.textSecondary)
                }
            }
        }
    }
}
