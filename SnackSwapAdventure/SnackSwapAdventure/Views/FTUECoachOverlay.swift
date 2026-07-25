import SwiftUI

/// First-Time User Experience (FTUE) Coach Marks Manager for Levels 1–3.
final class FTUEManager: ObservableObject {
    static let shared = FTUEManager()

    @AppStorage("ftue_l1_done") var ftueL1Done: Bool = false
    @AppStorage("ftue_l2_done") var ftueL2Done: Bool = false
    @AppStorage("ftue_l3_done") var ftueL3Done: Bool = false
    @AppStorage("ftue_skipped_all") var ftueSkippedAll: Bool = false

    func shouldShowFTUE(for level: Int) -> Bool {
        if ftueSkippedAll { return false }
        switch level {
        case 1: return !ftueL1Done
        case 2: return !ftueL2Done
        case 3: return !ftueL3Done
        default: return false
        }
    }

    @MainActor
    func completeFTUE(for level: Int) {
        switch level {
        case 1: ftueL1Done = true
        case 2: ftueL2Done = true
        case 3: ftueL3Done = true
        default: break
        }
        SoundManager.shared.play(.match)
        VoiceAnnouncer.shared.announceLevelStart()
    }

    @MainActor
    func skipAll() {
        ftueSkippedAll = true
        SoundManager.shared.playUITap()
    }
}

/// Coach mark modal overlay for Level 1, 2, and 3 tutorials.
struct FTUECoachOverlay: View {
    let level: Int
    let onDismiss: () -> Void

    @ObservedObject private var manager = FTUEManager.shared
    @State private var stepIndex: Int = 0

    private var steps: [FTUEStep] {
        switch level {
        case 1:
            return [
                FTUEStep(
                    title: "Welcome to Snack Swap!",
                    instruction: "Swap two snacks next to each other to match 3.",
                    subInstruction: "Tap one snack, then a neighbor.",
                    mascotExpression: .happy
                ),
                FTUEStep(
                    title: "Try it now!",
                    instruction: "Match 3 identical snacks to feed your Snackling!",
                    subInstruction: "Look for highlighted snacks on the board.",
                    mascotExpression: .thinking
                )
            ]
        case 2:
            return [
                FTUEStep(
                    title: "Match 4 Special!",
                    instruction: "Match 4 in a row for a striped bonus snack!",
                    subInstruction: "Striped snacks clear entire rows or columns!",
                    mascotExpression: .cheer
                )
            ]
        case 3:
            return [
                FTUEStep(
                    title: "Level Goal & Progress",
                    instruction: "Collect snacks for the goal—watch the progress bar!",
                    subInstruction: "Earn up to 3 stars for higher scores!",
                    mascotExpression: .happy
                )
            ]
        default:
            return []
        }
    }

    var body: some View {
        if manager.shouldShowFTUE(for: level), stepIndex < steps.count {
            let step = steps[stepIndex]

            ZStack {
                // 45% Dim Backdrop
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        advanceStep()
                    }

                VStack(spacing: 20) {
                    Spacer()

                    // Glass Card Coach Box
                    SSAGlassCard(padding: 20, cornerRadius: 24, borderColor: SSATheme.candyYellow) {
                        VStack(spacing: 14) {
                            HStack(spacing: 12) {
                                SnacklingMascotView(
                                    presentation: .dock,
                                    expression: step.mascotExpression,
                                    customSize: 52
                                )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(step.title)
                                        .font(.system(size: 18, weight: .black, design: .rounded))
                                        .foregroundStyle(SSATheme.candyYellow)

                                    Text(step.instruction)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text(step.subInstruction)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(SSATheme.textSecondary)
                                }

                                Spacer(minLength: 0)
                            }

                            HStack {
                                // Skip Button
                                Button {
                                    Task { @MainActor in
                                        manager.skipAll()
                                        onDismiss()
                                    }
                                } label: {
                                    Text("Skip Tutorial")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(SSATheme.textMuted)
                                        .underline()
                                }

                                Spacer()

                                // Next / Got It Button
                                Button {
                                    advanceStep()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(stepIndex < steps.count - 1 ? "NEXT" : "GOT IT!")
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 9)
                                    .background(Capsule().fill(SSATheme.primaryGradient))
                                    .shadow(color: SSATheme.candyPink.opacity(0.4), radius: 6)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .transition(.opacity)
            .onAppear {
                Task { @MainActor in
                    SoundManager.shared.playUITap()
                }
            }
        }
    }

    private func advanceStep() {
        Task { @MainActor in
            SoundManager.shared.playUITap()
            if stepIndex < steps.count - 1 {
                stepIndex += 1
            } else {
                manager.completeFTUE(for: level)
                onDismiss()
            }
        }
    }
}

struct FTUEStep {
    let title: String
    let instruction: String
    let subInstruction: String
    let mascotExpression: SnacklingExpression
}
