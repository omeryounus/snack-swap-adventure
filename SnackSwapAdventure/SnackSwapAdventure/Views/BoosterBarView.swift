import SwiftUI

enum ActiveBooster: String, CaseIterable {
    case hammer = "Hammer"
    case colorBomb = "Bomb"
    case extraMoves = "+5"

    var iconName: String {
        switch self {
        case .hammer: return "hammer.fill"
        case .colorBomb: return "sparkles"
        case .extraMoves: return "plus.circle.fill"
        }
    }

    /// How much the drawing has to grow to fill its artboard. The exported
    /// PDFs carry the margin each drawing had on its 128pt board, so without
    /// this the icons render around two-thirds size.
    var artworkScale: CGFloat {
        switch self {
        case .hammer: return 1.52
        case .colorBomb: return 1.07
        case .extraMoves: return 1.18
        }
    }

    /// Vector artwork drawn in Figma. Falls back to `iconName` if an asset is
    /// ever missing, so the dock never renders an empty cell.
    var artworkName: String {
        switch self {
        case .hammer: return "Booster_hammer"
        case .colorBomb: return "Booster_bomb"
        case .extraMoves: return "Booster_extramoves"
        }
    }

    var cost: Int {
        switch self {
        case .hammer: return 30
        case .colorBomb: return 50
        case .extraMoves: return 40
        }
    }

    var displayName: String {
        switch self {
        case .hammer: return "Snack Hammer"
        case .colorBomb: return "Color Bomb"
        case .extraMoves: return "Extra Moves"
        }
    }

    /// Owned boosters are spent before stars, and stars are never conjured:
    /// the shop is the only way to top up. The booster bar used to grant 100
    /// free stars here, which made every booster free and the star bundles
    /// pointless.
    static func canAfford(stock: Int, stars: Int, cost: Int) -> Bool {
        stock > 0 || stars >= cost
    }
}

