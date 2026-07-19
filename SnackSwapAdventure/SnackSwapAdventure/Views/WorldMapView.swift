import SwiftUI

struct WorldMapView: View {
    let maxUnlockedLevel: Int
    let onSelectLevel: (Int) -> Void
    let onBack: () -> Void

    private let worlds: [(name: String, emoji: String, levels: ClosedRange<Int>)] = [
        ("Cookie Kingdom", "🍪", 1...10),
        ("Popcorn Plains", "🍿", 11...20),
        ("Candy Canyon", "🍬", 21...30)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.28),
                    Color(red: 0.25, green: 0.12, blue: 0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("World Map")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 60)
                }
                .padding()

                ScrollView {
                    VStack(spacing: 28) {
                        ForEach(Array(worlds.enumerated()), id: \.offset) { _, world in
                            worldSection(world)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func worldSection(_ world: (name: String, emoji: String, levels: ClosedRange<Int>)) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(world.emoji)  \(world.name)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.4))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(Array(world.levels), id: \.self) { level in
                    levelButton(level)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func levelButton(_ level: Int) -> some View {
        let unlocked = level <= maxUnlockedLevel
        return Button {
            guard unlocked else { return }
            SoundManager.shared.playUITap()
            onSelectLevel(level)
        } label: {
            VStack(spacing: 4) {
                Text("\(level)")
                    .font(.headline.bold())
                Text(unlocked ? "★" : "🔒")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                unlocked
                    ? LinearGradient(colors: [.pink.opacity(0.8), .orange.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
            )
            .foregroundStyle(unlocked ? .white : .white.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!unlocked)
    }
}

#Preview {
    WorldMapView(maxUnlockedLevel: 5, onSelectLevel: { _ in }, onBack: {})
}
