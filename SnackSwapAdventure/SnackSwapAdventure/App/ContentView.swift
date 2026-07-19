import SwiftUI

enum AppScreen: Equatable {
    case title
    case worldMap
    case playing
    case leaderboard
    case stats
    case monsters
    case shop
    case invite
}

struct ContentView: View {
    @StateObject private var gameState = GameState(level: .level(1))
    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared
    @State private var screen: AppScreen = .title
    @State private var sceneID = UUID()

    var body: some View {
        Group {
            switch screen {
            case .title:
                TitleView(
                    onPlay: { startLevel(min(profile.maxUnlockedLevel, LevelConfig.totalLevels)) },
                    onWorldMap: { screen = .worldMap },
                    onLeaderboard: { screen = .leaderboard },
                    onStats: { screen = .stats },
                    onMonsters: { screen = .monsters },
                    onShop: { screen = .shop },
                    onInvite: { screen = .invite }
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
                    }
                )
                .id(sceneID)
                .transition(.opacity)

            case .leaderboard:
                LeaderboardView(onBack: { screen = .title })
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .stats:
                StatsView(onBack: { screen = .title })
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .monsters:
                MonstersView(onBack: { screen = .title })
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .shop:
                ShopView(onBack: { screen = .title })
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .invite:
                InviteView(onBack: { screen = .title })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: screen)
        .task {
            await profile.ensureRegistered()
            meta.refreshMonsterUnlocks(maxLevel: profile.maxUnlockedLevel)
            if meta.musicEnabled {
                MusicPlayer.shared.play()
            }
            SoundManager.shared.setEnabled(meta.soundEnabled)
        }
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
            // Apply the queued booster before the scene is rebuilt so the
            // player starts with a real cleared snack, not just a toast.
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
