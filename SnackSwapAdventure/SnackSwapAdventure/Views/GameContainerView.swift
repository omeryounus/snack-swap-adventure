import SwiftUI
import SpriteKit

struct GameContainerView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared
    let onExit: () -> Void
    let onNextLevel: () -> Void
    let onReplay: () -> Void
    let onMainMenu: () -> Void

    @State private var didSubmitResult = false
    @State private var submittedRank: Int?
    @State private var isWatchingAd = false
    @State private var adProgress: Double = 0

    @State private var scene: GameScene = {
        let s = GameScene(size: CGSize(width: 390, height: 844))
        s.scaleMode = .resizeFill
        return s
    }()

    @State private var showFTUEOverlay: Bool = true
    @State private var activeBooster: ActiveBooster? = nil

    var body: some View {
        ZStack {
            // Layer 1: World Gameplay Background Plate
            GameplayBackgroundView(level: gameState.level.levelNumber)

            // Layer 2: SpriteKit Match-3 Game Board
            SpriteView(
                scene: scene,
                options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
                .ignoresSafeArea()
                .onAppear {
                    DispatchQueue.main.async {
                        scene.configure(with: gameState)
                        if let view = scene.view {
                            scene.size = view.bounds.size
                        }
                        scene.rebuildBoard()
                    }
                }

            // Layer 3A: Top Glass Game HUD & Active Booster Banner
            VStack(spacing: 0) {
                GameHUD(
                    gameState: gameState,
                    onClose: {
                        gameState.stopTimer()
                        onExit()
                    },
                    onPause: {
                        gameState.isPaused = true
                    }
                )

                if activeBooster == .hammer {
                    HStack(spacing: 12) {
                        Text("🔨 TAP ANY TILE TO SMASH IT!")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(SSATheme.candyYellow)

                        Button {
                            activeBooster = nil
                            scene.isHammerModeActive = false
                        } label: {
                            Text("CANCEL")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.red.opacity(0.7)))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.75)))
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }

            // Layer 3B: Bottom Booster Toolbar & Mascot Feedback
            VStack(spacing: 0) {
                Spacer()

                // Booster Toolbar
                BoosterBarView(
                    gameState: gameState,
                    activeBooster: $activeBooster,
                    onHammerUse: {
                        scene.isHammerModeActive = true
                        scene.onHammerUsed = {
                            activeBooster = nil
                        }
                    },
                    onColorBombUse: {
                        scene.plantSpecialOnBoard(.rainbow)
                    },
                    onExtraMovesUse: {
                        scene.refreshHUD()
                    }
                )
                .padding(.bottom, 6)

                // Snackling Mascot Reaction Bubble (Screen 03 Gameplay)
                SnacklingMascot(
                    expression: gameState.isFeverActive ? .cheer : (gameState.outcome == .playing ? .happy : .thinking),
                    size: 44,
                    speechBubbleText: gameState.lastFeedMessage
                )
                .padding(.bottom, 4)
            }

            // Layer 4: FTUE Tutorial Coach Mark Overlay (Levels 1–3)
            if showFTUEOverlay {
                FTUECoachOverlay(level: gameState.level.levelNumber) {
                    showFTUEOverlay = false
                }
            }

            if gameState.isPaused, gameState.outcome == .playing {
                PauseOverlay(
                    soundOn: meta.soundEnabled,
                    musicOn: meta.musicEnabled,
                    onResume: { gameState.isPaused = false },
                    onToggleSound: { meta.setSoundEnabled(!meta.soundEnabled) },
                    onToggleMusic: { meta.setMusicEnabled(!meta.musicEnabled) },
                    onQuit: {
                        gameState.isPaused = false
                        gameState.stopTimer()
                        onExit()
                    },
                    onMainMenu: {
                        gameState.isPaused = false
                        gameState.stopTimer()
                        onMainMenu()
                    }
                )
            }

            // Timer expired — watch ad or spend stars
            if gameState.outcome == .timedOut {
                TimeUpOverlay(
                    stars: meta.stars,
                    starCost: LevelConfig.timeExtensionStarCost,
                    extensionSeconds: LevelConfig.timeExtensionSeconds,
                    isWatchingAd: isWatchingAd,
                    adProgress: adProgress,
                    onWatchAd: { watchAdForTime() },
                    onSpendStars: { spendStarsForTime() },
                    onGiveUp: {
                        gameState.forfeitAfterTimeout()
                    }
                )
                .transition(.opacity.combined(with: .scale))
            }

            if case .won(let stars, let score) = gameState.outcome {
                LevelResultOverlay(
                    won: true,
                    stars: stars,
                    score: score,
                    target: gameState.level.targetScore,
                    rank: submittedRank ?? profile.lastSubmittedRank,
                    isSyncing: profile.isSyncing,
                    onPrimary: onNextLevel,
                    onReplay: onReplay,
                    onMap: onExit,
                    onMainMenu: onMainMenu
                )
                .transition(.opacity.combined(with: .scale))
            } else if case .lost(let score) = gameState.outcome {
                LevelResultOverlay(
                    won: false,
                    stars: 0,
                    score: score,
                    target: gameState.level.targetScore,
                    rank: submittedRank ?? profile.lastSubmittedRank,
                    isSyncing: profile.isSyncing,
                    onPrimary: onReplay,
                    onReplay: onReplay,
                    onMap: onExit,
                    onMainMenu: onMainMenu
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: gameState.outcome)
        .onChange(of: gameState.outcome) { _, newValue in
            guard !didSubmitResult else { return }
            switch newValue {
            case .won(let stars, let score):
                didSubmitResult = true
                Task { await submit(score: score, stars: stars, won: true) }
            case .lost(let score):
                didSubmitResult = true
                Task { await submit(score: score, stars: 0, won: false) }
            case .playing, .timedOut:
                break
            }
        }
        .onAppear {
            didSubmitResult = false
            submittedRank = nil
        }
        .onDisappear {
            gameState.stopTimer()
        }
    }

    private func watchAdForTime() {
        guard !isWatchingAd else { return }
        isWatchingAd = true
        adProgress = 0
        SoundManager.shared.playUITap()
        // Progress ticker while ad loads / plays (real AdMob or simulated fallback).
        Task {
            let ticker = Task {
                for i in 1...40 {
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    await MainActor.run {
                        if isWatchingAd {
                            adProgress = min(0.95, Double(i) / 40.0)
                        }
                    }
                }
            }
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                RewardedAdService.shared.show { earned in
                    Task { @MainActor in
                        ticker.cancel()
                        isWatchingAd = false
                        adProgress = 1
                        if earned {
                            _ = gameState.extendTime()
                        }
                        cont.resume()
                    }
                }
            }
        }
    }

    private func spendStarsForTime() {
        SoundManager.shared.playUITap()
        if meta.spendStars(LevelConfig.timeExtensionStarCost) {
            _ = gameState.extendTime()
        }
    }

    private func submit(score: Int, stars: Int, won: Bool) async {
        await profile.recordLevelResult(
            level: gameState.level.levelNumber,
            score: score,
            stars: stars,
            won: won,
            movesLeft: gameState.movesLeft,
            maxCombo: gameState.maxComboThisLevel
        )
        submittedRank = profile.lastSubmittedRank
    }
}

