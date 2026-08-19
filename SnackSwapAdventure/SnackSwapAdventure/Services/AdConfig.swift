import Foundation

/// AdMob configuration. Uses Google's official test IDs in DEBUG.
/// Replace production values in App Store builds via Info.plist / build settings.
enum AdConfig {
    /// Google's public sample publisher. While the unit IDs still point at it
    /// there is no ad account behind them: no ads serve, nothing is earned,
    /// and shipping them is against AdMob policy.
    private static let samplePublisherPrefix = "ca-app-pub-3940256099942544"

    /// Whether a real ad network is wired up. False keeps the Google Mobile
    /// Ads SDK from initialising at all, so the app performs no third-party
    /// data collection and the ATT prompt is not shown for a capability it
    /// does not have. Replace the IDs below to turn ads back on.
    static var adsEnabled: Bool {
        !appID.hasPrefix(samplePublisherPrefix)
            && !rewardedUnitID.hasPrefix(samplePublisherPrefix)
            && !interstitialUnitID.hasPrefix(samplePublisherPrefix)
    }

    /// Google sample App ID — replace with yours for production.
    static let appID = "ca-app-pub-3940256099942544~1458002511"

    /// Google sample rewarded ad unit — replace for production.
    static let rewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// Google sample interstitial ad unit — replace for production.
    static let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"

    /// Show an interstitial on every Nth level transition.
    static let interstitialEveryNLevels = 3

    /// Never show two interstitials closer together than this.
    static let interstitialMinInterval: TimeInterval = 90

    /// Keep local simulated rewards out of TestFlight/App Store builds.
    #if DEBUG
    static let allowSimulatedFallback = true
    #else
    static let allowSimulatedFallback = false
    #endif
}

/// When an interstitial may be shown. Pure logic, kept separate from AdMob so
/// the "Remove Ads removes the ads" guarantee is unit-testable.
enum InterstitialPolicy {
    static func shouldShow(
        adsRemoved: Bool,
        levelsSinceLastAd: Int,
        everyNLevels: Int = AdConfig.interstitialEveryNLevels,
        secondsSinceLastAd: TimeInterval? = nil,
        minInterval: TimeInterval = AdConfig.interstitialMinInterval
    ) -> Bool {
        // The purchase gate comes first and has no exceptions.
        guard !adsRemoved else { return false }
        guard everyNLevels > 0, levelsSinceLastAd >= everyNLevels else { return false }
        if let elapsed = secondsSinceLastAd, elapsed < minInterval { return false }
        return true
    }
}
