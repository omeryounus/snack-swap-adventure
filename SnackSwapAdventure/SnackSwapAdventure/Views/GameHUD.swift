import SwiftUI

enum GameHUDChrome {
    case topBar
    case sidebar
}

/// AAA Apple Arcade style HUD — glassmorphism, circular clock, liquid progress.
/// Adapts between a compact top bar (portrait) and a vertical sidebar (landscape).
struct GameHUD: View {
    @ObservedObject var gameState: GameState
    let onClose: () -> Void
    let onPause: () -> Void
    var chrome: GameHUDChrome = .topBar

    @Environment(\.adaptiveLayout) private var layout
    @StateObject private var meta = MetaProgress.shared
    @State private var timerPulse = false

    var body: some View {
        Group {
            switch chrome {
            case .topBar:
                topBar
            case .sidebar:
                sidebar
            }
        }
        .onAppear { updatePulseState(urgent: gameState.isTimerUrgent) }
        .onChange(of: gameState.isTimerUrgent) { _, urgent in
            updatePulseState(urgent: urgent)
        }
    }

    // MARK: - Portrait top bar

    private var topBar: some View {
        VStack(spacing: layout.isCompactHeight ? 4 : 6) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: layout.hudSpacing) {
                    pauseButton
                    levelBadge
                    Spacer(minLength: 4)
                    starsPill
                    timerRing
                    movesPill
                }
                HStack(spacing: layout.hudSpacing) {
                    pauseButton
                    levelBadge
                    Spacer(minLength: 2)
                    timerRing
                    movesPill
                }
            }
            .frame(maxWidth: .infinity)

            goalBlock

            if gameState.isFeverActive {
                feverBanner
            }
        }
        .padding(.horizontal, layout.isVeryNarrow ? 2 : 4)
        .padding(.top, 2)
        .padding(.bottom, 2)
    }

    // MARK: - Landscape sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                pauseButton
                levelBadge
                Spacer(minLength: 0)
                starsPill
            }

            HStack(spacing: 12) {
                timerRing
                VStack(alignment: .leading, spacing: 6) {
                    movesPill
                    Text(gameState.level.goal.shortTitle)
                        .font(.system(size: layout.hudPillFont, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }
            }

            goalBlock

            if gameState.isFeverActive {
                feverBanner
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Shared bits

    private var pauseButton: some View {
        Button {
            SoundManager.shared.play(.uiTap)
            onPause()
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: layout.isPad ? 18 : 14, weight: .bold))
                .frame(width: layout.hudControlSize, height: layout.hudControlSize)
                .background(Color.white.opacity(0.12))
                .foregroundStyle(.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .accessibilityLabel("Pause")
    }

    private var levelBadge: some View {
        HStack(spacing: 4) {
            Text(gameState.level.worldEmoji)
                .font(layout.isPad ? .subheadline : .caption2)
            Text("L\(gameState.level.levelNumber)")
                .font(.system(size: layout.hudPillFont, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, layout.hudPillPaddingH)
        .padding(.vertical, layout.hudPillPaddingV)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var starsPill: some View {
        HStack(spacing: layout.isPad ? 5 : 3) {
            Text("⭐")
                .font(layout.isPad ? .subheadline : .caption2)
            Text("\(meta.stars)")
                .font(.system(size: layout.hudPillFont, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accentGold)
        }
        .padding(.horizontal, layout.hudPillPaddingH)
        .padding(.vertical, layout.hudPillPaddingV)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: layout.hudTimerStroke)
                .frame(width: layout.hudTimerSize, height: layout.hudTimerSize)

            Circle()
                .trim(from: 0.0, to: CGFloat(max(0, min(1.0, Double(gameState.timeRemaining) / Double(max(1, gameState.level.timeLimit))))))
                .stroke(
                    gameState.isTimerUrgent ? Color.red : Theme.accentGold,
                    style: StrokeStyle(lineWidth: layout.hudTimerStroke, lineCap: .round)
                )
                .frame(width: layout.hudTimerSize, height: layout.hudTimerSize)
                .rotationEffect(.degrees(-90))

            Text("\(gameState.timeRemaining)")
                .font(.system(size: layout.hudTimerFont, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(gameState.isTimerUrgent ? Color.red : Theme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .scaleEffect(timerPulse ? 1.08 : 1.0)
    }

    private var movesPill: some View {
        HStack(spacing: layout.isPad ? 5 : 3) {
            Image(systemName: "hand.tap.fill")
                .font(layout.isPad ? .subheadline : .caption2)
            Text("\(gameState.movesLeft)")
                .font(.system(size: layout.hudPillFont, weight: .semibold, design: .rounded).monospacedDigit())
        }
        .padding(.horizontal, layout.hudPillPaddingH)
        .padding(.vertical, layout.hudPillPaddingV)
        .background(
            gameState.movesLeft <= 5
                ? AnyShapeStyle(Color.orange.opacity(0.35))
                : AnyShapeStyle(Color.white.opacity(0.12))
        )
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(gameState.movesLeft <= 5 ? Color.orange.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var goalBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(gameState.level.goal.shortTitle)
                    .font(.system(size: layout.hudPillFont, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 4)
                Text("\(gameState.goalProgressValue)/\(gameState.level.progressDenominator)")
                    .font(.system(size: layout.hudPillFont, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF3D8A"), Color(hex: "FF6B4A"), Theme.accentGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(14, geo.size.width * gameState.progress))
                        .shadow(color: Color(hex: "FF3D8A").opacity(0.35), radius: 4, y: 0)
                        .animation(.easeOut(duration: 0.25), value: gameState.goalProgressValue)
                }
            }
            .frame(height: layout.progressBarHeight)
        }
    }

    private var feverBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: layout.isPad ? 14 : 11, weight: .bold))
                .foregroundStyle(Color(hex: "FF3D8A"))
            Text("Sugar Rush x2")
                .font(.system(size: layout.hudPillFont, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 4)
            Text("\(gameState.feverDisplayTurnsRemaining) turns")
                .font(.system(size: layout.hudPillFont, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "FF3D8A"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }

    private func updatePulseState(urgent: Bool) {
        if urgent {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                timerPulse = true
            }
        } else {
            withAnimation(.default) {
                timerPulse = false
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "0B0614").ignoresSafeArea()
        VStack {
            GameHUD(gameState: GameState(level: .level(5)), onClose: {}, onPause: {})
            Spacer()
        }
    }
}