// MARK: - Time up overlay

struct TimeUpOverlay: View {
    let stars: Int
    let starCost: Int
    let extensionSeconds: Int
    let isWatchingAd: Bool
    let adProgress: Double
    let onWatchAd: () -> Void
    let onSpendStars: () -> Void
    let onGiveUp: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 18) {
                Text("⏰")
                    .font(.system(size: 56))
                Text("Time's Up!")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Keep playing with +\(extensionSeconds) seconds")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                if isWatchingAd {
                    VStack(spacing: 10) {
                        Text("Watching reward ad…")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.85))
                        ProgressView(value: adProgress)
                            .tint(.yellow)
                            .padding(.horizontal)
                        Text("\(Int(adProgress * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.vertical, 8)
                } else {
                    Button(action: onWatchAd) {
                        HStack {
                            Text("▶️")
                            Text("Watch Ad  ·  +\(extensionSeconds)s")
                                .font(.headline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(action: onSpendStars) {
                        HStack {
                            Text("⭐")
                            Text("Spend \(starCost) Stars  ·  +\(extensionSeconds)s")
                                .font(.headline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .opacity(stars >= starCost ? 1 : 0.45)
                    }
                    .disabled(stars < starCost)

                    Text("You have \(stars) ⭐")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Button(action: onGiveUp) {
                    Text("Give up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.top, 4)
                }
                .disabled(isWatchingAd)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.28, green: 0.12, blue: 0.28),
                                Color(red: 0.12, green: 0.1, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
            .shadow(color: .black.opacity(0.45), radius: 30, y: 12)
        }
    }
}

struct PauseOverlay: View {
    let soundOn: Bool
    let musicOn: Bool
    let onResume: () -> Void
    let onToggleSound: () -> Void
    let onToggleMusic: () -> Void
    let onQuit: () -> Void
    let onMainMenu: () -> Void

    var body: some View {
        let soundBinding = Binding<Bool>(
            get: { soundOn },
            set: { _ in
                SoundManager.shared.playUITap()
                onToggleSound()
            }
        )
        let musicBinding = Binding<Bool>(
            get: { musicOn },
            set: { _ in
                SoundManager.shared.playUITap()
                onToggleMusic()
            }
        )

        return ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("Paused")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Button { SoundManager.shared.playUITap(); onResume() } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(OverlayPressButtonStyle())

                HStack {
                    Label("Sound Effects", systemImage: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Toggle("", isOn: soundBinding)
                        .labelsHidden()
                        .tint(.pink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack {
                    Label("Music Loop", systemImage: musicOn ? "music.note" : "music.note.slash")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Toggle("", isOn: musicBinding)
                        .labelsHidden()
                        .tint(.pink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button { SoundManager.shared.playUITap(); onQuit() } label: {
                    Label("World Map", systemImage: "map.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(OverlayPressButtonStyle())

                Button { SoundManager.shared.playUITap(); onMainMenu() } label: {
                    Label("Main Menu", systemImage: "house.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(OverlayPressButtonStyle())
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.24, green: 0.13, blue: 0.19),
                                Color(red: 0.12, green: 0.08, blue: 0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .padding(30)
            .shadow(color: .black.opacity(0.42), radius: 28, y: 12)
        }
    }
}

struct LevelResultOverlay: View {
    let won: Bool
    let stars: Int
    let score: Int
    let target: Int
    var rank: Int? = nil
    var isSyncing: Bool = false
    let onPrimary: () -> Void
    let onReplay: () -> Void
    let onMap: () -> Void
    let onMainMenu: () -> Void
    @State private var showPrize = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            if won {
                RewardRain()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            VStack(spacing: 18) {
                // Mascot Reaction (Screen 05 Win / Screen 06 Lose)
                SnacklingMascot(
                    expression: won ? .cheer : .sad,
                    size: 80,
                    speechBubbleText: won ? "YAY! Level Cleared!" : "Aww, so close! Try again!"
                )

                Text(won ? "Level Complete!" : "Out of Moves")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                if won {
                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { i in
                            ZStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 35, weight: .black))
                                    .foregroundStyle(i <= stars ? LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [.white.opacity(0.20)], startPoint: .top, endPoint: .bottom))
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white.opacity(i <= stars ? 0.85 : 0))
                                    .offset(x: 10, y: -9)
                            }
                            .scaleEffect(showPrize && i <= stars ? 1.16 : 0.94)
                            .animation(.spring(response: 0.42, dampingFraction: 0.55).delay(Double(i) * 0.09), value: showPrize)
                        }
                    }
                }

                Text("Score \(score)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))

                if isSyncing {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Syncing score…")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                } else if let rank {
                    Text("Global Rank #\(rank)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.yellow)
                }

                VStack(spacing: 12) {
                    Button {
                        SoundManager.shared.playUITap()
                        onPrimary()
                    } label: {
                        Label(won ? "Next Level" : "Try Again", systemImage: won ? "arrow.right.circle.fill" : "arrow.clockwise")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: won ? [.green, .mint] : [.pink, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(OverlayPressButtonStyle())

                    HStack(spacing: 10) {
                        Button {
                            SoundManager.shared.playUITap()
                            onReplay()
                        } label: {
                            Label("Replay", systemImage: "arrow.counterclockwise")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(OverlayPressButtonStyle())

                        Button {
                            SoundManager.shared.playUITap()
                            onMap()
                        } label: {
                            Label("Map", systemImage: "map.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(OverlayPressButtonStyle())
                    }

                    Button {
                        SoundManager.shared.playUITap()
                        onMainMenu()
                    } label: {
                        Label("Main Menu", systemImage: "house.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .foregroundStyle(.white.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(OverlayPressButtonStyle())
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.16, blue: 0.36),
                                Color(red: 0.14, green: 0.12, blue: 0.24)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
            .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
        }
        .onAppear {
            showPrize = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62).delay(0.08)) {
                showPrize = true
            }
        }
    }
}

private struct OverlayPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct RewardRain: View {
    private let snacks = ["🍪", "🍩", "🍬", "🍿", "⭐", "✨"]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0..<18, id: \.self) { index in
                        let x = CGFloat((index * 53) % 100) / 100 * geo.size.width
                        let speed = CGFloat(34 + (index % 5) * 14)
                        let y = CGFloat((t * Double(speed) + Double(index * 41)).truncatingRemainder(dividingBy: Double(geo.size.height + 120))) - 70
                        Text(snacks[index % snacks.count])
                            .font(.system(size: CGFloat(16 + (index % 4) * 5)))
                            .rotationEffect(.degrees(Double(index * 19) + t * 24))
                            .position(x: x, y: y)
                            .opacity(0.72)
                    }
                }
            }
        }
    }
}
