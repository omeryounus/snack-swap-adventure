import SwiftUI

/// The image a player shares after clearing a level. Rendered off-screen with
/// ImageRenderer, so it is sized in points and never depends on the device.
struct WinShareCard: View {
    let level: Int
    let themeName: String
    let stars: Int
    let score: Int
    let playerName: String
    let snacks: [String]

    var body: some View {
        VStack(spacing: 18) {
            Text("SNACK SWAP")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "FFD34D"), Color(hex: "FF7A3D")],
                                   startPoint: .leading, endPoint: .trailing)
                )
            Text("ADVENTURE")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .tracking(6)
                .foregroundStyle(.white)
                .padding(.top, -14)

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(
                            index < stars
                                ? AnyShapeStyle(LinearGradient(colors: [.yellow, .orange],
                                                               startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.white.opacity(0.18))
                        )
                }
            }

            VStack(spacing: 4) {
                Text("Level \(level) cleared")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(themeName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text("\(score)")
                .font(.system(size: 46, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(Color(hex: "FFD34D"))
            Text("POINTS")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, -10)

            Text(snacks.prefix(5).joined(separator: " "))
                .font(.system(size: 26))

            Text("Can you beat \(playerName)?")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 2)
        }
        .padding(32)
        .frame(width: 380, height: 480)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "2B0F3A"), Color(hex: "5B1D4E"), Color(hex: "120616")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color(hex: "FF3D8A").opacity(0.28), .clear],
                    center: .top, startRadius: 10, endRadius: 320
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

enum WinShareCardRenderer {
    /// Returns a PNG-backed image ready for ShareLink, or nil if rendering fails.
    @MainActor
    static func render(
        level: Int,
        themeName: String,
        stars: Int,
        score: Int,
        playerName: String,
        snacks: [String]
    ) -> UIImage? {
        let card = WinShareCard(
            level: level,
            themeName: themeName,
            stars: stars,
            score: score,
            playerName: playerName,
            snacks: snacks
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }
}
