import Foundation
import Combine

/// Manages cross-device iCloud synchronization using NSUbiquitousKeyValueStore.
@MainActor
final class iCloudSyncManager: ObservableObject {
    static let shared = iCloudSyncManager()

    private let kvStore = NSUbiquitousKeyValueStore.default
    private var cancellables = Set<AnyCancellable>()

    private enum Keys {
        static let maxUnlockedLevel = "cloud.maxUnlockedLevel"
        static let highScore = "cloud.highScore"
        static let totalStars = "cloud.totalStars"
        static let hammerCount = "cloud.hammerCount"
        static let colorBombCount = "cloud.colorBombCount"
        static let extraMovesCount = "cloud.extraMovesCount"
    }

    private init() {
        setupObservers()
    }

    /// Start listening for external iCloud changes and trigger initial sync
    func startSync() {
        kvStore.synchronize()
        pullFromiCloud()
    }

    /// Push local profile progress to iCloud
    func pushToiCloud() {
        let profile = PlayerProfile.shared
        kvStore.set(Int64(profile.maxUnlockedLevel), forKey: Keys.maxUnlockedLevel)
        kvStore.set(Int64(profile.localHighScore), forKey: Keys.highScore)
        kvStore.set(Int64(profile.localStars), forKey: Keys.totalStars)
        kvStore.set(Int64(profile.hammerCount), forKey: Keys.hammerCount)
        kvStore.set(Int64(profile.colorBombCount), forKey: Keys.colorBombCount)
        kvStore.set(Int64(profile.extraMovesCount), forKey: Keys.extraMovesCount)

        kvStore.synchronize()
    }

    /// Pull remote iCloud progress and merge safely (keeping highest level/score/stars)
    func pullFromiCloud() {
        let profile = PlayerProfile.shared

        let cloudLevel = Int(kvStore.longLong(forKey: Keys.maxUnlockedLevel))
        let cloudHighScore = Int(kvStore.longLong(forKey: Keys.highScore))
        let cloudStars = Int(kvStore.longLong(forKey: Keys.totalStars))
        let cloudHammers = Int(kvStore.longLong(forKey: Keys.hammerCount))
        let cloudBombs = Int(kvStore.longLong(forKey: Keys.colorBombCount))
        let cloudMoves = Int(kvStore.longLong(forKey: Keys.extraMovesCount))

        if cloudLevel > profile.maxUnlockedLevel {
            profile.unlockLevel(cloudLevel)
        }

        if cloudHighScore > profile.localHighScore {
            profile.localHighScore = cloudHighScore
        }

        if cloudStars > profile.localStars {
            profile.localStars = cloudStars
        }

        if cloudHammers > profile.hammerCount {
            profile.hammerCount = cloudHammers
        }

        if cloudBombs > profile.colorBombCount {
            profile.colorBombCount = cloudBombs
        }

        if cloudMoves > profile.extraMovesCount {
            profile.extraMovesCount = cloudMoves
        }
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.pullFromiCloud()
            }
            .store(in: &cancellables)
    }
}