/// Equal-width booster dock. Badges stay inside each cell so they never overlap.
struct BoosterBarView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var profile = PlayerProfile.shared
    @Binding var activeBooster: ActiveBooster?
    var axis: Axis = .horizontal
    var compact: Bool = false
    let onHammerUse: () -> Void
    let onColorBombUse: () -> Void
    let onExtraMovesUse: () -> Void

    @Environment(\.adaptiveLayout) private var layout

    /// Set when a booster is tapped that the player cannot pay for.
    @State private var insufficientFor: ActiveBooster?
    @State private var showShop = false

    var body: some View {
        Group {
            if axis == .vertical {
                VStack(spacing: 8) {
                    boosterCell(
                        booster: .hammer,
                        count: profile.hammerCount,
                        isSelected: activeBooster == .hammer,
                        action: hammerAction
                    )
                    boosterCell(
                        booster: .colorBomb,
                        count: profile.colorBombCount,
                        isSelected: activeBooster == .colorBomb,
                        action: colorBombAction
                    )
                    boosterCell(
                        booster: .extraMoves,
                        count: profile.extraMovesCount,
                        isSelected: false,
                        action: extraMovesAction
                    )
                }
            } else {
                HStack(spacing: 8) {
                    boosterCell(
                        booster: .hammer,
                        count: profile.hammerCount,
                        isSelected: activeBooster == .hammer,
                        action: hammerAction
                    )
                    boosterCell(
                        booster: .colorBomb,
                        count: profile.colorBombCount,
                        isSelected: activeBooster == .colorBomb,
                        action: colorBombAction
                    )
                    boosterCell(
                        booster: .extraMoves,
                        count: profile.extraMovesCount,
                        isSelected: false,
                        action: extraMovesAction
                    )
                }
            }
        }
        .padding(compact ? 6 : 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .alert(
            "Not Enough Stars",
            isPresented: Binding(
                get: { insufficientFor != nil },
                set: { if !$0 { insufficientFor = nil } }
            ),
            presenting: insufficientFor
        ) { booster in
            Button("Get Stars") {
                insufficientFor = nil
                showShop = true
            }
            Button("Cancel", role: .cancel) { insufficientFor = nil }
        } message: { booster in
            Text("\(booster.displayName) costs \(booster.cost) ⭐ and you have \(profile.stars) ⭐.")
        }
        .sheet(isPresented: $showShop) {
            ShopView(onBack: { showShop = false })
        }
    }

    /// The drawn icon, or the SF Symbol if the asset is missing.
    @ViewBuilder
    private func boosterArtwork(_ booster: ActiveBooster) -> some View {
        if UIImage(named: booster.artworkName) != nil {
            Image(booster.artworkName)
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .scaleEffect(booster.artworkScale)
        } else {
            Image(systemName: booster.iconName)
                .font(.system(size: compact ? 15 : (layout.isPad ? 18 : 17), weight: .bold))
                .foregroundStyle(SSATheme.candyYellow)
        }
    }

    private func boosterCell(
        booster: ActiveBooster,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                boosterArtwork(booster)
                    .frame(width: compact ? 36 : 40, height: compact ? 36 : 40)
                    .clipped()

                Text(booster.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? SSATheme.candyYellow : .white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 5 : 7)
            .overlay(alignment: .topTrailing) {
                    Text(count > 0 ? "\(count)" : "\(booster.cost)★")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(count > 0 ? .white : Color(hex: "3A2205"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(count > 0
                                           ? AnyShapeStyle(SSATheme.candyGreen)
                                           : AnyShapeStyle(SSAOrnate.gold))
                        )
                        .overlay(Capsule().stroke(Color.black.opacity(0.35), lineWidth: 1))
                        .padding(.top, 2)
                        .padding(.trailing, 4)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected
                          ? AnyShapeStyle(SSATheme.candyPink.opacity(0.9))
                          : AnyShapeStyle(SSAOrnate.plaqueFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(SSAOrnate.gold, lineWidth: 2.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    .padding(2.5)
            )
            .shadow(color: .black.opacity(0.45), radius: 5, y: 3)
            // Unaffordable boosters stay tappable so the tap can explain why
            // and offer the shop, but they read as unavailable.
            .opacity(canAfford(booster) || isSelected ? 1 : 0.45)
        }
        .buttonStyle(.plain)
    }

    private func stock(for booster: ActiveBooster) -> Int {
        switch booster {
        case .hammer: return profile.hammerCount
        case .colorBomb: return profile.colorBombCount
        case .extraMoves: return profile.extraMovesCount
        }
    }

    private func canAfford(_ booster: ActiveBooster) -> Bool {
        ActiveBooster.canAfford(
            stock: stock(for: booster),
            stars: profile.stars,
            cost: booster.cost
        )
    }

    private func hammerAction() {
        if activeBooster == .hammer {
            activeBooster = nil
            return
        }
        guard canAfford(.hammer) else {
            insufficientFor = .hammer
            return
        }
        // Charged on the tile tap in GameScene.smashTile, since the player can
        // still cancel hammer mode without using it.
        activeBooster = .hammer
        onHammerUse()
        Task { @MainActor in SoundManager.shared.playSelect() }
    }

    private func colorBombAction() {
        guard canAfford(.colorBomb) else {
            insufficientFor = .colorBomb
            return
        }
        if profile.colorBombCount > 0 {
            profile.colorBombCount -= 1
        } else {
            profile.deductStars(ActiveBooster.colorBomb.cost)
        }
        onColorBombUse()
    }

    private func extraMovesAction() {
        guard canAfford(.extraMoves) else {
            insufficientFor = .extraMoves
            return
        }
        if profile.extraMovesCount > 0 {
            profile.extraMovesCount -= 1
        } else {
            profile.deductStars(ActiveBooster.extraMoves.cost)
        }
        gameState.addMoves(5)
        onExtraMovesUse()
    }
}
