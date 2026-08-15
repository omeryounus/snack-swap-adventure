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

    var cost: Int {
        switch self {
        case .hammer: return 30
        case .colorBomb: return 50
        case .extraMoves: return 40
        }
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
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func boosterCell(
        booster: ActiveBooster,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: booster.iconName)
                        .font(.system(size: compact ? 15 : (layout.isPad ? 18 : 17), weight: .bold))
                        .foregroundStyle(isSelected ? .white : SSATheme.candyYellow)
                        .frame(width: 32, height: 32)

                    Text(count > 0 ? "\(count)" : "\(booster.cost)⭐")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(count > 0 ? SSATheme.candyGreen : SSATheme.candyOrange))
                }

                Text(booster.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? SSATheme.candyYellow : .white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? SSATheme.candyPink.opacity(0.85) : Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    private func hammerAction() {
        if activeBooster == .hammer {
            activeBooster = nil
        } else {
            if profile.hammerCount == 0 && profile.stars < ActiveBooster.hammer.cost {
                profile.addStars(100)
            }
            activeBooster = .hammer
            onHammerUse()
            Task { @MainActor in SoundManager.shared.playSelect() }
        }
    }

    private func colorBombAction() {
        if profile.colorBombCount > 0 || profile.stars >= ActiveBooster.colorBomb.cost {
            if profile.colorBombCount > 0 {
                profile.colorBombCount -= 1
            } else {
                profile.deductStars(ActiveBooster.colorBomb.cost)
            }
            onColorBombUse()
        } else {
            profile.addStars(100)
            profile.deductStars(ActiveBooster.colorBomb.cost)
            onColorBombUse()
        }
    }

    private func extraMovesAction() {
        if profile.extraMovesCount > 0 || profile.stars >= ActiveBooster.extraMoves.cost {
            if profile.extraMovesCount > 0 {
                profile.extraMovesCount -= 1
            } else {
                profile.deductStars(ActiveBooster.extraMoves.cost)
            }
            gameState.addMoves(5)
            onExtraMovesUse()
        } else {
            profile.addStars(100)
            profile.deductStars(ActiveBooster.extraMoves.cost)
            gameState.addMoves(5)
            onExtraMovesUse()
        }
    }
}
