import Foundation
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Full-screen interstitials shown between levels — the ads that
/// `com.snackswap.adventure.removeads` pays to switch off.
///
/// Every presentation goes through `showIfEligible`, which consults
/// `StoreManager.isAdsRemoved` before anything else, so there is exactly one
/// place the entitlement has to be honoured.
@MainActor
final class InterstitialAdService: NSObject, ObservableObject {
    static let shared = InterstitialAdService()

    @Published private(set) var isReady = false

    #if canImport(GoogleMobileAds)
    private var interstitial: GADInterstitialAd?
    #endif

    private var pendingCompletion: (() -> Void)?
    private var levelsSinceLastAd = 0
    private var lastShownAt: Date?

    private override init() {
        super.init()
    }

    func start() {
        guard !StoreManager.shared.isAdsRemoved else { return }
        load()
    }

    private func load() {
        #if canImport(GoogleMobileAds)
        guard Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") != nil else {
            isReady = false
            return
        }
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: AdConfig.interstitialUnitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("[InterstitialAdService] load failed: \(error.localizedDescription)")
                    self.interstitial = nil
                    self.isReady = false
                    return
                }
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
                self.isReady = ad != nil
            }
        }
        #else
        isReady = false
        #endif
    }

    /// Runs `completion` exactly once, either after the ad is dismissed or
    /// immediately when no ad should be shown. Never blocks progression.
    func showIfEligible(from viewController: UIViewController? = nil, completion: @escaping () -> Void) {
        let adsRemoved = StoreManager.shared.isAdsRemoved

        // Purchasers do not accrue a countdown either, so nothing is queued up
        // waiting for them if a refund ever flips the entitlement back.
        guard !adsRemoved else {
            completion()
            return
        }

        levelsSinceLastAd += 1

        let eligible = InterstitialPolicy.shouldShow(
            adsRemoved: adsRemoved,
            levelsSinceLastAd: levelsSinceLastAd,
            secondsSinceLastAd: lastShownAt.map { Date().timeIntervalSince($0) }
        )
        guard eligible else {
            completion()
            return
        }

        #if canImport(GoogleMobileAds)
        guard let ad = interstitial, let root = viewController ?? Self.topViewController() else {
            // Nothing loaded — never make the player wait on an ad.
            completion()
            load()
            return
        }
        pendingCompletion = completion
        levelsSinceLastAd = 0
        lastShownAt = Date()
        ad.present(fromRootViewController: root)
        #else
        completion()
        #endif
    }

    private func finish() {
        let completion = pendingCompletion
        pendingCompletion = nil
        interstitial = nil
        isReady = false
        completion?()
        load()
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

#if canImport(GoogleMobileAds)
extension InterstitialAdService: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: any GADFullScreenPresentingAd) {
        Task { @MainActor in self.finish() }
    }

    nonisolated func ad(
        _ ad: any GADFullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            print("[InterstitialAdService] present failed: \(error.localizedDescription)")
            self.finish()
        }
    }
}
#endif
