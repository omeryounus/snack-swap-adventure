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
    /// Hammer mode prompt. Rendered inside the card, in the space the geometry
    /// already reserves for transient rows — outside it, the card's clip shaves it.
    var hammerPromptActive: Bool = false
    var onCancelHammer: () -> Void = {}

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

                // Both can end the level, but moves is the constraint the
                // player steers with, so it carries the weight and time is
                // demoted to a secondary readout.
                SSAOrnateStat(
                    title: "TIME",
                    value: "\(gameState.timeRemaining)",
                    accent: gameState.isTimerUrgent ? .red : Color(hex: "9FD8FF"),
                    compact: true
                )
                .frame(maxWidth: .infinity)
                .opacity(timerPulse ? 0.6 : 1)

                SSAOrnateStat(
                    title: "MOVES",
                    value: "\(gameState.movesLeft)",
                    accent: gameState.movesLeft <= 5 ? .orange : SSATheme.candyYellow,
                    emphasised: true
                )
                .frame(maxWidth: .infinity)

                starPurse
            }

            // The card permanently reserves room for the transient rows so the
            // board never moves. Idle, that space carries the goal description
            // and a divider rather than reading as a hole in the frame — but it
            // is filler, so it yields the moment a real row needs the space.
            if hasTransientRow {
                Spacer(minLength: 0)
            } else {
                idleOrnament
            }

            if gameState.isFeverActive {
                feverRow
            }

            if hammerPromptActive {
                hammerRow
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
                .font(.system(size: isSidebar ? 13 : 15, weight: .black))
                .foregroundStyle(SSATheme.candyYellow)
                .shadow(color: SSATheme.candyYellow.opacity(0.8), radius: 5)
            Text("\(profile.stars)")
                .font(.system(size: isSidebar ? 16 : 19, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(Color(hex: "FFE9A8"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, isSidebar ? 8 : 10)
        .padding(.vertical, isSidebar ? 7 : 9)
        .frame(minWidth: isSidebar ? 62 : 74)
        .background(Capsule().fill(SSAOrnate.plaqueFill))
        .overlay(Capsule().strokeBorder(SSAOrnate.gold, lineWidth: 2.5))
        .layoutPriority(1)
    }

    private var isSidebar: Bool { chrome == .sidebar }

    private var hasTransientRow: Bool {
        gameState.isFeverActive || hammerPromptActive
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
            Spacer(minLength: 0)
        }
    }

    /// Hammer-mode prompt, styled to match the gilded chrome.
    private var hammerRow: some View {
        HStack(spacing: 8) {
            Text("🔨 TAP A TILE!")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(SSATheme.candyYellow)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            Button(action: onCancelHammer) {
                Text("CANCEL")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.red.opacity(0.85)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.5)))
        .overlay(Capsule().strokeBorder(SSAOrnate.goldRim, lineWidth: 1.5))
    }

    /// Target on the left, live value on the right, bar underneath. The old
    /// layout restated the same number three times — as the goal detail, the
    /// goal title, and again in the progress count.
    private var objectiveRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(goalCaption)
                        .font(.system(size: isSidebar ? 9 : 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "E7D6FF").opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(goalTargetText)
                        .font(.system(size: isSidebar ? 13 : 16, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color(hex: "FFF3D6"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 6)

                Text(goalCurrentText)
                    .font(.system(size: isSidebar ? 22 : 30, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(SSATheme.candyYellow)
                    .shadow(color: SSATheme.candyYellow.opacity(0.5), radius: 5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            SSAOrnateProgressBar(progress: gameState.progress, height: isSidebar ? 14 : 18)
                .animation(.easeOut(duration: 0.25), value: gameState.goalProgressValue)
        }
    }

    /// What the player is being asked for, without repeating the number.
    private var goalCaption: String {
        switch gameState.level.goal {
        case .score: return "TARGET SCORE"
        case .collect(let type, _): return "COLLECT \(type.emoji)"
        case .clearSnacks: return "CLEAR SNACKS"
        case .makeCombos: return "MAKE COMBOS"
        }
    }

    private var goalTargetText: String {
        Self.grouped(gameState.level.progressDenominator)
    }

    private var goalCurrentText: String {
        Self.grouped(gameState.goalProgressValue)
    }

    private static func grouped(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Landscape

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: sidebarIsTight ? 6 : 10) {
            SSAOrnateBanner(
                title: gameState.level.themeName,
                tint: SSATheme.candyPink,
                stretches: true,
                compact: true
            )

            HStack(spacing: 8) {
                pauseButton
                Spacer(minLength: 4)
                starPurse
            }

            // Three across even in the narrow column — they share the width, so
            // the row fits whatever the sidebar happens to be.
            HStack(spacing: 6) {
                SSAOrnateStat(
                    title: "LEVEL",
                    value: "\(gameState.level.levelNumber)",
                    accent: .white,
                    compact: true
                )
                .frame(maxWidth: .infinity)

                SSAOrnateStat(
                    title: "TIME",
                    value: "\(gameState.timeRemaining)",
                    accent: gameState.isTimerUrgent ? .red : SSATheme.candyYellow,
                    compact: true
                )
                .frame(maxWidth: .infinity)
                .opacity(timerPulse ? 0.6 : 1)

                SSAOrnateStat(
                    title: "MOVES",
                    value: "\(gameState.movesLeft)",
                    accent: gameState.movesLeft <= 5 ? .orange : .white,
                    compact: true
                )
                .frame(maxWidth: .infinity)
            }

            // Slack lives here, so transient rows push into it rather than
            // shoving the objective out of the card.
            Spacer(minLength: 0)

            if gameState.isFeverActive {
                feverRow
            }

            if hammerPromptActive {
                hammerRow
            }

            objectiveRow
        }
        .padding(sidebarIsTight ? 8 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ornateHudBackground)
    }

    /// Phone landscape gives the sidebar barely 230pt of height, so it trims
    /// its own spacing rather than pushing content out of the card.
    private var sidebarIsTight: Bool { layout.isCompactHeight }

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
                .font(.system(size: isSidebar ? 17 : 20, weight: .black))
                .foregroundStyle(Color(hex: "FFF3D6"))
                .frame(width: isSidebar ? 42 : 50, height: isSidebar ? 42 : 50)
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
