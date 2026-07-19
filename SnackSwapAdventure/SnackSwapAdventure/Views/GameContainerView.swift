import SwiftUI
import SpriteKit

struct GameContainerView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared
    let onExit: () -> Void
    let onNextLevel: () -> Void
    let onReplay: () -> Void

    @State private var didSubmitResult = false
    @State private var submittedRank: Int?
    @State private var isWatchingAd = false
    @State private var adProgress: Double = 0

    @State private var scene: GameScene = {
        let s = GameScene(size: CGSize(width: 390, height: 844))
        s.scaleMode = .resizeFill
        return s
    }()

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
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
                Spacer()
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
                    onMap: onExit
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
                    onMap: onExit
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

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Paused").font(.title.bold()).foregroundStyle(.white)
                Button { SoundManager.shared.playUITap(); onResume() } label: {
                    Text("Resume").font(.headline.bold()).frame(maxWidth: .infinity)
                        .padding().background(LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button { SoundManager.shared.playUITap(); onToggleSound() } label: {
                    Text(soundOn ? "Sound: On" : "Sound: Off").frame(maxWidth: .infinity).padding()
                        .background(Color.white.opacity(0.12)).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button { SoundManager.shared.playUITap(); onToggleMusic() } label: {
                    Text(musicOn ? "Music: On" : "Music: Off").frame(maxWidth: .infinity).padding()
                        .background(Color.white.opacity(0.12)).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button { SoundManager.shared.playUITap(); onQuit() } label: {
                    Text("World Map").frame(maxWidth: .infinity).padding()
                        .background(Color.white.opacity(0.08)).foregroundStyle(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.18, green: 0.12, blue: 0.28)))
            .padding(32)
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

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(won ? "🎉" : "😿")
                    .font(.system(size: 56))
                    .scaleEffect(won ? 1.1 : 1.0)

                Text(won ? "Level Complete!" : "Out of Moves")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                if won {
                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { i in
                            Text(i <= stars ? "★" : "☆")
                                .font(.system(size: 36))
                                .foregroundStyle(i <= stars ? Color.yellow : Color.white.opacity(0.35))
                                .scaleEffect(i <= stars ? 1.15 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(Double(i) * 0.08), value: stars)
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
                        Text(won ? "Next Level" : "Try Again")
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

                    HStack(spacing: 12) {
                        Button {
                            SoundManager.shared.playUITap()
                            onReplay()
                        } label: {
                            Text("Replay")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        Button {
                            SoundManager.shared.playUITap()
                            onMap()
                        } label: {
                            Text("World Map")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
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
    }
}
