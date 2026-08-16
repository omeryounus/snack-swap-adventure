import Foundation
import UserNotifications

/// Local notifications only — no server, no APNs, no device tokens.
///
/// Authorization is deliberately not requested at launch: the prompt is asked
/// for at the first moment it makes sense to the player (running out of lives),
/// which is also when a reminder is actually worth something.
@MainActor
final class NotificationScheduler: ObservableObject {
    static let shared = NotificationScheduler()

    private enum Identifiers {
        static let livesFull = "ssa.notification.livesFull"
        static let dailyReward = "ssa.notification.dailyReward"
    }

    @Published private(set) var isAuthorized = false
    private var hasCheckedStatus = false

    private init() {}

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
        hasCheckedStatus = true
    }

    /// Asks once. Returns the current state without re-prompting if the player
    /// has already answered — iOS only shows the system prompt once anyway.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        if !hasCheckedStatus { await refreshAuthorizationStatus() }
        if isAuthorized { return true }

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return isAuthorized }

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    /// Schedules (or clears) the "lives are full" reminder.
    func updateLivesFullReminder(in seconds: TimeInterval?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Identifiers.livesFull])

        guard let seconds, seconds > 1, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Lives refilled! ❤️"
        content.body = "All \(LivesManager.maxLives) lives are back. Time for another run?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.add(UNNotificationRequest(identifier: Identifiers.livesFull, content: content, trigger: trigger))
    }

    /// A single next-day nudge for the daily reward streak.
    func scheduleDailyRewardReminder(hour: Int = 18) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Identifiers.dailyReward])
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your daily snack is waiting 🍪"
        content.body = "Collect today's reward before the streak resets."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: Identifiers.dailyReward, content: content, trigger: trigger))
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
