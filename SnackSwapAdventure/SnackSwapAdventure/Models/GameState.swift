import Foundation
import Combine

/// Observable game session state shared between SpriteKit and SwiftUI.
@MainActor
final class GameState: ObservableObject {
    @Published var level: LevelConfig
    @Published var movesLeft: Int
    @Published var timeRemaining: Int
    @Published var score: Int
    @Published var outcome: GameOutcome = .playing
    @Published var comboCount: Int = 0
    @Published var maxComboThisLevel: Int = 0
    @Published var lastFeedMessage: String = "Match snacks to feed the monsters!"
    @Published var monsterMood: MonsterMood = .idle

    /// Goal progress counters
    @Published var collectedOfType: Int = 0
    @Published var snacksCleared: Int = 0
    @Published var combosMade: Int = 0
    @Published var isPaused: Bool = false
    /// How many time extensions used this level (ad or stars).
    @Published var extensionsUsed: Int = 0
    @Published var isTimerUrgent: Bool = false

    let board: BoardModel

    private var timerTask: Task<Void, Never>?

    init(level: LevelConfig = .prototype) {
        self.level = level
        self.movesLeft = level.moves
        self.timeRemaining = level.timeLimit
        self.score = 0
        self.board = BoardModel(size: level.boardSize, snackTypes: level.snackTypes)
    }

    deinit {
        timerTask?.cancel()
    }

    func reset(to level: LevelConfig? = nil) {
        stopTimer()
        if let level {
            self.level = level
        }
        movesLeft = self.level.moves
        timeRemaining = self.level.timeLimit
        score = 0
        outcome = .playing
        comboCount = 0
        maxComboThisLevel = 0
        collectedOfType = 0
        snacksCleared = 0
        combosMade = 0
        isPaused = false
        extensionsUsed = 0
        isTimerUrgent = false
        lastFeedMessage = self.level.goal.detail
        monsterMood = .idle
        board.reset(size: self.level.boardSize, snackTypes: self.level.snackTypes)
        startTimer()
    }

    // MARK: - Timer

    func startTimer() {
        stopTimer()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, !Task.isCancelled else { return }
                await self.tick()
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func tick() {
        guard outcome == .playing, !isPaused else { return }
        timeRemaining = max(0, timeRemaining - 1)
        isTimerUrgent = timeRemaining <= 10
        if timeRemaining <= 10 && timeRemaining > 0 {
            SoundManager.shared.playTimerTick(urgent: timeRemaining <= 5)
        }
        if timeRemaining <= 0 {
            handleTimerExpired()
        }
    }

    private func handleTimerExpired() {
        guard outcome == .playing else { return }
        isPaused = true
        outcome = .timedOut
        monsterMood = .sad
        lastFeedMessage = "Time's up! Watch an ad or spend stars for +30s."
        SoundManager.shared.playTimerExpire()
        stopTimer()
    }

    /// Resume after ad or star purchase.
    @discardableResult
    func extendTime(seconds: Int = LevelConfig.timeExtensionSeconds) -> Bool {
        guard outcome == .timedOut || outcome == .playing else { return false }
        timeRemaining += seconds
        extensionsUsed += 1
        isTimerUrgent = timeRemaining <= 10
        outcome = .playing
        isPaused = false
        lastFeedMessage = "+\(seconds)s! Keep matching!"
        monsterMood = .happy
        SoundManager.shared.playExtend()
        startTimer()
        return true
    }

    /// Decline extend → lose the level.
    func forfeitAfterTimeout() {
        guard outcome == .timedOut else { return }
        outcome = .lost(score: score)
        lastFeedMessage = "Out of time… the monsters are still hungry."
        monsterMood = .sad
        stopTimer()
    }

    func registerSuccessfulSwap() {
        guard outcome == .playing else { return }
        movesLeft = max(0, movesLeft - 1)
    }

    func registerClear(positions: Set<BoardPosition>, cascadeDepth: Int, points: Int) {
        score += points
        snacksCleared += positions.count
        comboCount = cascadeDepth + 1
        maxComboThisLevel = max(maxComboThisLevel, comboCount)
        if cascadeDepth >= 1 {
            combosMade += 1
        }

        if cascadeDepth >= 2 {
            monsterMood = .ecstatic
            lastFeedMessage = "COMBO x\(comboCount)! The monsters are thrilled!"
        } else if cascadeDepth >= 1 {
            monsterMood = .happy
            lastFeedMessage = "Yummy chain reaction!"
        } else {
            monsterMood = .happy
            lastFeedMessage = "Nom nom! +\(points)"
        }

        evaluateOutcome()
    }

    func countCollected(type: SnackType, amount: Int) {
        if case .collect(let goalType, _) = level.goal, goalType == type {
            collectedOfType += amount
        }
    }

    func addScore(_ points: Int, cascadeDepth: Int) {
        score += points
        comboCount = cascadeDepth + 1
        maxComboThisLevel = max(maxComboThisLevel, comboCount)
        if cascadeDepth >= 1 { combosMade += 1 }
        if cascadeDepth >= 2 {
            monsterMood = .ecstatic
            lastFeedMessage = "COMBO x\(comboCount)!"
        } else {
            monsterMood = .happy
            lastFeedMessage = "Nom nom! +\(points)"
        }
        evaluateOutcome()
    }

    func registerInvalidSwap() {
        monsterMood = .sad
        lastFeedMessage = "Hmm… try a better swap!"
    }

    var goalProgressValue: Int {
        switch level.goal {
        case .score: return score
        case .collect: return collectedOfType
        case .clearSnacks: return snacksCleared
        case .makeCombos: return combosMade
        }
    }

    var goalMet: Bool {
        goalProgressValue >= level.progressDenominator
    }

    var timerProgress: Double {
        min(1.0, Double(timeRemaining) / Double(max(level.timeLimit, 1)))
    }

    var formattedTime: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    func evaluateOutcome() {
        guard outcome == .playing else { return }

        if goalMet {
            stopTimer()
            let stars: Int
            let remainingMoves = Double(movesLeft) / Double(max(level.moves, 1))
            let remainingTime = Double(timeRemaining) / Double(max(level.timeLimit, 1))
            let blend = (remainingMoves + remainingTime) / 2
            if blend >= 0.4 {
                stars = 3
            } else if blend >= 0.15 {
                stars = 2
            } else {
                stars = 1
            }
            outcome = .won(stars: stars, score: score)
            monsterMood = .ecstatic
            lastFeedMessage = "Level complete! ★\(stars)"
            PlayerProfile.shared.awardLevelWin(
                level: level.levelNumber,
                stars: stars,
                score: score,
                coins: 20 + stars * 15 + score / 100
            )
            MetaProgress.shared.addStars(stars * 3 + 2)
        } else if movesLeft <= 0 {
            stopTimer()
            outcome = .lost(score: score)
            monsterMood = .sad
            lastFeedMessage = "Out of moves… the monsters are still hungry."
        }
    }

    var progress: Double {
        min(1.0, Double(goalProgressValue) / Double(level.progressDenominator))
    }
}

enum MonsterMood: Equatable {
    case idle, happy, ecstatic, sad

    var emoji: String {
        switch self {
        case .idle: return "👾"
        case .happy: return "😋"
        case .ecstatic: return "🤩"
        case .sad: return "🥺"
        }
    }
}
