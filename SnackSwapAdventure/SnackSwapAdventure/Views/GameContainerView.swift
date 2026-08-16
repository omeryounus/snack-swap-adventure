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
    /// Fired once when the level is failed, so a life can be spent.
    var onLevelLost: () -> Void = {}
    /// Fired once when the level is cleared, with the stars earned.
    var onLevelWon: (Int) -> Void = { _ in }

    @State private var didSubmitResult = false
    @State private var submittedRank: Int?
    @State private var isWatchingAd = false
    @State private var adProgress: Double = 0

    @Environment(\.adaptiveLayout) private var layout

    @State private var scene: GameScene = {
        let s = GameScene(size: CGSize(width: 390, height: 844))
        s.scaleMode = .resizeFill
        return s
    }()

    @State private var showFTUEOverlay: Bool = true
    @State private var activeBooster: ActiveBooster? = nil

    var body: some View {
        ZStack {
            GameplayBackgroundView(level: gameState.level.levelNumber)

            playfield

            // Layer 4: FTUE Tutorial Coach Mark Overlay (Levels 1–3)
            if showFTUEOverlay {
                FTUECoachOverlay(
                    level: gameState.level.levelNumber,
                    chromeClearance: chromeClearance
                ) {
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
                    onPrimary: { afterInterstitial(onNextLevel) },
                    onReplay: { afterInterstitial(onReplay) },
                    onMap: { afterInterstitial(onExit) },
                    onMainMenu: { afterInterstitial(onMainMenu) },
                    level: gameState.level.levelNumber,
                    themeName: gameState.level.themeName,
                    snacks: LevelTheme.forLevel(gameState.level.levelNumber).snacks.map(\.emoji)
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
                    onPrimary: { afterInterstitial(onReplay) },
                    onReplay: { afterInterstitial(onReplay) },
                    onMap: { afterInterstitial(onExit) },
                    onMainMenu: { afterInterstitial(onMainMenu) }
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
                onLevelWon(stars)
                Task { await submit(score: score, stars: stars, won: true) }
            case .lost(let score):
                didSubmitResult = true
                onLevelLost()
                Task { await submit(score: score, stars: 0, won: false) }
            case .playing, .timedOut:
                break
            }
        }
        .onAppear {
            didSubmitResult = false
            submittedRank = nil
            DispatchQueue.main.async {
                configureScene()
            }
        }
        .onChange(of: layout) { _, _ in
            DispatchQueue.main.async {
                configureScene()
            }
        }
        .onDisappear {
            gameState.stopTimer()
        }
    }

    // MARK: - Playfields

    /// Transient HUD rows the geometry has to reserve height for, otherwise they
    /// render past the HUD card and sit on top of the board.
    private var hudAccessoryRows: Int {
        (gameState.isFeverActive ? 1 : 0) + (activeBooster == .hammer ? 1 : 0)
    }

    /// Same partition the playfield uses, derived from the window so overlays
    /// outside the playfield's GeometryReader can avoid the chrome.
    private var windowGeometry: PlayfieldGeometry {
        let content = CGSize(
            width: max(1, layout.width - layout.safeArea.leading - layout.safeArea.trailing),
            height: max(1, layout.height - layout.safeArea.top - layout.safeArea.bottom)
        )
        return PlayfieldGeometry.make(
            container: content,
            isLandscape: content.width > content.height + 12,
            isPad: layout.isPad,
            hudAccessoryRows: hudAccessoryRows
        )
    }

    /// Portrait: clear the bottom dock. Landscape: clear the left sidebar.
    private var chromeClearance: EdgeInsets {
        let geometry = windowGeometry
        let content = CGSize(
            width: max(1, layout.width - layout.safeArea.leading - layout.safeArea.trailing),
            height: max(1, layout.height - layout.safeArea.top - layout.safeArea.bottom)
        )
        if geometry.isLandscape {
            return EdgeInsets(
                top: 0,
                leading: geometry.dock.maxX + layout.safeArea.leading,
                bottom: layout.safeArea.bottom,
                trailing: 0
            )
        }
        return EdgeInsets(
            top: 0,
            leading: 0,
            bottom: (content.height - geometry.dock.minY) + layout.safeArea.bottom,
            trailing: 0
        )
    }

    private var playfield: some View {
        GeometryReader { geo in
            placedPlayfield(
                PlayfieldGeometry.make(
                    container: geo.size,
                    isLandscape: geo.size.width > geo.size.height + 12,
                    isPad: layout.isPad,
                    hudAccessoryRows: hudAccessoryRows
                )
            )
        }
        .adaptiveSafeAreaPadding(layout)
    }

    private func placedPlayfield(_ geometry: PlayfieldGeometry) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 4) {
                GameHUD(
                    gameState: gameState,
                    onClose: exitToMap,
                    onPause: { gameState.isPaused = true },
                    chrome: geometry.isLandscape ? .sidebar : .topBar
                )
                hammerBanner
                Spacer(minLength: 0)
            }
            .padding(geometry.isLandscape ? 8 : 4)
            .frame(width: geometry.hud.width, height: geometry.hud.height, alignment: .top)
            // Matches board/dock: chrome can never paint outside its own rect.
            .clipped()
            .offset(x: geometry.hud.minX, y: geometry.hud.minY)

            boardCard
                .frame(width: geometry.board.width, height: geometry.board.height)
                .clipped()
                .offset(x: geometry.board.minX, y: geometry.board.minY)

            // Horizontal in both orientations: the sidebar is wide enough for a
            // 3-up row, and a vertical stack needed more height than the dock has.
            boosterBar(axis: .horizontal, compact: true)
                .frame(width: geometry.dock.width, height: geometry.dock.height)
                .clipped()
                .offset(x: geometry.dock.minX, y: geometry.dock.minY)
        }
    }

    private var boardCard: some View {
        boardView
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .clipped()
    }

    private var boardView: some View {
        SpriteView(
            scene: scene,
            options: [.ignoresSiblingOrder]
        )
        .allowsHitTesting(gameState.outcome == .playing && !gameState.isPaused)
        .onAppear {
            DispatchQueue.main.async { configureScene() }
        }
    }

    @ViewBuilder
    private var hammerBanner: some View {
        if activeBooster == .hammer {
            HStack(spacing: 10) {
                Text("🔨 TAP A TILE!")
                    .font(.system(size: layout.isCompactHeight ? 11 : 13, weight: .black, design: .rounded))
                    .foregroundStyle(SSATheme.candyYellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.75)))
            .padding(.top, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func boosterBar(axis: Axis, compact: Bool) -> some View {
        BoosterBarView(
            gameState: gameState,
            activeBooster: $activeBooster,
            axis: axis,
            compact: compact,
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
    }

    /// Level transitions are the interstitial slot. The service returns
    /// immediately when Remove Ads is owned, when the cadence has not come
    /// round, or when nothing is loaded — navigation is never blocked on an ad.
    private func afterInterstitial(_ action: @escaping () -> Void) {
        gameState.stopTimer()
        InterstitialAdService.shared.showIfEligible { action() }
    }

    private func exitToMap() {
        gameState.stopTimer()
        onExit()
    }

    private func configureScene() {
        LayoutMetrics.sync(from: layout)
        scene.configure(with: gameState)
        if let view = scene.view {
            let bounds = view.bounds.size
            if bounds.width > 1, bounds.height > 1 {
                scene.size = bounds
            }
        }
        // Keep tiles inside the rounded clip so the first row is never shaved off.
        let margin = max(18, layout.boardMargin)
        scene.playfieldInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        scene.maxTileSize = layout.maxTileSize
        scene.rebuildBoard()
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

    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            AdaptiveModalCard {
            VStack(spacing: layout.isCompactHeight ? 12 : 18) {
                Text("⏰")
                    .font(.system(size: layout.overlayEmojiSize))
                Text("Time's Up!")
                    .font(.system(size: layout.overlayTitleFont, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                Text("Keep playing with +\(extensionSeconds) seconds")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

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
            .frame(maxWidth: .infinity)
            }
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
            AdaptiveModalCard {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("Paused")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
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
            .frame(maxWidth: .infinity)
            }
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
    /// Level identity for the shareable card; defaults keep previews simple.
    var level: Int = 1
    var themeName: String = ""
    var snacks: [String] = []
    @State private var showPrize = false
    @State private var shareImage: ShareableWin?
    @State private var challengeFailed = false
    @StateObject private var gameCenter = GameCenterManager.shared
    @StateObject private var profileForShare = PlayerProfile.shared
    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            if won {
                RewardRain()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            AdaptiveModalCard {
            VStack(spacing: 16) {
                SnacklingMascot(
                    expression: won ? .cheer : .sad,
                    size: layout.isCompactHeight ? 56 : (layout.isPad ? 96 : 80),
                    speechBubbleText: won ? "YAY! Level Cleared!" : "Aww, so close! Try again!"
                )

                Text(won ? "Level Complete!" : "Out of Moves")
                    .font(.system(size: layout.overlayTitleFont, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)

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

                if won {
                    socialRow
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
            .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            showPrize = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62).delay(0.08)) {
                showPrize = true
            }
        }
        .alert("Nothing to Challenge With", isPresented: $challengeFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Game Center needs a submitted score before it can send a challenge. Try again in a moment.")
        }
    }

    /// Share the win, or dare a Game Center friend to beat it.
    private var socialRow: some View {
        HStack(spacing: 10) {
            Button {
                SoundManager.shared.playUITap()
                if let image = WinShareCardRenderer.render(
                    level: level,
                    themeName: themeName,
                    stars: stars,
                    score: score,
                    playerName: profileForShare.displayName,
                    snacks: snacks
                ) {
                    shareImage = ShareableWin(image: image)
                }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
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
                Task {
                    let shown = await gameCenter.presentChallenge(
                        for: .highScore,
                        message: "I just scored \(score) on level \(level) of Snack Swap Adventure. Beat that! 🍪"
                    )
                    if !shown { challengeFailed = true }
                }
            } label: {
                Label("Challenge", systemImage: "flag.checkered.2.crossed")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.12))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(OverlayPressButtonStyle())
        }
        .sheet(item: $shareImage) { win in
            ShareSheet(items: [win.image, "I just cleared level \(level) of Snack Swap Adventure!"])
        }
    }
}

/// Wraps the rendered card so `.sheet(item:)` can drive presentation.
struct ShareableWin: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// UIActivityViewController bridge — SwiftUI's ShareLink cannot carry a
/// freshly rendered UIImage without writing it to disk first.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
