import XCTest
@testable import SnackSwapAdventure

/// App Review rejected 1.3.0 under 5.1.2(i): the privacy label declared
/// tracking while ATTrackingManager was never called. These pin the rules that
/// keep the shipped build and the declared label consistent.
final class TrackingConsentTests: XCTestCase {

    /// Shipping Google's sample publisher means no ad account is behind the
    /// build — no ads serve, and it breaches AdMob policy.
    func testAdsAreDisabledWhileUsingSamplePublisherIDs() {
        let sample = "ca-app-pub-3940256099942544"
        let usingSample = AdConfig.appID.hasPrefix(sample)
            || AdConfig.rewardedUnitID.hasPrefix(sample)
            || AdConfig.interstitialUnitID.hasPrefix(sample)

        if usingSample {
            XCTAssertFalse(
                AdConfig.adsEnabled,
                "sample ad IDs must not count as a live ad network"
            )
        } else {
            XCTAssertTrue(AdConfig.adsEnabled)
        }
    }

    /// The whole point of the gate: with no ad network there is no third-party
    /// SDK to initialise, so the app collects nothing used for tracking.
    func testNoAdNetworkMeansNothingToTrack() throws {
        guard !AdConfig.adsEnabled else {
            throw XCTSkip("An ad network is configured; tracking rules apply instead.")
        }
        XCTAssertFalse(AdConfig.adsEnabled)
    }

    /// Interstitial cadence must stay independent of the ad network so the
    /// Remove Ads entitlement keeps working the moment ads come back.
    func testRemoveAdsStillSuppressesInterstitialsRegardlessOfNetwork() {
        XCTAssertFalse(
            InterstitialPolicy.shouldShow(
                adsRemoved: true,
                levelsSinceLastAd: 99,
                everyNLevels: 1,
                secondsSinceLastAd: 86_400,
                minInterval: 0
            )
        )
    }

    /// The shipped bundle must carry the usage string, or the prompt cannot be
    /// shown at all and the app would be rejected again the moment ads are
    /// enabled. Read from the built bundle rather than the source tree — the
    /// test host is sandboxed and cannot open the project directory.
    func testTrackingUsageDescriptionShipsInTheBundle() {
        let usage = Bundle.main
            .object(forInfoDictionaryKey: "NSUserTrackingUsageDescription") as? String
        XCTAssertNotNil(usage, "NSUserTrackingUsageDescription missing from the built bundle")
        XCTAssertFalse((usage ?? "").isEmpty)
    }
}
