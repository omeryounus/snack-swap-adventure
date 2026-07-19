import Foundation

/// AdMob configuration. Uses Google's official test IDs in DEBUG.
/// Replace production values in App Store builds via Info.plist / build settings.
enum AdConfig {
    /// Google sample App ID — replace with yours for production.
    static let appID = "ca-app-pub-3940256099942544~1458002511"

    /// Google sample rewarded ad unit — replace for production.
    static let rewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// When true, use a local simulated ad if the SDK fails (simulator-friendly).
    static let allowSimulatedFallback = true
}
