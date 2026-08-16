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
        // No iCloud entitlement in this target — touching the default store
        // can terminate on device. Only use it when a ubiquity identity exists.
        guard FileManager.default.ubiquityIdentityToken != nil else { return nil }
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
        static let lives = "cloud.lives"
        static let livesAnchor = "cloud.livesAnchor"
        static let updatedAt = "cloud.updatedAt"
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
        store.set(Int64(LivesManager.shared.lives), forKey: Keys.lives)
        store.set(LivesManager.shared.anchorForSync?.timeIntervalSince1970 ?? 0, forKey: Keys.livesAnchor)
        // Stamps this device as the most recent writer, which is what decides
        // spendable balances on the next merge.
        let now = Date().timeIntervalSince1970
        store.set(now, forKey: Keys.updatedAt)
        lastLocalWriteAt = now

        store.synchronize()
    }

    /// Merge policy depends on what the value means.
    ///
    /// Records only ever go up, so `max` is right for them. Spendable balances
    /// are not records: taking the maximum meant every spend was undone by the
    /// next sync, which handed out free stars, boosters and lives. Those follow
    /// the most recently written device instead.
    func pullFromiCloud() {
        guard let store = kvStore else { return }
        let profile = PlayerProfile.shared

        // Records — highest wins.
        let cloudLevel = Int(store.longLong(forKey: Keys.maxUnlockedLevel))
        let cloudHighScore = Int(store.longLong(forKey: Keys.highScore))
        if cloudLevel > profile.maxUnlockedLevel {
            profile.unlockLevel(cloudLevel)
        }
        if cloudHighScore > profile.localHighScore {
            profile.localHighScore = cloudHighScore
        }

        // Balances — newest writer wins, and only if the cloud copy is newer
        // than this device's last local change.
        let cloudUpdatedAt = store.double(forKey: Keys.updatedAt)
        guard cloudUpdatedAt > lastLocalWriteAt else { return }

        profile.localStars = max(0, Int(store.longLong(forKey: Keys.totalStars)))
        profile.hammerCount = max(0, Int(store.longLong(forKey: Keys.hammerCount)))
        profile.colorBombCount = max(0, Int(store.longLong(forKey: Keys.colorBombCount)))
        profile.extraMovesCount = max(0, Int(store.longLong(forKey: Keys.extraMovesCount)))

        let anchorStamp = store.double(forKey: Keys.livesAnchor)
        LivesManager.shared.applyMergedState(
            lives: Int(store.longLong(forKey: Keys.lives)),
            anchor: anchorStamp > 0 ? Date(timeIntervalSince1970: anchorStamp) : nil
        )
        lastLocalWriteAt = cloudUpdatedAt
    }

    /// When this device last wrote a balance, so an older cloud snapshot cannot
    /// overwrite a newer local spend.
    private var lastLocalWriteAt: Double {
        get { UserDefaults.standard.double(forKey: "ssa.cloud.lastLocalWriteAt") }
        set { UserDefaults.standard.set(newValue, forKey: "ssa.cloud.lastLocalWriteAt") }
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
