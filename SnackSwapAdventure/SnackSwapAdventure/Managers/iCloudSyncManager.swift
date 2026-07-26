import Foundation
import Combine

/// Manages cross-device iCloud synchronization using NSUbiquitousKeyValueStore.
@MainActor
final class iCloudSyncManager: ObservableObject {
    static let shared = iCloudSyncManager()

    private var kvStore: NSUbiquitousKeyValueStore? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return NSUbiquitousKeyValueStore.default
        #endif
    }

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
        guard let store = kvStore else { return }
        store.synchronize()
        pullFromiCloud()
    }

    /// Push local profile progress to iCloud
    func pushToiCloud() {
        guard let store = kvStore else { return }
        let profile = PlayerProfile.shared
        store.set(Int64(profile.maxUnlockedLevel), forKey: Keys.maxUnlockedLevel)
        store.set(Int64(profile.localHighScore), forKey: Keys.highScore)
        store.set(Int64(profile.localStars), forKey: Keys.totalStars)
        store.set(Int64(profile.hammerCount), forKey: Keys.hammerCount)
        store.set(Int64(profile.colorBombCount), forKey: Keys.colorBombCount)
        store.set(Int64(profile.extraMovesCount), forKey: Keys.extraMovesCount)

        store.synchronize()
    }

    /// Pull remote iCloud progress and merge safely (keeping highest level/score/stars)
    func pullFromiCloud() {
        guard let store = kvStore else { return }
        let profile = PlayerProfile.shared

        let cloudLevel = Int(store.longLong(forKey: Keys.maxUnlockedLevel))
        let cloudHighScore = Int(store.longLong(forKey: Keys.highScore))
        let cloudStars = Int(store.longLong(forKey: Keys.totalStars))
        let cloudHammers = Int(store.longLong(forKey: Keys.hammerCount))
        let cloudBombs = Int(store.longLong(forKey: Keys.colorBombCount))
        let cloudMoves = Int(store.longLong(forKey: Keys.extraMovesCount))

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
        #if !targetEnvironment(simulator)
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.pullFromiCloud()
            }
            .store(in: &cancellables)
        #endif
    }
}
