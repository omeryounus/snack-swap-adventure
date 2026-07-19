import SwiftUI

/// Bakery / confectionery HUD — warm candy palette, clear hierarchy, single progress bar.
struct GameHUD: View {
    @ObservedObject var gameState: GameState
    let onClose: () -> Void
    let onPause: () -> Void

    // Warm candy palette (no neon cyber accents)
    private let cream = Color(red: 1.0, green: 0.97, blue: 0.92)
    private let creamMuted = Color(red: 1.0, green: 0.94, blue: 0.88).opacity(0.72)
    private let cocoa = Color(red: 0.28, green: 0.16, blue: 0.12)
    private let marshmallow = Color(red: 1.0, green: 0.78, blue: 0.86)
    private let cookieGold = Color(red: 0.96, green: 0.72, blue: 0.28)
    private let frostingPink = Color(red: 0.98, green: 0.45, blue: 0.62)
    private let caramel = Color(red: 0.92, green: 0.58, blue: 0.28)
    private let panelFill = Color(red: 0.22, green: 0.14, blue: 0.18).opacity(0.88)

    var body: some View {
        VStack(spacing: 10) {
            // Row 1: controls + level + timer
            HStack(spacing: 10) {
                hudIconButton(systemName: "xmark", action: onClose)

                levelBadge

                Spacer(minLength: 4)

                timerBadge

                Spacer(minLength: 4)

                hudIconButton(systemName: "pause.fill", action: onPause)
            }

            // Row 2: score / moves / goal — cream labels, warm accent numbers
            HStack(spacing: 8) {
                statChip(
                    title: "SCORE",
                    value: gameState.score.formatted(),
                    valueColor: cookieGold
                )
                statChip(
                    title: "MOVES",
                    value: "\(gameState.movesLeft)",
                    valueColor: caramel
                )
                statChip(
                    title: "GOAL",
                    value: "\(gameState.goalProgressValue)/\(gameState.level.progressDenominator)",
                    valueColor: frostingPink
                )
            }

            // Row 3: single progress bar (goal) + timer shown only as text badge above
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(gameState.level.worldEmoji)
                    Text(gameState.level.goal.shortTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(cream)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(gameState.progress * 100))%")
                        .font(.caption.monospacedDigit().weight(.heavy))
                        .foregroundStyle(cookieGold)
                }

                // ONE thick progress bar — goal fill on muted track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.35, green: 0.24, blue: 0.22).opacity(0.95))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [frostingPink, caramel, cookieGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(14, geo.size.width * gameState.progress))
                            .shadow(color: cookieGold.opacity(0.35), radius: 4, y: 0)
                            .animation(.easeOut(duration: 0.25), value: gameState.goalProgressValue)
                    }
                }
                .frame(height: 14)

                HStack(spacing: 8) {
                    Image(systemName: gameState.isFeverActive ? "flame.fill" : "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(gameState.isFeverActive ? frostingPink : cookieGold)
                    Text(gameState.isFeverActive ? "Sugar Rush x2" : "Sugar Rush")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(cream)
                        .lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [frostingPink, cookieGold],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(gameState.feverProgress > 0 ? 8 : 0, geo.size.width * gameState.feverProgress))
                                .animation(.easeOut(duration: 0.22), value: gameState.feverMeter)
                        }
                    }
                    .frame(height: 7)
                    Text(gameState.isFeverActive ? "\(gameState.feverDisplayTurnsRemaining)" : "\(gameState.streakCount)x")
                        .font(.caption2.monospacedDigit().weight(.heavy))
                        .foregroundStyle(gameState.isFeverActive ? frostingPink : creamMuted)
                        .frame(minWidth: 24, alignment: .trailing)
                }

                // Tiny timer remaining hint (not a second competing bar)
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 10, weight: .bold))
                    Text("Time \(gameState.formattedTime)")
                        .font(.caption2.monospacedDigit().weight(.semibold))
                    Spacer()
                    if gameState.isTimerUrgent {
                        Text("Hurry!")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.35))
                    }
                }
                .foregroundStyle(gameState.isTimerUrgent ? Color(red: 1.0, green: 0.55, blue: 0.4) : creamMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(marshmallow.opacity(0.22), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.09, blue: 0.12).opacity(0.94),
                    Color(red: 0.20, green: 0.11, blue: 0.14).opacity(0.75),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var levelBadge: some View {
        HStack(spacing: 6) {
            Text(gameState.level.worldEmoji)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 0) {
                Text("LEVEL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(creamMuted)
                Text("\(gameState.level.levelNumber)")
                    .font(.headline.bold())
                    .foregroundStyle(cream)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.22, blue: 0.28).opacity(0.95),
                            Color(red: 0.55, green: 0.28, blue: 0.22).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(marshmallow.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private var timerBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.subheadline.bold())
            Text(gameState.formattedTime)
                .font(.system(size: 18, weight: .heavy, design: .rounded).monospacedDigit())
        }
        .foregroundStyle(cream)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(
                    gameState.isTimerUrgent
                        ? LinearGradient(
                            colors: [Color(red: 0.85, green: 0.28, blue: 0.22), caramel],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [
                                Color(red: 0.32, green: 0.20, blue: 0.16).opacity(0.95),
                                Color(red: 0.26, green: 0.16, blue: 0.14).opacity(0.95)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            gameState.isTimerUrgent ? cream.opacity(0.4) : marshmallow.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(gameState.isTimerUrgent ? 1.05 : 1.0)
        .animation(
            gameState.isTimerUrgent
                ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
                : .default,
            value: gameState.isTimerUrgent
        )
    }

    private func statChip(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // Consistent cream labels — no neon headers
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(creamMuted)

            // Accent color ONLY on the big number
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(valueColor)
                .shadow(color: valueColor.opacity(0.25), radius: 2, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.18, green: 0.12, blue: 0.12).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func hudIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.playUITap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(cream)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(red: 0.22, green: 0.14, blue: 0.14).opacity(0.95))
                        .overlay(Circle().stroke(marshmallow.opacity(0.22), lineWidth: 1))
                )
        }
        .buttonStyle(HUDTapButtonStyle())
    }
}

private struct HUDTapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .shadow(
                color: configuration.isPressed ? Color.white.opacity(0.18) : .clear,
                radius: configuration.isPressed ? 8 : 0,
                y: 0
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color(red: 0.14, green: 0.09, blue: 0.12).ignoresSafeArea()
        VStack {
            GameHUD(gameState: GameState(level: .level(5)), onClose: {}, onPause: {})
            Spacer()
        }
    }
}
