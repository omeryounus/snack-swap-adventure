import SwiftUI

enum GameHUDChrome {
    case topBar
    case sidebar
}

/// Single glass HUD card. Every control stays inside the card — no scale pulses,
/// no floating badges, no overlapping neighbors.
struct GameHUD: View {
    @ObservedObject var gameState: GameState
    let onClose: () -> Void
    let onPause: () -> Void
    var chrome: GameHUDChrome = .topBar

    @Environment(\.adaptiveLayout) private var layout
    /// PlayerProfile owns the canonical star balance and mirrors it into
    /// MetaProgress, so the HUD reads it directly for live updates.
    @StateObject private var profile = PlayerProfile.shared
    @State private var timerPulse = false

    var body: some View {
        Group {
            switch chrome {
            case .topBar: topBar
            case .sidebar: sidebar
            }
        }
        .onAppear { updatePulseState(urgent: gameState.isTimerUrgent) }
        .onChange(of: gameState.isTimerUrgent) { _, urgent in
            updatePulseState(urgent: urgent)
        }
    }

    // MARK: - Portrait

    private var topBar: some View {
        VStack(spacing: 10) {
            // Level plaque centred like a hanging sign, with pause and the
            // star purse flanking it.
            // The name leads, full width, so it is never cropped.
            SSAOrnateBanner(
                title: gameState.level.themeName,
                tint: SSATheme.candyPink,
                stretches: true
            )

            // One row underneath: pause and the star purse flank the three
            // stats, which share the remaining width equally so the row fits
            // by construction on any screen.
            HStack(spacing: 8) {
                pauseButton

                SSAOrnateStat(
                    title: "LEVEL",
                    value: "\(gameState.level.levelNumber)",
                    accent: .white
                )
                .frame(maxWidth: .infinity)

                SSAOrnateStat(
                    title: "TIME",
                    value: "\(gameState.timeRemaining)",
                    accent: gameState.isTimerUrgent ? .red : SSATheme.candyYellow
                )
                .frame(maxWidth: .infinity)
                .opacity(timerPulse ? 0.6 : 1)

                SSAOrnateStat(
                    title: "MOVES",
                    value: "\(gameState.movesLeft)",
                    accent: gameState.movesLeft <= 5 ? .orange : .white
                )
                .frame(maxWidth: .infinity)

                starPurse
            }

            // The card permanently reserves room for the transient rows so the
            // board never moves. Idle, that space carries the goal description
            // and a divider rather than reading as a hole in the frame.
            idleOrnament

            if gameState.isFeverActive {
                feverRow
            }

            objectiveRow
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ornateHudBackground)
    }

    /// Gilded shell for the whole bar.
    private var ornateHudBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(SSAOrnate.panelFill)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(SSAOrnate.gold, lineWidth: 3)
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                .padding(3)
        }
    }

    private var starPurse: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(SSATheme.candyYellow)
                .shadow(color: SSATheme.candyYellow.opacity(0.8), radius: 5)
            Text("\(profile.stars)")
                .font(.system(size: 19, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(Color(hex: "FFE9A8"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(minWidth: 74)
        .background(Capsule().fill(SSAOrnate.plaqueFill))
        .overlay(Capsule().strokeBorder(SSAOrnate.gold, lineWidth: 2.5))
        .layoutPriority(1)
    }

    private var idleOrnament: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                Capsule().fill(SSAOrnate.gold).frame(height: 2)
                SSAGem(size: 9, tint: SSATheme.candyPink)
                Capsule().fill(SSAOrnate.gold).frame(height: 2)
            }
            .opacity(0.5)
            Text(gameState.level.goal.detail)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "E7D6FF").opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
    }

    /// The level goal, framed and labelled rather than sharing a line.
    private var objectiveRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(gameState.level.goal.shortTitle)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "FFF3D6"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 6)
                Text("\(gameState.goalProgressValue)/\(gameState.level.progressDenominator)")
                    .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(SSATheme.candyYellow)
                    .lineLimit(1)
            }

            SSAOrnateProgressBar(progress: gameState.progress, height: 18)
                .animation(.easeOut(duration: 0.25), value: gameState.goalProgressValue)
        }
    }

    // MARK: - Landscape

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                pauseButton
                statChip(
                    title: gameState.level.themeName.uppercased(),
                    value: "\(gameState.level.levelNumber)",
                    accent: .white,
                    titleMaxWidth: layout.hudThemeNameMaxWidth
                )
                Spacer(minLength: 0)
                statChip(title: "⭐", value: "\(profile.stars)", accent: Theme.accentGold)
            }

            HStack(spacing: 8) {
                timerChip
                statChip(
                    title: "MOVES",
                    value: "\(gameState.movesLeft)",
                    accent: gameState.movesLeft <= 5 ? .orange : .white
                )
            }

            goalRow

            if gameState.isFeverActive {
                feverRow
            }

            if showsStatusLine {
                statusLine
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(hudBackground)
    }

    // MARK: - Pieces

    private var showsStatusLine: Bool {
        !gameState.lastFeedMessage.isEmpty && !layout.isCompactHeight
    }

    private var pauseButton: some View {
        Button {
            SoundManager.shared.play(.uiTap)
            onPause()
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color(hex: "FFF3D6"))
                .frame(width: 50, height: 50)
                .background(Circle().fill(SSAOrnate.plaqueFill))
                .overlay(Circle().strokeBorder(SSAOrnate.gold, lineWidth: 3))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1).padding(3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pause")
    }

    /// `titleMaxWidth` caps long level-theme names so the chip can never push
    /// the rest of the row out of the HUD card.
    private func statChip(
        title: String,
        value: String,
        accent: Color,
        titleMaxWidth: CGFloat? = nil
    ) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: titleMaxWidth)
            Text(value)
                .font(.system(size: layout.isCompactWidth ? 22 : 26, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(minWidth: 56)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var timerChip: some View {
        VStack(spacing: 3) {
            Text("TIME")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            Text("\(gameState.timeRemaining)")
                .font(.system(size: layout.isCompactWidth ? 22 : 26, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(gameState.isTimerUrgent ? Color.red : Theme.accentGold)
                .opacity(timerPulse ? 0.55 : 1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(minWidth: 64)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(gameState.isTimerUrgent ? Color.red.opacity(0.7) : Color.clear, lineWidth: 1)
        )
    }

    private var compactGoalRow: some View {
        HStack(spacing: 8) {
            Text(gameState.level.goal.shortTitle)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF3D8A"), Color(hex: "FF6B4A"), Theme.accentGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * gameState.progress))
                        .animation(.easeOut(duration: 0.25), value: gameState.goalProgressValue)
                }
            }
            .frame(height: 14)

            Text("\(gameState.goalProgressValue)/\(gameState.level.progressDenominator)")
                .font(.system(size: 17, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
    }

    private var goalRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(gameState.level.goal.shortTitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 6)
                Text("\(gameState.goalProgressValue)/\(gameState.level.progressDenominator)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF3D8A"), Color(hex: "FF6B4A"), Theme.accentGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * gameState.progress))
                        .animation(.easeOut(duration: 0.25), value: gameState.goalProgressValue)
                }
            }
            .frame(height: 8)
        }
    }

    private var feverRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .bold))
            Text("Sugar Rush ×2")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text("\(gameState.feverDisplayTurnsRemaining) turns")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(Color(hex: "FF3D8A"))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(hex: "FF3D8A").opacity(0.14))
        .clipShape(Capsule())
    }

    private var statusLine: some View {
        Text(gameState.lastFeedMessage)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hudBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.black.opacity(0.42))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
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
