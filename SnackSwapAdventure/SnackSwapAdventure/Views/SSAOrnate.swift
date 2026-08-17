import SwiftUI

/// Ornate chrome: gilded frames, gem accents and bevelled plaques.
///
/// Everything here is drawn rather than illustrated, so it scales to any size
/// and costs nothing in the asset catalog. Painted props — jewelled booster
/// icons, filigree scrollwork — still need real art.
enum SSAOrnate {

    // MARK: - Metals

    /// Warm gold with the highlight/shadow banding that reads as bevelled metal.
    static let gold = LinearGradient(
        colors: [
            Color(hex: "FFE9A8"),
            Color(hex: "F5C24A"),
            Color(hex: "C8891F"),
            Color(hex: "F3CE6A")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let goldRim = LinearGradient(
        colors: [Color(hex: "FFF3C4"), Color(hex: "B8791A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Deep interior for panels, so gilding has something to sit against.
    static let panelFill = LinearGradient(
        colors: [Color(hex: "3B1D63").opacity(0.96), Color(hex: "1E0E38").opacity(0.98)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let plaqueFill = LinearGradient(
        colors: [Color(hex: "5A2E86"), Color(hex: "331A55")],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// A four-sided gem, used to pin frame corners and break up long edges.
struct SSAGem: View {
    var size: CGFloat = 12
    var tint: Color = SSATheme.candyPink

    var body: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [.white, tint, tint.opacity(0.65)],
                    center: .init(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: size
                )
            )
            .rotationEffect(.degrees(45))
            .frame(width: size, height: size)
            .overlay(
                Rectangle()
                    .stroke(SSAOrnate.goldRim, lineWidth: 1.5)
                    .rotationEffect(.degrees(45))
                    .frame(width: size, height: size)
            )
            .shadow(color: tint.opacity(0.7), radius: size * 0.35)
    }
}

/// A gilded panel: dark interior, bevelled gold border, optional corner gems.
struct SSAOrnatePanel<Content: View>: View {
    var cornerRadius: CGFloat = 18
    var borderWidth: CGFloat = 3
    var gemTint: Color = SSATheme.candyPink
    var showsGems: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SSAOrnate.panelFill)
            )
            .overlay(
                // Outer gilding plus a thin inner highlight — two strokes read
                // as a bevel where one reads as a flat outline.
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(SSAOrnate.gold, lineWidth: borderWidth)
                    RoundedRectangle(cornerRadius: cornerRadius - borderWidth, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        .padding(borderWidth)
                }
            )
            .overlay(alignment: .topLeading) { gem(showsGems) }
            .overlay(alignment: .topTrailing) { gem(showsGems) }
            .overlay(alignment: .bottomLeading) { gem(showsGems) }
            .overlay(alignment: .bottomTrailing) { gem(showsGems) }
            .shadow(color: .black.opacity(0.55), radius: 10, y: 5)
    }

    @ViewBuilder
    private func gem(_ visible: Bool) -> some View {
        if visible {
            SSAGem(size: 11, tint: gemTint)
                .offset(x: 0, y: 0)
                .padding(4)
        }
    }
}

/// The banner that names the level, shaped like a hanging sign.
struct SSAOrnateBanner: View {
    let title: String
    var tint: Color = SSATheme.candyPink

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "FFF6D5"), Color(hex: "FFD98A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.6), radius: 1, y: 1)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(SSAOrnate.plaqueFill)
            )
            .overlay(Capsule().stroke(SSAOrnate.gold, lineWidth: 2.5))
            .overlay(alignment: .leading) { SSAGem(size: 10, tint: tint).offset(x: -3) }
            .overlay(alignment: .trailing) { SSAGem(size: 10, tint: tint).offset(x: 3) }
            .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
    }
}

/// A small gilded stat tile — TIME, MOVES and friends.
struct SSAOrnateStat: View {
    let title: String
    let value: String
    var accent: Color = SSATheme.candyYellow
    var minWidth: CGFloat = 68

    var body: some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "E7D6FF").opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.55), radius: 5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(minWidth: minWidth)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(SSAOrnate.plaqueFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(SSAOrnate.goldRim, lineWidth: 2)
        )
    }
}

/// Gilded progress track with a gem sliding along it.
struct SSAOrnateProgressBar: View {
    let progress: Double
    var height: CGFloat = 20
    var tint: Color = SSATheme.candyPink

    var body: some View {
        GeometryReader { geo in
            let clamped = max(0, min(1, progress))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.45))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [SSATheme.candyPink, SSATheme.candyOrange, SSATheme.candyYellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geo.size.width * clamped))
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .frame(height: height * 0.28)
                            .padding(.horizontal, 4)
                            .offset(y: -height * 0.22),
                        alignment: .top
                    )
                    .clipShape(Capsule())
            }
            .overlay(Capsule().stroke(SSAOrnate.gold, lineWidth: 2))
        }
        .frame(height: height)
    }
}
