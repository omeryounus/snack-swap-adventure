import SwiftUI

/// Professional top-of-screen HUD for match-3 gameplay.
struct GameHUD: View {
    @ObservedObject var gameState: GameState
    let onClose: () -> Void
    let onPause: () -> Void

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

            // Row 2: score / moves / goal chips
            HStack(spacing: 8) {
                statChip(
                    title: "SCORE",
                    value: gameState.score.formatted(),
                    accent: Color(red: 0.45, green: 0.95, blue: 0.7),
                    icon: "bolt.fill"
                )
                statChip(
                    title: "MOVES",
                    value: "\(gameState.movesLeft)",
                    accent: Color(red: 1.0, green: 0.82, blue: 0.35),
                    icon: "hand.tap.fill"
                )
                statChip(
                    title: "GOAL",
                    value: "\(gameState.goalProgressValue)/\(gameState.level.progressDenominator)",
                    accent: Color(red: 1.0, green: 0.55, blue: 0.75),
                    icon: "flag.fill"
                )
            }

            // Row 3: goal description + progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(gameState.level.worldEmoji)
                    Text(gameState.level.goal.shortTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(gameState.progress * 100))%")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.white.opacity(0.75))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(10, geo.size.width * gameState.progress))
                            .animation(.easeOut(duration: 0.25), value: gameState.goalProgressValue)
                    }
                }
                .frame(height: 8)

                // Timer strip under goal
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: gameState.isTimerUrgent
                                        ? [Color.red, Color.orange]
                                        : [Color.cyan, Color.mint, Color.green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * gameState.timerProgress))
                            .animation(.linear(duration: 0.9), value: gameState.timeRemaining)
                    }
                }
                .frame(height: 5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.08, blue: 0.22).opacity(0.92),
                    Color(red: 0.18, green: 0.1, blue: 0.28).opacity(0.78),
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
                    .foregroundStyle(.white.opacity(0.55))
                Text("\(gameState.level.levelNumber)")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.55), Color.pink.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
        .foregroundStyle(gameState.isTimerUrgent ? Color.white : Color.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(
                    gameState.isTimerUrgent
                        ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(
                            colors: [Color.black.opacity(0.45), Color.black.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            gameState.isTimerUrgent ? Color.white.opacity(0.35) : Color.white.opacity(0.12),
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
        .shadow(color: gameState.isTimerUrgent ? .red.opacity(0.45) : .clear, radius: 8)
    }

    private func statChip(title: String, value: String, accent: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
            }
            .foregroundStyle(accent.opacity(0.9))

            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(accent.opacity(0.35), lineWidth: 1)
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
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color(red: 0.12, green: 0.1, blue: 0.2).ignoresSafeArea()
        VStack {
            GameHUD(gameState: GameState(level: .level(5)), onClose: {}, onPause: {})
            Spacer()
        }
    }
}
