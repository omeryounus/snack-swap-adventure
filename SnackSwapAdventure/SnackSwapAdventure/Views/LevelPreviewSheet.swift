import SwiftUI

/// Pre-level Preview Sheet for Screen 02 (World Map level selection).
/// Displays level goals, star rating, pre-selected boosters, and Play CTA.
struct LevelPreviewSheet: View {
    let levelNumber: Int
    let maxStars: Int
    let onPlay: () -> Void
    let onClose: () -> Void

    @StateObject private var meta = MetaProgress.shared
    @State private var selectedBoosters: Set<String> = []

    var config: LevelConfig {
        LevelConfig.level(levelNumber)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 20) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(config.worldEmoji) \(config.worldName)")
                            .font(.caption.bold())
                            .foregroundStyle(SSATheme.candyYellow)

                        Text("Level \(levelNumber)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button {
                        SoundManager.shared.playUITap()
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }

                // Stars Earned Preview
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                i <= maxStars
                                ? SSATheme.goldGradient
                                : LinearGradient(colors: [.white.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: i <= maxStars ? SSATheme.candyYellow.opacity(0.5) : .clear, radius: 8)
                    }
                }

                // Level Goal Preview Card
                SSAGlassCard(padding: 16) {
                    HStack(spacing: 14) {
                        Image(systemName: "target")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(SSATheme.candyPink)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Level Target")
                                .font(.caption.bold())
                                .foregroundStyle(SSATheme.textSecondary)

                            Text(config.goal.shortTitle)
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Moves")
                                .font(.caption.bold())
                                .foregroundStyle(SSATheme.textSecondary)

                            Text("\(config.moves)")
                                .font(.title2.bold())
                                .foregroundStyle(SSATheme.candyCyan)
                        }
                    }
                }

                // Pre-level Boosters Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Equip Boosters")
                        .font(.caption.bold())
                        .foregroundStyle(SSATheme.textSecondary)

                    HStack(spacing: 12) {
                        BoosterChip(
                            title: "+5 Moves",
                            icon: "hand.tap.fill",
                            id: "moves",
                            isSelected: selectedBoosters.contains("moves"),
                            onToggle: toggleBooster
                        )

                        BoosterChip(
                            title: "+30s Time",
                            icon: "clock.fill",
                            id: "time",
                            isSelected: selectedBoosters.contains("time"),
                            onToggle: toggleBooster
                        )

                        BoosterChip(
                            title: "Hammer",
                            icon: "hammer.fill",
                            id: "hammer",
                            isSelected: selectedBoosters.contains("hammer"),
                            onToggle: toggleBooster
                        )
                    }
                }

                // Start Level Primary Button
                SSAPrimaryButton(
                    title: "PLAY LEVEL \(levelNumber)",
                    icon: "play.fill",
                    gradient: SSATheme.primaryGradient
                ) {
                    // Queue selected boosters
                    for b in selectedBoosters {
                        meta.queueBooster(b)
                    }
                    onPlay()
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(SSATheme.bgElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        }
    }

    private func toggleBooster(_ id: String) {
        if selectedBoosters.contains(id) {
            selectedBoosters.remove(id)
        } else {
            selectedBoosters.insert(id)
        }
    }
}

private struct BoosterChip: View {
    let title: String
    let icon: String
    let id: String
    let isSelected: Bool
    let onToggle: (String) -> Void

    var body: some View {
        Button {
            SoundManager.shared.playUITap()
            onToggle(id)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? .white : SSATheme.textSecondary)

                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(isSelected ? .white : SSATheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? SSATheme.candyPink.opacity(0.8) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? SSATheme.candyPink : Color.white.opacity(0.15), lineWidth: 1.5)
            )
        }
    }
}
