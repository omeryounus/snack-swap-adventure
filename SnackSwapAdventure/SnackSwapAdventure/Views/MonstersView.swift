import SwiftUI

/// Screen 09: Monsters / Snackling Dex — Snackling grid, feed meter, evolution progress & flavor stats.
struct MonstersView: View {
    let onBack: () -> Void

    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared

    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        ScreenScaffold(
            title: "SNACKLING DEX",
            subtitle: "Monster Collection",
            accent: SSATheme.candyPink,
            themeColor: SSATheme.candyPink,
            onBack: onBack
        ) {
                    VStack(spacing: 20) {
                        // Featured Active Mascot Card
                        SSAGlassCard(padding: 16) {
                            HStack(spacing: 16) {
                                SnacklingMascot(expression: .happy, size: 70, speechBubbleText: "", animateFloat: true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ghostie (Primary)")
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text("Favorite: Lollipop 🍭")
                                        .font(.caption.bold())
                                        .foregroundStyle(SSATheme.candyPink)

                                    Text("Full & Happy • Level 14 Buff: +10% Score")
                                        .font(.caption2)
                                        .foregroundStyle(SSATheme.textSecondary)
                                }
                                Spacer()
                            }
                        }

                        // Snackling Grid
                        Text("All Snacklings (\(meta.unlockedMonsterIDs.count)/6)")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: layout.gridItems(count: layout.monsterGridColumns), spacing: 14) {
                            MonsterCard(name: "Ghostie", snack: "Lollipop 🍭", emoji: "👻", isUnlocked: true)
                            MonsterCard(name: "Poppy", snack: "Popcorn 🍿", emoji: "🍿", isUnlocked: meta.unlockedMonsterIDs.contains("popcorn"))
                            MonsterCard(name: "Chip", snack: "Cookie 🍪", emoji: "🍪", isUnlocked: meta.unlockedMonsterIDs.contains("cookie"))
                            MonsterCard(name: "Donutty", snack: "Donut 🍩", emoji: "🍩", isUnlocked: meta.unlockedMonsterIDs.contains("donut"))
                            MonsterCard(name: "Fizz", snack: "Soda 🥤", emoji: "🥤", isUnlocked: meta.unlockedMonsterIDs.contains("soda"))
                            MonsterCard(name: "Sweetie", snack: "Candy 🍬", emoji: "🍬", isUnlocked: meta.unlockedMonsterIDs.contains("candy"))
                        }
                    }
        }
    }
}

private struct MonsterCard: View {
    let name: String
    let snack: String
    let emoji: String
    let isUnlocked: Bool

    var body: some View {
        SSAGlassCard(padding: 14, cornerRadius: 18) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? SSATheme.candyPink.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 60, height: 60)

                    Text(isUnlocked ? emoji : "🔒")
                        .font(.system(size: isUnlocked ? 32 : 24))
                }

                VStack(spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isUnlocked ? .white : SSATheme.textMuted)

                    Text(snack)
                        .font(.caption2.bold())
                        .foregroundStyle(isUnlocked ? SSATheme.candyYellow : SSATheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
