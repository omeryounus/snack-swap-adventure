import SwiftUI

/// Screen 02: World Map — a winding candy trail through all 30 levels.
///
/// The trail, the node colours and the world banners are all derived from
/// `LevelTheme`, so the map shifts palette as the player climbs instead of
/// repeating three hardcoded bands. Stars shown are the ones actually earned.
struct WorldMapView: View {
    let maxUnlockedLevel: Int
    let onSelectLevel: (Int) -> Void
    let onBack: () -> Void

    @Environment(\.adaptiveLayout) private var layout
    @StateObject private var profile = PlayerProfile.shared
    @State private var selectedLevelForPreview: Int? = nil

    private let totalLevels = LevelConfig.totalLevels

    /// Vertical distance between level nodes. Tuned so roughly seven levels of
    /// trail are on screen at once — enough to read the route ahead.
    private var spacing: CGFloat { layout.isPad ? 104 : 88 }
    private var nodeSize: CGFloat { layout.isPad ? 66 : 54 }
    private var topInset: CGFloat { 76 }

    var body: some View {
        ZStack(alignment: .top) {
            ScreenScaffold(
                title: "WORLD MAP",
                subtitle: "\(profile.totalEarnedStars)★ · \(maxUnlockedLevel)/\(totalLevels) unlocked",
                accent: SSATheme.candyYellow,
                themeColor: SSATheme.candyCyan,
                onBack: onBack
            ) {
                GeometryReader { geo in
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            trail(width: geo.size.width)
                                .frame(height: canvasHeight)
                        }
                        .onAppear {
                            // Drop the player where they actually are.
                            proxy.scrollTo(scrollAnchor, anchor: .center)
                        }
                    }
                }
                // ScreenScaffold hosts its own ScrollView; give this one a real
                // height to work inside rather than collapsing to zero.
                .frame(height: layout.height * 0.72)
            }

            if let levelNum = selectedLevelForPreview {
                LevelPreviewSheet(
                    levelNumber: levelNum,
                    maxStars: 3,
                    onPlay: {
                        selectedLevelForPreview = nil
                        onSelectLevel(levelNum)
                    },
                    onClose: { selectedLevelForPreview = nil }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var scrollAnchor: Int {
        min(max(1, maxUnlockedLevel), totalLevels)
    }

    private var canvasHeight: CGFloat {
        topInset + CGFloat(totalLevels - 1) * spacing + topInset
    }

    // MARK: - Trail

    private func trail(width: CGFloat) -> some View {
        let points = nodePoints(width: width)
        return ZStack(alignment: .topLeading) {
            // Muted full trail, then the travelled portion painted over it.
            trailPath(points)
                .stroke(
                    Color.white.opacity(0.10),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)
                )

            trailPath(Array(points.prefix(max(1, min(points.count, maxUnlockedLevel)))))
                .stroke(
                    LinearGradient(
                        colors: [SSATheme.candyPink, SSATheme.candyOrange, SSATheme.candyYellow],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                )

            ForEach(worldBanners(width: width), id: \.level) { banner in
                WorldBanner(title: banner.title, level: banner.level, tint: banner.tint)
                    .position(x: width / 2, y: banner.y)
            }

            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                let level = index + 1
                LevelNode(
                    level: level,
                    stars: profile.stars(forLevel: level),
                    isUnlocked: level <= maxUnlockedLevel,
                    isCurrent: level == maxUnlockedLevel,
                    size: nodeSize
                ) {
                    SoundManager.shared.playUITap()
                    selectedLevelForPreview = level
                }
                .id(level)
                .position(x: point.x, y: point.y)
            }
        }
        .frame(width: width)
    }

    /// Serpentine layout: a sine wave keeps the walk readable without the
    /// hard left/right alternation the old list used.
    private func nodePoints(width: CGFloat) -> [CGPoint] {
        let amplitude = min(width * 0.28, layout.isPad ? 160 : 110)
        return (0..<totalLevels).map { index in
            let i = CGFloat(index)
            return CGPoint(
                x: width / 2 + amplitude * sin(i * 0.72),
                y: topInset + i * spacing
            )
        }
    }

    private func trailPath(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for (from, to) in zip(points, points.dropFirst()) {
                let midY = (from.y + to.y) / 2
                path.addCurve(
                    to: to,
                    control1: CGPoint(x: from.x, y: midY),
                    control2: CGPoint(x: to.x, y: midY)
                )
            }
        }
    }

    private struct Banner {
        let level: Int
        let title: String
        let tint: Color
        let y: CGFloat
    }

    /// A banner at the head of each ten-level world, named from the theme the
    /// player is about to enter rather than a hardcoded list.
    private func worldBanners(width: CGFloat) -> [Banner] {
        stride(from: 1, through: totalLevels, by: 10).map { level in
            let theme = LevelTheme.forLevel(level)
            return Banner(
                level: level,
                title: theme.name,
                tint: theme.bgColors.dropFirst().first ?? SSATheme.candyPink,
                y: topInset + CGFloat(level - 1) * spacing - spacing * 0.55
            )
        }
    }
}

private struct WorldBanner: View {
    let title: String
    let level: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(tint)
                .frame(width: 22, height: 3)
                .clipShape(Capsule())
            Text(title.uppercased())
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Rectangle()
                .fill(tint)
                .frame(width: 22, height: 3)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.black.opacity(0.45)))
        .overlay(Capsule().stroke(tint.opacity(0.55), lineWidth: 1))
    }
}

private struct LevelNode: View {
    let level: Int
    let stars: Int
    let isUnlocked: Bool
    let isCurrent: Bool
    let size: CGFloat
    let onTap: () -> Void

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var theme: LevelTheme { LevelTheme.forLevel(level) }

    var body: some View {
        Button(action: { if isUnlocked { onTap() } }) {
            VStack(spacing: 5) {
                ZStack {
                    if isCurrent {
                        Circle()
                            .stroke(SSATheme.candyYellow.opacity(0.7), lineWidth: 3)
                            .frame(width: size + 16, height: size + 16)
                            .scaleEffect(pulse ? 1.12 : 0.96)
                            .opacity(pulse ? 0.15 : 0.75)
                    }

                    Circle()
                        .fill(
                            isUnlocked
                            ? AnyShapeStyle(LinearGradient(
                                colors: theme.bgColors.count >= 2
                                    ? [theme.bgColors[1], theme.bgColors[0]]
                                    : [SSATheme.candyPink, SSATheme.candyOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.white.opacity(0.07))
                        )
                        .frame(width: size, height: size)
                        .overlay(
                            Circle().stroke(
                                isCurrent ? SSATheme.candyYellow
                                    : (isUnlocked ? .white.opacity(0.45) : .white.opacity(0.12)),
                                lineWidth: isCurrent ? 3 : 1.5
                            )
                        )
                        .shadow(color: isUnlocked ? .black.opacity(0.45) : .clear, radius: 8, y: 4)

                    if isUnlocked {
                        Text("\(level)")
                            .font(.system(size: size * 0.36, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: size * 0.28, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }

                // Real ratings — an uncleared level shows empty stars, not gold.
                if isUnlocked {
                    HStack(spacing: 3) {
                        ForEach(1...3, id: \.self) { index in
                            Image(systemName: index <= stars ? "star.fill" : "star")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(
                                    index <= stars ? SSATheme.candyYellow : .white.opacity(0.22)
                                )
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .onAppear {
            guard isCurrent, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityLabel(
            isUnlocked
            ? "Level \(level), \(theme.name), \(stars) of 3 stars"
            : "Level \(level), locked"
        )
    }
}
