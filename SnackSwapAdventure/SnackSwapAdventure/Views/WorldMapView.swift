import SwiftUI

struct WorldMapView: View {
    let maxUnlockedLevel: Int
    let onSelectLevel: (Int) -> Void
    let onBack: () -> Void

    private let cream = Color(red: 1.0, green: 0.96, blue: 0.90)
    private let creamMuted = Color(red: 1.0, green: 0.90, blue: 0.82).opacity(0.72)
    private let cocoa = Color(red: 0.17, green: 0.09, blue: 0.12)
    private let panel = Color(red: 0.22, green: 0.13, blue: 0.18)
    private let pink = Color(red: 1.0, green: 0.34, blue: 0.55)
    private let orange = Color(red: 1.0, green: 0.58, blue: 0.22)
    private let gold = Color(red: 1.0, green: 0.82, blue: 0.28)

    private let worlds: [WorldMapSection] = [
        WorldMapSection(
            name: "Cookie Kingdom",
            emoji: "🍪",
            levels: 1...10,
            colors: [
                Color(red: 0.44, green: 0.22, blue: 0.24),
                Color(red: 0.30, green: 0.14, blue: 0.18)
            ]
        ),
        WorldMapSection(
            name: "Popcorn Plains",
            emoji: "🍿",
            levels: 11...20,
            colors: [
                Color(red: 0.42, green: 0.32, blue: 0.15),
                Color(red: 0.24, green: 0.18, blue: 0.14)
            ]
        ),
        WorldMapSection(
            name: "Candy Canyon",
            emoji: "🍬",
            levels: 21...30,
            colors: [
                Color(red: 0.38, green: 0.18, blue: 0.42),
                Color(red: 0.18, green: 0.12, blue: 0.30)
            ]
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.08, blue: 0.12),
                    Color(red: 0.10, green: 0.06, blue: 0.13),
                    Color(red: 0.19, green: 0.09, blue: 0.17)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 18) {
                        progressPanel

                        ForEach(worlds) { world in
                            worldSection(world)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                SoundManager.shared.playUITap()
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .heavy))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(panel.opacity(0.95))
                            .overlay(Circle().stroke(cream.opacity(0.14), lineWidth: 1))
                    )
                    .foregroundStyle(cream)
            }
            .buttonStyle(MapPressButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text("World Map")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(cream)
                Text("Choose your next snack stop")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(creamMuted)
            }

            Spacer()

            Text("\(min(maxUnlockedLevel, LevelConfig.totalLevels))/\(LevelConfig.totalLevels)")
                .font(.caption.monospacedDigit().weight(.heavy))
                .foregroundStyle(gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.22))
                        .overlay(Capsule().stroke(gold.opacity(0.24), lineWidth: 1))
                )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.17, green: 0.08, blue: 0.12).opacity(0.98),
                    Color(red: 0.17, green: 0.08, blue: 0.12).opacity(0.72),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var progressPanel: some View {
        let capped = min(maxUnlockedLevel, LevelConfig.totalLevels)
        let progress = Double(capped) / Double(LevelConfig.totalLevels)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Level")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(creamMuted)
                    Text("Level \(capped)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(cream)
                }

                Spacer()

                Button {
                    SoundManager.shared.playUITap()
                    onSelectLevel(capped)
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .font(.headline.weight(.heavy))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [pink, orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: pink.opacity(0.35), radius: 10, y: 4)
                }
                .buttonStyle(MapPressButtonStyle())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [pink, orange, gold], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(18, geo.size.width * progress))
                }
            }
            .frame(height: 10)

            HStack {
                Label("\(unlockedWorldName(for: capped))", systemImage: "map.fill")
                Spacer()
                Text("\(Int(progress * 100))% complete")
                    .monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(creamMuted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(panel.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(cream.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func worldSection(_ world: WorldMapSection) -> some View {
        let worldUnlocked = world.levels.lowerBound <= maxUnlockedLevel
        let completed = min(max(maxUnlockedLevel - world.levels.lowerBound + 1, 0), world.levels.count)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(world.emoji)
                    .font(.system(size: 34))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white.opacity(0.10)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(world.name)
                        .font(.title3.weight(.black))
                        .foregroundStyle(cream)
                    Text(worldUnlocked ? "\(completed) of \(world.levels.count) stops open" : "Unlock at Level \(world.levels.lowerBound)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(worldUnlocked ? creamMuted : cream.opacity(0.42))
                }

                Spacer()

                Image(systemName: worldUnlocked ? "sparkles" : "lock.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(worldUnlocked ? gold : cream.opacity(0.35))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(Array(world.levels), id: \.self) { level in
                    levelButton(level)
                }
            }
            .background {
                WorldPathOverlay(
                    levels: Array(world.levels),
                    maxUnlockedLevel: maxUnlockedLevel,
                    gold: gold,
                    cream: cream
                )
                .allowsHitTesting(false)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: world.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(worldUnlocked ? cream.opacity(0.16) : cream.opacity(0.08), lineWidth: 1)
                )
        )
        .opacity(worldUnlocked ? 1.0 : 0.62)
    }

    private func levelButton(_ level: Int) -> some View {
        let unlocked = level <= maxUnlockedLevel
        let current = level == min(maxUnlockedLevel, LevelConfig.totalLevels)

        return Button {
            guard unlocked else { return }
            SoundManager.shared.playUITap()
            onSelectLevel(level)
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(current ? gold.opacity(0.24) : Color.white.opacity(unlocked ? 0.10 : 0.03))
                        .frame(width: 30, height: 30)
                    Text("\(level)")
                        .font(.system(size: 15, weight: .black, design: .rounded).monospacedDigit())
                }
                Image(systemName: current ? "play.fill" : unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .font(.system(size: 9, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .foregroundStyle(unlocked ? .white : cream.opacity(0.35))
            .background(levelTileBackground(unlocked: unlocked, current: current))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(current ? gold.opacity(0.85) : cream.opacity(unlocked ? 0.18 : 0.07), lineWidth: current ? 2 : 1)
            )
            .shadow(color: current ? gold.opacity(0.32) : .clear, radius: 10, y: 3)
        }
        .buttonStyle(MapPressButtonStyle())
        .disabled(!unlocked)
        .accessibilityLabel(unlocked ? "Level \(level)" : "Level \(level), locked")
    }

    private func levelTileBackground(unlocked: Bool, current: Bool) -> some ShapeStyle {
        if current {
            return AnyShapeStyle(LinearGradient(colors: [pink, orange], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        if unlocked {
            return AnyShapeStyle(LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom))
        }
        return AnyShapeStyle(Color.black.opacity(0.18))
    }

    private func unlockedWorldName(for level: Int) -> String {
        worlds.first(where: { $0.levels.contains(level) })?.name ?? worlds[0].name
    }
}

private struct WorldMapSection: Identifiable {
    let name: String
    let emoji: String
    let levels: ClosedRange<Int>
    let colors: [Color]

    var id: String { name }
}

private struct WorldPathOverlay: View {
    let levels: [Int]
    let maxUnlockedLevel: Int
    let gold: Color
    let cream: Color

    var body: some View {
        GeometryReader { geo in
            let columns = 5
            let rows = max(1, Int(ceil(Double(levels.count) / Double(columns))))
            let cellW = geo.size.width / CGFloat(columns)
            let cellH = geo.size.height / CGFloat(rows)
            let points = levels.enumerated().map { index, level in
                let row = index / columns
                let colInRow = index % columns
                let serpentineCol = row.isMultiple(of: 2) ? colInRow : (columns - 1 - colInRow)
                return (
                    level: level,
                    point: CGPoint(
                        x: CGFloat(serpentineCol) * cellW + cellW / 2,
                        y: CGFloat(row) * cellH + cellH / 2
                    )
                )
            }

            ZStack {
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first.point)
                    for item in points.dropFirst() {
                        path.addLine(to: item.point)
                    }
                }
                .stroke(cream.opacity(0.12), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))

                Path { path in
                    let unlocked = points.filter { $0.level <= maxUnlockedLevel }
                    guard let first = unlocked.first else { return }
                    path.move(to: first.point)
                    for item in unlocked.dropFirst() {
                        path.addLine(to: item.point)
                    }
                }
                .stroke(
                    LinearGradient(colors: [.pink, .orange, gold], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: gold.opacity(0.28), radius: 8)
            }
            .padding(.horizontal, cellW * 0.36)
            .padding(.vertical, cellH * 0.34)
        }
    }
}

private struct MapPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    WorldMapView(maxUnlockedLevel: 6, onSelectLevel: { _ in }, onBack: {})
}
