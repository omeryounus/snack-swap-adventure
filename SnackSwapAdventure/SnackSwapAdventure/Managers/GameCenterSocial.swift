import Foundation
import GameKit
import UIKit

/// One row of a friends-scoped leaderboard.
struct FriendRankEntry: Identifiable, Equatable {
    let id: String
    let displayName: String
    let rank: Int
    let score: Int
    let formattedScore: String
    let isLocalPlayer: Bool
}

/// Friend-facing Game Center features: a friends-only leaderboard, and the
/// system challenge composer. Everything here needs an authenticated local
/// player, and friends data additionally needs the player to allow friend
/// access, so each entry point degrades to an explanatory message rather than
/// an empty list.
extension GameCenterManager {

    enum FriendsBoard: String, CaseIterable, Identifiable {
        case highScore
        case highestLevel
        case totalStars

        var id: String { rawValue }

        var leaderboardID: String {
            switch self {
            case .highScore: return Leaderboards.highScore
            case .highestLevel: return Leaderboards.highestLevel
            case .totalStars: return Leaderboards.totalStars
            }
        }

        var title: String {
            switch self {
            case .highScore: return "High Score"
            case .highestLevel: return "Level"
            case .totalStars: return "Stars"
            }
        }
    }

    /// Loads the friends-only scope for `board`, newest first.
    func loadFriendsLeaderboard(_ board: FriendsBoard) async {
        guard isAuthenticated else {
            friendEntries = []
            friendsMessage = "Sign in to Game Center to see how you rank against friends."
            return
        }

        isLoadingFriends = true
        defer { isLoadingFriends = false }

        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: [board.leaderboardID])
            guard let leaderboard = boards.first else {
                friendEntries = []
                friendsMessage = "That leaderboard isn't set up in App Store Connect yet."
                return
            }

            let (localEntry, entries, _) = try await leaderboard.loadEntries(
                for: .friendsOnly,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 25)
            )

            let localID = GKLocalPlayer.local.gamePlayerID
            var rows = entries.map { entry in
                FriendRankEntry(
                    id: entry.player.gamePlayerID,
                    displayName: entry.player.displayName,
                    rank: entry.rank,
                    score: entry.score,
                    formattedScore: entry.formattedScore,
                    isLocalPlayer: entry.player.gamePlayerID == localID
                )
            }

            // The friends scope sometimes omits the local player; keep them in
            // so the list always answers "where am I?".
            if let localEntry, !rows.contains(where: { $0.isLocalPlayer }) {
                rows.append(
                    FriendRankEntry(
                        id: localEntry.player.gamePlayerID,
                        displayName: localEntry.player.displayName,
                        rank: localEntry.rank,
                        score: localEntry.score,
                        formattedScore: localEntry.formattedScore,
                        isLocalPlayer: true
                    )
                )
            }

            friendEntries = rows.sorted { $0.rank < $1.rank }
            friendsMessage = friendEntries.isEmpty
                ? "No friends playing yet — invite someone and their scores show up here."
                : nil
        } catch {
            friendEntries = []
            friendsMessage = "Couldn't load friends: \(error.localizedDescription)"
        }
    }

    /// Presents Game Center's own challenge sheet for the player's score on
    /// `board`. Returns false when there is nothing to challenge with yet.
    @discardableResult
    func presentChallenge(for board: FriendsBoard, message: String) async -> Bool {
        guard isAuthenticated else { return false }
        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: [board.leaderboardID])
            guard let leaderboard = boards.first else { return false }

            let (localEntry, _) = try await leaderboard.loadEntries(
                for: [GKLocalPlayer.local],
                timeScope: .allTime
            )
            guard let localEntry else { return false }
            guard let root = Self.topViewController() else { return false }

            let composer = localEntry.challengeComposeController(
                withMessage: message,
                players: [],
                completionHandler: { viewController, _, _ in
                    viewController.dismiss(animated: true)
                }
            )
            root.present(composer, animated: true)
            return true
        } catch {
            print("[GameCenter] challenge compose failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Count of challenges friends have sent that are still outstanding.
    func refreshReceivedChallengeCount() async {
        guard isAuthenticated else {
            receivedChallengeCount = 0
            return
        }
        do {
            let challenges = try await GKChallenge.loadReceivedChallenges()
            receivedChallengeCount = challenges.filter { $0.state == .invalid || $0.state == .pending }.count
        } catch {
            receivedChallengeCount = 0
        }
    }

    static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene?.windows.first?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
