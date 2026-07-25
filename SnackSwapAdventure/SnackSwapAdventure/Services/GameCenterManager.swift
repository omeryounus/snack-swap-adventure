import Foundation
import GameKit

/// GameKit authentication & Apple Game Center leaderboard submission manager.
@MainActor
final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var localPlayerName = "Player"

    override private init() {
        super.init()
    }

    func authenticateLocalPlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if GKLocalPlayer.local.isAuthenticated {
                self.isAuthenticated = true
                self.localPlayerName = GKLocalPlayer.local.alias
                print("GameCenterManager: Authenticated as \(GKLocalPlayer.local.alias)")
            } else if let error {
                print("GameCenterManager: Auth error - \(error.localizedDescription)")
                self.isAuthenticated = false
            }
        }
    }

    func submitScore(_ score: Int, leaderboardID: String = "com.snackswap.leaderboard.highscore") {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error {
                print("GameCenterManager: Failed to submit score \(score) - \(error.localizedDescription)")
            } else {
                print("GameCenterManager: Successfully submitted score \(score) to Game Center!")
            }
        }
    }
}
