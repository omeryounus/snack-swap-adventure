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

    var body: some View {
        AdaptiveRoot {
            screenStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(SSATheme.bgVoid.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.28), value: screen)
        .task {
            await profile.ensureRegistered()
            meta.refreshMonsterUnlocks(maxLevel: profile.maxUnlockedLevel)
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
        let config = LevelConfig.level(number)
        let boosters = meta.consumePendingBoosters()
        var extraMoves = 0
        var extraTime = 0
        for b in boosters {
            if b == "moves" { extraMoves += 5 }
            if b == "time" { extraTime += 30 }
        }
        gameState.reset(to: config)
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
}

#Preview {
    ContentView()
}
