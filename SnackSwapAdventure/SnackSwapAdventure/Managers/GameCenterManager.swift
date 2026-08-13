import Foundation
import GameKit
import SwiftUI

/// Manages Apple Game Center authentication, leaderboards, and achievements.
@MainActor
final class GameCenterManager: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var localPlayerName = ""
    @Published var authError: String?

    struct Leaderboards {
        static let highestLevel = "snackswap.highest_level"
        static let highScore = "snackswap.high_score"
        static let totalStars = "snackswap.total_stars"
    }

    struct Achievements {
        static let firstWin = "snackswap.first_win"
        static let level10 = "snackswap.level_10"
        static let combo5 = "snackswap.combo_5"
        static let boosterMaster = "snackswap.booster_master"
    }

    private override init() {
        super.init()
    }

    func authenticateLocalPlayer() {
        authenticatePlayer()
    }

    /// Authenticate the local Game Center player
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, error in
            Task { @MainActor in
                if let error = error {
                    self?.authError = error.localizedDescription
                    self?.isAuthenticated = false
                    return
                }

                if let vc = vc {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard let windowScene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first(where: { $0.activationState == .foregroundActive })
                        ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
                          let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                            ?? windowScene.windows.first?.rootViewController
                    else { return }
                    if rootVC.presentedViewController == nil {
                        rootVC.present(vc, animated: true)
                    }
                    return
                }

                if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.localPlayerName = GKLocalPlayer.local.displayName
                    self?.authError = nil
                    print("[GameCenter] Authenticated as \(GKLocalPlayer.local.displayName)")
                } else {
                    self?.isAuthenticated = false
                }
            }
        }
    }

    /// Submit level & high score to Game Center leaderboards
    func reportScore(score: Int, level: Int, totalStars: Int) {
        guard isAuthenticated else { return }

        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [Leaderboards.highScore]) { error in
            if let error = error {
                print("[GameCenter] Failed to submit score: \(error.localizedDescription)")
            }
        }

        GKLeaderboard.submitScore(level, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [Leaderboards.highestLevel]) { _ in }
        GKLeaderboard.submitScore(totalStars, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [Leaderboards.totalStars]) { _ in }
    }

    /// Check and unlock relevant achievements based on gameplay stats
    func checkAchievements(level: Int, won: Bool, maxCombo: Int, hammerCount: Int) {
        guard isAuthenticated else { return }

        var achievementsToReport: [GKAchievement] = []

        if won {
            let firstWinAcc = GKAchievement(identifier: Achievements.firstWin)
            firstWinAcc.percentComplete = 100.0
            firstWinAcc.showsCompletionBanner = true
            achievementsToReport.append(firstWinAcc)
        }

        if level >= 10 {
            let level10Acc = GKAchievement(identifier: Achievements.level10)
            level10Acc.percentComplete = 100.0
            level10Acc.showsCompletionBanner = true
            achievementsToReport.append(level10Acc)
        }

        if maxCombo >= 5 {
            let combo5Acc = GKAchievement(identifier: Achievements.combo5)
            combo5Acc.percentComplete = 100.0
            combo5Acc.showsCompletionBanner = true
            achievementsToReport.append(combo5Acc)
        }

        if hammerCount >= 5 {
            let boosterAcc = GKAchievement(identifier: Achievements.boosterMaster)
            boosterAcc.percentComplete = 100.0
            boosterAcc.showsCompletionBanner = true
            achievementsToReport.append(boosterAcc)
        }

        if !achievementsToReport.isEmpty {
            GKAchievement.report(achievementsToReport) { error in
                if let error = error {
                    print("[GameCenter] Failed to report achievements: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Present Game Center Overlay Dashboard
    func showDashboard(state: GKGameCenterViewControllerState = .default) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let gcVC = GKGameCenterViewController(state: state)
        gcVC.gameCenterDelegate = self
        rootVC.present(gcVC, animated: true)
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
