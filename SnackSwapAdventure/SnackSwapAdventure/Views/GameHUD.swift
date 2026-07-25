import SwiftUI

/// AAA Apple Arcade style HUD — glassmorphism, circular clock, liquid progress indicator.
struct GameHUD: View {
    @ObservedObject var gameState: GameState
    let onClose: () -> Void
    let onPause: () -> Void

    @StateObject private var meta = MetaProgress.shared

    @State private var timerPulse = false

    private let lm = LayoutMetrics.shared

    var body: some View {
        VStack(spacing: 12) {
            // Row 1: Pause, Level Badge, Stars, Circular Timer, Moves Pill
            HStack(spacing: lm.hudSpacing) {
                // Pause button (icon-only to save space)
                Button {
                    SoundManager.shared.play(.uiTap)
                    onPause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: lm.isPad ? 18 : 14, weight: .bold))
                        .frame(width: lm.isPad ? 46 : 36, height: lm.isPad ? 46 : 36)
                        .background(Color.white.opacity(0.12))
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }

                // Level Badge
                HStack(spacing: 4) {
                    Text(gameState.level.worldEmoji)
                        .font(lm.isPad ? .subheadline : .caption2)
                    Text("L\(gameState.level.levelNumber)")
                        .font(lm.isPad ? .subheadline.bold() : Theme.fontCaption().bold())
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, lm.hudPillPaddingH)
                .padding(.vertical, lm.hudPillPaddingV)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

                Spacer()

                // Stars Count Pill
                HStack(spacing: lm.isPad ? 5 : 3) {
                    Text("⭐")
                        .font(lm.isPad ? .subheadline : .caption2)
                    Text("\(meta.stars)")
                        .font(lm.isPad ? .subheadline.bold() : Theme.fontCaption().bold())
                        .foregroundStyle(Theme.accentGold)
                }
                .padding(.horizontal, lm.hudPillPaddingH)
                .padding(.vertical, lm.hudPillPaddingV)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))

                // Circular depletion timer
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: lm.hudTimerStroke)
                        .frame(width: lm.hudTimerSize, height: lm.hudTimerSize)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(max(0, min(1.0, Double(gameState.timeRemaining) / Double(gameState.level.timeLimit)))))
                        .stroke(
                            gameState.isTimerUrgent
                                ? Color.red
                                : Theme.accentGold,
                            style: StrokeStyle(lineWidth: lm.hudTimerStroke, lineCap: .round)
                        )
                        .frame(width: lm.hudTimerSize, height: lm.hudTimerSize)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(gameState.timeRemaining)")
                        .font(.system(size: lm.hudTimerFont, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(gameState.isTimerUrgent ? Color.red : Theme.textPrimary)
                }
                .scaleEffect(timerPulse ? 1.08 : 1.0)
                .onAppear {
                    updatePulseState(urgent: gameState.isTimerUrgent)
                }
                .onChange(of: gameState.isTimerUrgent) { _, urgent in
                    updatePulseState(urgent: urgent)
                }

                // Moves pill - turns orange when moves left <= 5
                HStack(spacing: lm.isPad ? 5 : 3) {
                    Image(systemName: "hand.tap.fill")
                        .font(lm.isPad ? .subheadline : .caption2)
                    Text("\(gameState.movesLeft)")
                        .font(lm.isPad ? .subheadline.monospacedDigit() : Theme.fontTabular())
                }
                .padding(.horizontal, lm.hudPillPaddingH)
                .padding(.vertical, lm.hudPillPaddingV)
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
            .padding(.horizontal, lm.hudHorizontalPadding)
            .padding(.top, 8)
            .frame(maxWidth: lm.hudMaxWidth)

            // Liquid Goal Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(gameState.level.goal.shortTitle)
                        .font(lm.isPad ? .subheadline.bold() : Theme.fontCaption().bold())
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("Goal: \(gameState.goalProgressValue)/\(gameState.level.progressDenominator)")
                        .font(lm.isPad ? .subheadline : Theme.fontCaption())
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 4)

                // Liquid fill bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        
                        // Liquid fill gradient
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
                .frame(height: lm.progressBarHeight)
            }
            .padding(.horizontal, lm.hudHorizontalPadding)
            .padding(.vertical, 10)
            .glassCard()
            .padding(.horizontal, 14)
            .frame(maxWidth: lm.hudMaxWidth)
            
            // Sugar rush details overlay
            if gameState.isFeverActive {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: lm.isPad ? 14 : 11, weight: .bold))
                        .foregroundStyle(Color(hex: "FF3D8A"))
                    Text("Sugar Rush x2")
                        .font(lm.isPad ? .subheadline.bold() : Theme.fontCaption().bold())
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(gameState.feverDisplayTurnsRemaining) turns")
                        .font(lm.isPad ? .subheadline : Theme.fontCaption())
                        .foregroundStyle(Color(hex: "FF3D8A"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                .padding(.horizontal, 14)
                .frame(maxWidth: lm.hudMaxWidth)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Theme.bgVoid, Theme.bgVoid.opacity(0.8), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
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

#Preview {
    ZStack {
        Color(hex: "0B0614").ignoresSafeArea()
        VStack {
            GameHUD(gameState: GameState(level: .level(5)), onClose: {}, onPause: {})
            Spacer()
        }
    }
}
