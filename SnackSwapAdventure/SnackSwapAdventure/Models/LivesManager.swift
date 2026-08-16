import Foundation
import SwiftUI

/// Pure regeneration maths, kept free of storage and clocks so the rules can be
/// tested directly — including the cases that hand out free lives if they are
/// wrong.
enum LivesRegen {
    struct Result: Equatable {
        /// Lives after applying elapsed time.
        let lives: Int
        /// When the next life lands, or nil once full.
        let anchor: Date?
    }

    /// - Parameter anchor: the moment the current life started regenerating.
    static func apply(
        lives: Int,
        anchor: Date?,
        now: Date,
        maxLives: Int,
        interval: TimeInterval
    ) -> Result {
        let clamped = max(0, min(maxLives, lives))
        guard clamped < maxLives else { return Result(lives: maxLives, anchor: nil) }
        guard let anchor, interval > 0 else {
            return Result(lives: clamped, anchor: now)
        }

        let elapsed = now.timeIntervalSince(anchor)
        // The device clock moved backwards. Re-anchor rather than banking
        // negative progress, which would otherwise stall regeneration forever.
        guard elapsed >= 0 else { return Result(lives: clamped, anchor: now) }

        let earned = Int(elapsed / interval)
        guard earned > 0 else { return Result(lives: clamped, anchor: anchor) }

        let gained = min(earned, maxLives - clamped)
        let newLives = clamped + gained
        if newLives >= maxLives {
            return Result(lives: maxLives, anchor: nil)
        }
        // Carry the remainder so partial progress is never lost.
        return Result(lives: newLives, anchor: anchor.addingTimeInterval(Double(gained) * interval))
    }
}

/// Lives gate play and are the main sink for stars. Regeneration is wall-clock
/// based: a player who moves their device clock forward can still hurry it
/// along, which needs a trusted time source to close properly.
@MainActor
final class LivesManager: ObservableObject {
    static let shared = LivesManager()

    static let maxLives = 5
    static let regenInterval: TimeInterval = 30 * 60
    /// Cost of an immediate full refill.
    static let refillStarCost = 20

    private enum Keys {
        static let lives = "ssa.lives"
        static let anchor = "ssa.livesAnchor"
    }

    @Published private(set) var lives: Int = LivesManager.maxLives
    @Published private(set) var nextLifeAt: Date?
    /// Extra capacity earned from fully evolved Snacklings.
    @Published private(set) var bonusMaxLives: Int = 0

    /// Base capacity plus whatever the collection has earned.
    var capacity: Int { Self.maxLives + bonusMaxLives }

    private let defaults = UserDefaults.standard

    private init() {
        if defaults.object(forKey: Keys.lives) == nil {
            lives = Self.maxLives
            nextLifeAt = nil
            persist()
        } else {
            lives = max(0, defaults.integer(forKey: Keys.lives))
            let stamp = defaults.double(forKey: Keys.anchor)
            nextLifeAt = stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
        }
        refresh()
    }

    var isFull: Bool { lives >= capacity }
    var hasLife: Bool { lives > 0 }

    /// Seconds until the next life, or nil when full.
    func secondsUntilNextLife(now: Date = Date()) -> TimeInterval? {
        guard !isFull, let anchor = nextLifeAt else { return nil }
        return max(0, anchor.addingTimeInterval(Self.regenInterval).timeIntervalSince(now))
    }

    /// Applies any time that has passed. Safe to call as often as you like.
    func refresh(now: Date = Date()) {
        let result = LivesRegen.apply(
            lives: lives,
            anchor: nextLifeAt,
            now: now,
            maxLives: capacity,
            interval: Self.regenInterval
        )
        guard result.lives != lives || result.anchor != nextLifeAt else { return }
        lives = result.lives
        nextLifeAt = result.anchor
        persist()
        syncNotifications()
    }

    /// Spends a life. Returns false when there is none to spend.
    @discardableResult
    func consumeLife(now: Date = Date()) -> Bool {
        refresh(now: now)
        guard lives > 0 else { return false }
        let wasFull = isFull
        lives -= 1
        // Start the clock from this moment when leaving a full tank.
        if wasFull { nextLifeAt = now }
        persist()
        syncNotifications()
        return true
    }

    func grantLife(now: Date = Date()) {
        refresh(now: now)
        guard lives < capacity else { return }
        lives += 1
        if lives >= capacity { nextLifeAt = nil }
        persist()
        syncNotifications()
    }

    func refillAll() {
        lives = capacity
        nextLifeAt = nil
        persist()
        syncNotifications()
    }

    /// Buys a full tank with stars. Returns false when the player is short.
    @discardableResult
    func refillWithStars() -> Bool {
        guard !isFull else { return false }
        guard PlayerProfile.shared.stars >= Self.refillStarCost else { return false }
        PlayerProfile.shared.deductStars(Self.refillStarCost)
        refillAll()
        return true
    }

    /// Raises the ceiling as Snacklings evolve. Extra capacity is granted as
    /// actual lives so the reward is felt immediately rather than as an empty
    /// slot the player has to wait 30 minutes to fill.
    func setBonusMaxLives(_ bonus: Int) {
        let clamped = max(0, min(SnacklingPerks.maxBonusLives, bonus))
        guard clamped != bonusMaxLives else { return }
        let gained = clamped - bonusMaxLives
        bonusMaxLives = clamped
        if gained > 0 { lives = min(capacity, lives + gained) }
        lives = min(lives, capacity)
        if lives >= capacity { nextLifeAt = nil }
        persist()
        syncNotifications()
    }

    /// Used by the iCloud merge, which must not resurrect spent lives.
    func applyMergedState(lives: Int, anchor: Date?) {
        self.lives = max(0, min(capacity, lives))
        self.nextLifeAt = self.lives >= capacity ? nil : anchor
        persist()
        syncNotifications()
    }

    var anchorForSync: Date? { nextLifeAt }

    private func persist() {
        defaults.set(lives, forKey: Keys.lives)
        defaults.set(nextLifeAt?.timeIntervalSince1970 ?? 0, forKey: Keys.anchor)
    }

    private func syncNotifications() {
        let full = secondsUntilFull()
        NotificationScheduler.shared.updateLivesFullReminder(in: full)
    }

    /// Seconds until every life is back, or nil when already full.
    func secondsUntilFull(now: Date = Date()) -> TimeInterval? {
        guard !isFull else { return nil }
        guard let next = secondsUntilNextLife(now: now) else { return nil }
        let remainingAfterNext = capacity - (lives + 1)
        return next + Double(max(0, remainingAfterNext)) * Self.regenInterval
    }
}
