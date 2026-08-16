import SwiftUI

/// Screen 09: Snackling Dex — the collection half of the game loop. Levels pay
/// snacks, snacks feed Snacklings, evolved Snacklings pay back into play.
struct MonstersView: View {
    let onBack: () -> Void

    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared
    @StateObject private var keeper = SnacklingKeeper.shared

    @Environment(\.adaptiveLayout) private var layout
    @State private var justEvolved: MonsterDef?

    private var unlocked: [MonsterDef] {
        MetaProgress.monsters.filter { meta.isMonsterUnlocked($0.id) }
    }

    var body: some View {
        ScreenScaffold(
            title: "SNACKLING DEX",
            subtitle: "\(unlocked.count)/\(MetaProgress.monsters.count) discovered",
            accent: SSATheme.candyPink,
            themeColor: SSATheme.candyPink,
            onBack: onBack
        ) {
            VStack(spacing: 18) {
                pantryCard
                perksCard

                Text("Snacklings")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 168), spacing: 14)], spacing: 14) {
                    ForEach(MetaProgress.monsters) { monster in
                        SnacklingCard(
                            monster: monster,
                            isUnlocked: meta.isMonsterUnlocked(monster.id),
                            feeds: keeper.feedCount(for: monster),
                            pantry: keeper.count(of: monster.favouriteSnack),
                            onFeed: { feed(monster) }
                        )
                    }
                }
            }
        }
        .alert(
            "\(justEvolved?.name ?? "") evolved!",
            isPresented: Binding(
                get: { justEvolved != nil },
                set: { if !$0 { justEvolved = nil } }
            ),
            presenting: justEvolved
        ) { _ in
            Button("Nice", role: .cancel) { justEvolved = nil }
        } message: { monster in
            Text("\(monster.name) is now \(SnacklingRules.stageName(keeper.stage(for: monster))). \(perkBlurb)")
        }
    }

    private var perkBlurb: String {
        let perks = keeper.perks(unlocked: unlocked)
        var parts: [String] = []
        if perks.bonusMoves > 0 { parts.append("+\(perks.bonusMoves) starting moves") }
        if perks.bonusMaxLives > 0 { parts.append("+\(perks.bonusMaxLives) max lives") }
        return parts.isEmpty ? "Keep feeding to earn bonuses." : "Your collection grants " + parts.joined(separator: " and ") + "."
    }

    private func feed(_ monster: MonsterDef) {
        SoundManager.shared.playUITap()
        if keeper.feed(monster) != nil {
            justEvolved = monster
            SoundManager.shared.play(.match)
        }
    }

    private var pantryCard: some View {
        SSAGlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Pantry")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                if keeper.totalSnacks == 0 {
                    Text("Clear any level to earn snacks — finished levels still pay out.")
                        .font(.caption)
                        .foregroundStyle(SSATheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                        ForEach(SnackType.allCases, id: \.self) { snack in
                            HStack(spacing: 5) {
                                Text(snack.emoji)
                                Text("\(keeper.count(of: snack))")
                                    .font(.system(size: 14, weight: .black, design: .rounded).monospacedDigit())
                                    .foregroundStyle(keeper.count(of: snack) > 0 ? .white : SSATheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var perksCard: some View {
        let perks = keeper.perks(unlocked: unlocked)
        return SSAGlassCard(padding: 16) {
            HStack(spacing: 14) {
                Text("✨")
                    .font(.system(size: 30))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Collection Bonus")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(perks == .none
                         ? "Evolve Snacklings to Grown for bonus moves."
                         : "+\(perks.bonusMoves) moves · +\(perks.bonusMaxLives) max lives")
                        .font(.caption.bold())
                        .foregroundStyle(perks == .none ? SSATheme.textSecondary : SSATheme.candyYellow)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct SnacklingCard: View {
    let monster: MonsterDef
    let isUnlocked: Bool
    let feeds: Int
    let pantry: Int
    let onFeed: () -> Void

    private var stage: Int { SnacklingRules.stage(forFeeds: feeds) }
    private var isMaxed: Bool { stage >= SnacklingRules.maxStage }
    private var progress: (fed: Int, needed: Int) { SnacklingRules.stageProgress(forFeeds: feeds) }

    var body: some View {
        SSAGlassCard(padding: 14, cornerRadius: 18) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? SSATheme.candyPink.opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 62, height: 62)
                    Text(isUnlocked ? monster.emoji : "🔒")
                        .font(.system(size: isUnlocked ? 32 : 24))
                }

                VStack(spacing: 2) {
                    Text(isUnlocked ? monster.name : "Level \(monster.unlockLevel)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isUnlocked ? .white : SSATheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(isUnlocked
                         ? "\(SnacklingRules.stageName(stage)) · \(monster.favouriteSnack.emoji)"
                         : "Locked")
                        .font(.caption2.bold())
                        .foregroundStyle(isUnlocked ? SSATheme.candyYellow : SSATheme.textMuted)
                        .lineLimit(1)
                }

                if isUnlocked {
                    if isMaxed {
                        Text("MAX")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(SSATheme.candyYellow))
                    } else {
                        VStack(spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.12))
                                    Capsule()
                                        .fill(SSATheme.primaryGradient)
                                        .frame(
                                            width: max(
                                                4,
                                                geo.size.width * CGFloat(progress.fed) / CGFloat(max(1, progress.needed))
                                            )
                                        )
                                }
                            }
                            .frame(height: 7)

                            Text("\(progress.fed)/\(progress.needed)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(SSATheme.textSecondary)

                            Button(action: onFeed) {
                                Text(pantry > 0 ? "Feed \(monster.favouriteSnack.emoji)" : "Need \(monster.favouriteSnack.emoji)")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(pantry > 0 ? AnyShapeStyle(SSATheme.primaryGradient) : AnyShapeStyle(Color.white.opacity(0.1)))
                                    )
                                    .foregroundStyle(pantry > 0 ? .white : SSATheme.textMuted)
                            }
                            .disabled(pantry == 0)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
