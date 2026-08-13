import SwiftUI

/// Screen 02: World Map — two-column on iPad / wide landscape, winding path on phones.
struct WorldMapView: View {
    let maxUnlockedLevel: Int
    let onSelectLevel: (Int) -> Void
    let onBack: () -> Void

    @Environment(\.adaptiveLayout) private var layout
    @State private var selectedLevelForPreview: Int? = nil

    private let totalLevels = LevelConfig.totalLevels

    var body: some View {
        ZStack(alignment: .top) {
            ScreenScaffold(
                title: "WORLD MAP",
                subtitle: "\(maxUnlockedLevel)/\(totalLevels) Levels Unlocked",
                accent: SSATheme.candyYellow,
                themeColor: SSATheme.candyCyan,
                onBack: onBack
            ) {
                VStack(spacing: layout.isCompactHeight ? 20 : 32) {
                    worldSection(
                        title: "Cookie Kingdom",
                        emoji: "🍪",
                        levelsRange: "Levels 1 - 10",
                        color: SSATheme.candyOrange,
                        levels: 1...10
                    )
                    worldSection(
                        title: "Popcorn Plains",
                        emoji: "🍿",
                        levelsRange: "Levels 11 - 20",
                        color: SSATheme.candyYellow,
                        levels: 11...20
                    )
                    worldSection(
                        title: "Candy Canyon",
                        emoji: "🍭",
                        levelsRange: "Levels 21 - 30",
                        color: SSATheme.candyPink,
                        levels: 21...30
                    )
                }
            }

            if let levelNum = selectedLevelForPreview {
                LevelPreviewSheet(
                    levelNumber: levelNum,
                    maxStars: 3,
                    onPlay: {
                        selectedLevelForPreview = nil
                        onSelectLevel(levelNum)
                    },
                    onClose: {
                        selectedLevelForPreview = nil
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func worldSection(
        title: String,
        emoji: String,
        levelsRange: String,
        color: Color,
        levels: ClosedRange<Int>
    ) -> some View {
        VStack(spacing: 16) {
            WorldSectionHeader(title: title, emoji: emoji, levelsRange: levelsRange, color: color)

            if layout.worldMapColumns > 1 {
                LazyVGrid(columns: layout.gridItems(count: layout.worldMapColumns, spacing: 16), spacing: 16) {
                    ForEach(Array(levels), id: \.self) { lvl in
                        LevelNodeRow(
                            level: lvl,
                            isUnlocked: lvl <= maxUnlockedLevel,
                            isCurrent: lvl == maxUnlockedLevel,
                            compact: true,
                            onTap: {
                                SoundManager.shared.playUITap()
                                selectedLevelForPreview = lvl
                            }
                        )
                    }
                }
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(levels), id: \.self) { lvl in
                        LevelNodeRow(
                            level: lvl,
                            isUnlocked: lvl <= maxUnlockedLevel,
                            isCurrent: lvl == maxUnlockedLevel,
                            compact: false,
                            onTap: {
                                SoundManager.shared.playUITap()
                                selectedLevelForPreview = lvl
                            }
                        )
                    }
                }
            }
        }
    }
}

private struct WorldSectionHeader: View {
    let title: String
    let emoji: String
    let levelsRange: String
    let color: Color

    var body: some View {
        SSAGlassCard(padding: 12, cornerRadius: 16) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(levelsRange)
                        .font(.caption.bold())
                        .foregroundStyle(SSATheme.textSecondary)
                }

                Spacer()
            }
        }
    }
}

private struct LevelNodeRow: View {
    let level: Int
    let isUnlocked: Bool
    let isCurrent: Bool
    var compact: Bool = false
    let onTap: () -> Void

    var body: some View {
        HStack {
            if !compact, level % 2 == 0 { Spacer() }

            Button {
                if isUnlocked { onTap() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isUnlocked ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
                            .overlay(
                                Circle()
                                    .fill(isCurrent ? SSATheme.primaryGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom))
                            )
                            .frame(width: 58, height: 58)
                            .shadow(color: isCurrent ? SSATheme.candyPink.opacity(0.5) : .clear, radius: 10)

                        Circle()
                            .stroke(
                                isCurrent ? Color.white : (isUnlocked ? SSATheme.candyYellow : Color.white.opacity(0.15)),
                                lineWidth: 2
                            )
                            .frame(width: 58, height: 58)

                        if isUnlocked {
                            VStack(spacing: 0) {
                                Text("L\(level)")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)

                                HStack(spacing: 2) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 8))
                                            .foregroundStyle(SSATheme.candyYellow)
                                    }
                                }
                            }
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(SSATheme.textMuted)
                        }
                    }

                    if isCurrent {
                        Text("CURRENT")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(SSATheme.candyPink))
                            .shadow(radius: 4)
                    }
                    if compact { Spacer(minLength: 0) }
                }
                .frame(maxWidth: compact ? .infinity : nil, alignment: .leading)
            }

            if !compact, level % 2 != 0 { Spacer() }
        }
    }
}
