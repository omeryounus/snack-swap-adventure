import SwiftUI

enum AppScreen: Equatable {
    case splash
    case title
    case worldMap
    case playing
    case leaderboard
    case stats
    case monsters
    case shop
    case invite
    case settings
}

struct ContentView: View {
    @StateObject private var gameState = GameState(level: LevelConfig.level(1))
    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared
    @State private var screen: AppScreen = .splash
    @State private var sceneID = UUID()
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var lives = LivesManager.shared
    @State private var showOutOfLives = false
    /// The level the player tried to start with an empty tank.
    @State private var pendingLevel: Int?
    @State private var isWatchingLifeAd = false

    var body: some View {
        AdaptiveRoot {
            ZStack {
                screenStack

                if showOutOfLives {
                    OutOfLivesOverlay(
                        onWatchAd: { watchAdForLife() },
                        onSpendStars: { spendStarsForLives() },
                        onClose: { dismissOutOfLives() }
                    )
                    .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(SSATheme.bgVoid.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.28), value: screen)
        .task {
            await profile.ensureRegistered()
            meta.refreshMonsterUnlocks(maxLevel: profile.maxUnlockedLevel)
            iCloudSyncManager.shared.startSync()
            SnacklingKeeper.shared.applyPerks()
            if meta.musicEnabled {
                MusicPlayer.shared.play()
            }
            SoundManager.shared.setEnabled(meta.soundEnabled)
        }
        .onChange(of: screen) { _, newScreen in
            MusicPlayer.shared.updateBGM(forScreen: newScreen, levelNumber: gameState.level.levelNumber)
        }
        .onChange(of: gameState.level.levelNumber) { _, newLevel in
            MusicPlayer.shared.updateBGM(forScreen: screen, levelNumber: newLevel)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                if screen == .playing {
                    gameState.isPaused = true
                    gameState.stopTimer()
                }
            } else if newPhase == .active {
                if screen == .playing && gameState.outcome == .playing && !gameState.isPaused {
                    gameState.startTimer()
                }
            }
        }
    }

    @ViewBuilder
    private var screenStack: some View {
        ZStack(alignment: .top) {
            switch screen {
            case .splash:
                SplashView(onFinished: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        screen = .title
                    }
                })
                .transition(.opacity)

            case .title:
                TitleView(
                    onPlay: { startLevel(min(profile.maxUnlockedLevel, LevelConfig.totalLevels)) },
                    onWorldMap: { screen = .worldMap },
                    onLeaderboard: { screen = .leaderboard },
                    onStats: { screen = .stats },
                    onMonsters: { screen = .monsters },
                    onShop: { screen = .shop },
                    onInvite: { screen = .invite },
                    onSettings: { screen = .settings }
                )
                .transition(.opacity)

            case .worldMap:
                WorldMapView(
                    maxUnlockedLevel: profile.maxUnlockedLevel,
                    onSelectLevel: { startLevel($0) },
                    onBack: { screen = .title }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))

            case .playing:
                GameContainerView(
                    gameState: gameState,
                    onExit: {
                        gameState.stopTimer()
                        screen = .worldMap
                    },
                    onNextLevel: {
                        let next = min(LevelConfig.totalLevels, gameState.level.levelNumber + 1)
                        profile.unlockLevel(next)
                        startLevel(next)
                    },
                    onReplay: {
                        startLevel(gameState.level.levelNumber)
                    },
                    onMainMenu: {
                        gameState.stopTimer()
                        screen = .title
                    },
                    onLevelLost: { consumeLifeForLoss() },
                    onLevelWon: { stars in
                        SnacklingKeeper.shared.awardLevelReward(
                            level: gameState.level.levelNumber,
                            stars: stars
                        )
                    }
                )
                .id(sceneID)
                .transition(.opacity)

            case .leaderboard:
                LeaderboardView(onBack: { screen = .title })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .stats:
                StatsView(onBack: { screen = .title })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .monsters:
                MonstersView(onBack: { screen = .title })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .shop:
                ShopView(onBack: { screen = .title })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .invite:
                InviteView(onBack: { screen = .title })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .settings:
                SettingsView(onBack: { screen = .title })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func startLevel(_ number: Int) {
        // Lives gate entry, not completion: losing costs one, winning is free.
        lives.refresh()
        guard lives.hasLife else {
            pendingLevel = number
            showOutOfLives = true
            return
        }
        let config = LevelConfig.level(number)
        let boosters = meta.consumePendingBoosters()
        var extraMoves = 0
        var extraTime = 0
        for b in boosters {
            if b == "moves" { extraMoves += 5 }
            if b == "time" { extraTime += 30 }
        }
        // Drop the previous level's payout so the win card cannot show a stale one.
        SnacklingKeeper.shared.clearLastReward()
        gameState.reset(to: config)
        // Grown Snacklings pay back into play.
        let perkMoves = SnacklingKeeper.shared.currentPerks.bonusMoves
        if perkMoves > 0 {
            gameState.movesLeft += perkMoves
        }
        if extraMoves > 0 {
            gameState.movesLeft += extraMoves
        }
        if extraTime > 0 {
            gameState.timeRemaining += extraTime
        }
        if boosters.contains("hammer") {
            let target = BoardPosition(row: config.boardSize / 2, col: config.boardSize / 2)
            gameState.board.clear([target])
            _ = gameState.board.applyGravity()
            _ = gameState.board.refill()
            if !gameState.board.findMatches().isEmpty {
                _ = gameState.board.reshuffleToPlayable()
            }
            gameState.lastFeedMessage = "Snack Hammer bonus! One snack smashed!"
        }
        if boosters.contains("shuffle") {
            gameState.board.fillWithoutInitialMatches()
        }
        sceneID = UUID()
        screen = .playing
    }

    // MARK: - Lives

    /// Retries the level the player was blocked from, once a life arrives.
    private func resumePendingLevel() {
        showOutOfLives = false
        guard let number = pendingLevel else { return }
        pendingLevel = nil
        startLevel(number)
    }

    private func dismissOutOfLives() {
        showOutOfLives = false
        pendingLevel = nil
    }

    private func watchAdForLife() {
        guard !isWatchingLifeAd else { return }
        isWatchingLifeAd = true
        RewardedAdService.shared.show { earned in
            Task { @MainActor in
                isWatchingLifeAd = false
                guard earned else { return }
                lives.grantLife()
                resumePendingLevel()
            }
        }
    }

    private func spendStarsForLives() {
        SoundManager.shared.playUITap()
        guard lives.refillWithStars() else { return }
        resumePendingLevel()
    }

    /// A life is spent on failure, so a win never costs anything.
    private func consumeLifeForLoss() {
        lives.consumeLife()
        Task {
            // Ask for notification permission at the first moment a reminder is
            // actually worth something to the player.
            if await NotificationScheduler.shared.requestAuthorizationIfNeeded() {
                NotificationScheduler.shared.updateLivesFullReminder(in: lives.secondsUntilFull())
                NotificationScheduler.shared.scheduleDailyRewardReminder()
            }
        }
    }
}

#Preview {
    ContentView()
}
