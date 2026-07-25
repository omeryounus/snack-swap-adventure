import SwiftUI

/// Screen 02: World Map — Cookie Kingdom (1-10), Popcorn Plains (11-20), Candy Canyon (21-30), golden level path, L1-L30 level nodes, and bottom Level Preview sheet.
struct WorldMapView: View {
    let maxUnlockedLevel: Int
    let onSelectLevel: (Int) -> Void
    let onBack: () -> Void

    @State private var selectedLevelForPreview: Int? = nil

    private let totalLevels = LevelConfig.totalLevels

    var body: some View {
        ZStack(alignment: .top) {
            WorldBackgroundPlate(themeColor: SSATheme.candyCyan)

            VStack(spacing: 0) {
                // Map Header Bar
                HStack {
                    Button {
                        SoundManager.shared.playUITap()
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("WORLD MAP")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(maxUnlockedLevel)/\(totalLevels) Levels Unlocked")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(SSATheme.candyYellow)
                    }

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // World 1 Header Banner: Cookie Kingdom (Levels 1 - 10)
                        WorldSectionHeader(
                            title: "Cookie Kingdom",
                            emoji: "🍪",
                            levelsRange: "Levels 1 - 10",
                            color: SSATheme.candyOrange
                        )

                        VStack(spacing: 16) {
                            ForEach(1...10, id: \.self) { lvl in
                                LevelNodeRow(
                                    level: lvl,
                                    isUnlocked: lvl <= maxUnlockedLevel,
                                    isCurrent: lvl == maxUnlockedLevel,
                                    onTap: {
                                        SoundManager.shared.playUITap()
                                        selectedLevelForPreview = lvl
                                    }
                                )
                            }
                        }

                        // World 2 Header Banner: Popcorn Plains (Levels 11 - 20)
                        WorldSectionHeader(
                            title: "Popcorn Plains",
                            emoji: "🍿",
                            levelsRange: "Levels 11 - 20",
                            color: SSATheme.candyYellow
                        )

                        VStack(spacing: 16) {
                            ForEach(11...20, id: \.self) { lvl in
                                LevelNodeRow(
                                    level: lvl,
                                    isUnlocked: lvl <= maxUnlockedLevel,
                                    isCurrent: lvl == maxUnlockedLevel,
                                    onTap: {
                                        SoundManager.shared.playUITap()
                                        selectedLevelForPreview = lvl
                                    }
                                )
                            }
                        }

                        // World 3 Header Banner: Candy Canyon (Levels 21 - 30)
                        WorldSectionHeader(
                            title: "Candy Canyon",
                            emoji: "🍭",
                            levelsRange: "Levels 21 - 30",
                            color: SSATheme.candyPink
                        )

                        VStack(spacing: 16) {
                            ForEach(21...30, id: \.self) { lvl in
                                LevelNodeRow(
                                    level: lvl,
                                    isUnlocked: lvl <= maxUnlockedLevel,
                                    isCurrent: lvl == maxUnlockedLevel,
                                    onTap: {
                                        SoundManager.shared.playUITap()
                                        selectedLevelForPreview = lvl
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }

            // Bottom Level Preview Sheet Modal
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
    let onTap: () -> Void

    var body: some View {
        HStack {
            if level % 2 == 0 { Spacer() }

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
                        Text("CURRENT LEVEL")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(SSATheme.candyPink))
                            .shadow(radius: 4)
                    }
                }
            }

            if level % 2 != 0 { Spacer() }
        }
    }
}
