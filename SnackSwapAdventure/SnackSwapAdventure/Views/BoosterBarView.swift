import SwiftUI

enum ActiveBooster: String, CaseIterable {
    case hammer = "Snack Hammer"
    case colorBomb = "Color Bomb"
    case extraMoves = "+5 Moves"

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
        let stack = Group {
            boosterButton(
                booster: .hammer,
                count: profile.hammerCount,
                isSelected: activeBooster == .hammer
            ) {
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

            boosterButton(
                booster: .colorBomb,
                count: profile.colorBombCount,
                isSelected: activeBooster == .colorBomb
            ) {
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

            boosterButton(
                booster: .extraMoves,
                count: profile.extraMovesCount,
                isSelected: false
            ) {
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

        Group {
            if axis == .vertical {
                VStack(spacing: compact ? 10 : 14) { stack }
            } else {
                HStack(spacing: compact ? 10 : 16) { stack }
            }
        }
        .padding(.horizontal, axis == .vertical ? 10 : 16)
        .padding(.vertical, axis == .vertical ? 12 : 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.45))
                .overlay(Capsule().stroke(SSATheme.candyYellow.opacity(0.3), lineWidth: 1.5))
        )
    }

    private func boosterButton(
        booster: ActiveBooster,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(isSelected ? SSATheme.candyPink : Color.white.opacity(0.12))
                        .frame(width: buttonSize, height: buttonSize)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? .white : SSATheme.candyYellow.opacity(0.6), lineWidth: isSelected ? 2.5 : 1)
                        )

                    Image(systemName: booster.iconName)
                        .font(.system(size: compact ? 16 : 20, weight: .bold))
                        .foregroundStyle(isSelected ? .white : SSATheme.candyYellow)
                        .frame(width: buttonSize, height: buttonSize)

                    // Count or Star cost badge
                    Text(count > 0 ? "\(count)" : "⭐\(booster.cost)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(count > 0 ? SSATheme.candyGreen : SSATheme.candyOrange))
                        .offset(x: 6, y: -4)
                }

                if !compact || axis == .horizontal {
                    Text(compact ? shortName(booster) : booster.rawValue)
                        .font(.system(size: compact ? 9 : 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? SSATheme.candyYellow : .white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var buttonSize: CGFloat {
        if layout.isVeryNarrow { return 32 }
        if compact { return 36 }
        return layout.isPad ? 50 : 44
    }

    private func shortName(_ booster: ActiveBooster) -> String {
        switch booster {
        case .hammer: return "Hammer"
        case .colorBomb: return "Bomb"
        case .extraMoves: return "+5"
        }
    }
}
