import Foundation
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Loads and presents rewarded ads for timer extensions.
/// Uses Google Mobile Ads when linked; falls back to a short simulated reward on failure/simulator.
@MainActor
final class RewardedAdService: NSObject, ObservableObject {
    static let shared = RewardedAdService()

    @Published private(set) var isReady = false
    @Published private(set) var isShowing = false
    @Published private(set) var statusMessage = "Ads ready"

    #if canImport(GoogleMobileAds)
    private var rewardedAd: GADRewardedAd?
    #endif

    private var rewardHandler: ((Bool) -> Void)?

    private override init() {
        super.init()
    }

    func start() {
        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start { [weak self] _ in
            Task { @MainActor in
                self?.load()
            }
        }
        #else
        isReady = true
        statusMessage = "Simulated ads (SDK not linked)"
        #endif
    }

    func load() {
        #if canImport(GoogleMobileAds)
        GADRewardedAd.load(
            withAdUnitID: AdConfig.rewardedUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.isReady = AdConfig.allowSimulatedFallback
                    self.statusMessage = "Ad load failed — fallback on"
                    print("RewardedAd load error: \(error.localizedDescription)")
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isReady = true
                self.statusMessage = "Rewarded ad ready"
            }
        }
        #else
        isReady = true
        #endif
    }

    /// Present a rewarded ad. Calls `completion(true)` if the user earned the reward.
    func show(from viewController: UIViewController? = nil, completion: @escaping (Bool) -> Void) {
        rewardHandler = completion

        #if canImport(GoogleMobileAds)
        if let ad = rewardedAd {
            let root = viewController ?? Self.topViewController()
            guard let root else {
                simulateReward(completion: completion)
                return
            }
            isShowing = true
            ad.present(fromRootViewController: root) { [weak self] in
                Task { @MainActor in
                    self?.isShowing = false
                    self?.rewardHandler?(true)
                    self?.rewardHandler = nil
                    self?.rewardedAd = nil
                    self?.load()
                }
            }
            return
        }
        #endif

        if AdConfig.allowSimulatedFallback {
            simulateReward(completion: completion)
        } else {
            completion(false)
        }
    }

    private func simulateReward(completion: @escaping (Bool) -> Void) {
        isShowing = true
        statusMessage = "Simulated ad playing…"
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                self.isShowing = false
                self.statusMessage = "Reward granted (simulated)"
                completion(true)
                self.load()
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow }
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

#if canImport(GoogleMobileAds)
extension RewardedAdService: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: any GADFullScreenPresentingAd) {
        Task { @MainActor in
            self.isShowing = false
            if self.rewardHandler != nil {
                // Dismissed without reward callback already handling it.
                self.rewardHandler = nil
            }
            self.rewardedAd = nil
            self.load()
        }
    }

    nonisolated func ad(
        _ ad: any GADFullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            self.isShowing = false
            let handler = self.rewardHandler
            self.rewardHandler = nil
            self.rewardedAd = nil
            if AdConfig.allowSimulatedFallback {
                self.simulateReward { earned in
                    handler?(earned)
                }
            } else {
                handler?(false)
            }
            self.load()
        }
    }
}
#endif
