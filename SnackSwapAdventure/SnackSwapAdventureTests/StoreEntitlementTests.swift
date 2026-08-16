import XCTest
@testable import SnackSwapAdventure

/// The Remove Ads product previously set a flag that no ad code ever read, so
/// buying it changed nothing. These lock the guarantee down.
final class StoreEntitlementTests: XCTestCase {

    // MARK: - Remove Ads actually removes ads

    func testRemoveAdsSuppressesInterstitialsUnconditionally() {
        // Even at a cadence and interval that would otherwise show an ad.
        for levels in 0...12 {
            XCTAssertFalse(
                InterstitialPolicy.shouldShow(
                    adsRemoved: true,
                    levelsSinceLastAd: levels,
                    everyNLevels: 1,
                    secondsSinceLastAd: 86_400,
                    minInterval: 0
                ),
                "purchaser was shown an interstitial after \(levels) levels"
            )
        }
    }

    func testNonPurchaserSeesInterstitialOnCadence() {
        XCTAssertTrue(
            InterstitialPolicy.shouldShow(
                adsRemoved: false,
                levelsSinceLastAd: AdConfig.interstitialEveryNLevels,
                secondsSinceLastAd: nil
            ),
            "ads never show for non-purchasers, so Remove Ads would be worthless"
        )
    }

    func testInterstitialWaitsForTheCadence() {
        XCTAssertFalse(
            InterstitialPolicy.shouldShow(
                adsRemoved: false,
                levelsSinceLastAd: AdConfig.interstitialEveryNLevels - 1,
                secondsSinceLastAd: nil
            )
        )
    }

    func testInterstitialRespectsMinimumInterval() {
        XCTAssertFalse(
            InterstitialPolicy.shouldShow(
                adsRemoved: false,
                levelsSinceLastAd: 99,
                everyNLevels: 1,
                secondsSinceLastAd: 5,
                minInterval: 90
            ),
            "two interstitials back to back"
        )
    }

    // MARK: - Product catalogue

    /// These must match the products that exist in App Store Connect, or
    /// Product.products(for:) returns nothing and every buy button is dead.
    func testProductIDsMatchAppStoreConnect() {
        XCTAssertEqual(StoreManager.ProductIDs.stars60, "com.snackswap.adventure.stars60")
        XCTAssertEqual(StoreManager.ProductIDs.stars180, "com.snackswap.adventure.stars180")
        XCTAssertEqual(StoreManager.ProductIDs.stars500, "com.snackswap.adventure.stars500")
        XCTAssertEqual(StoreManager.ProductIDs.removeAds, "com.snackswap.adventure.removeads")
        XCTAssertEqual(StoreManager.ProductIDs.all.count, 4)
    }

    /// A bundle must never advertise one amount and credit another.
    func testStarPacksAreSelfConsistent() {
        XCTAssertEqual(StoreManager.starPacks.count, 3)
        for pack in StoreManager.starPacks {
            XCTAssertTrue(
                StoreManager.ProductIDs.all.contains(pack.id),
                "\(pack.id) is not in the fetched product set"
            )
            XCTAssertGreaterThan(pack.stars, 0)
            XCTAssertTrue(
                pack.title.contains("\(pack.stars)"),
                "\(pack.title) advertises a different amount than the \(pack.stars) it credits"
            )
        }
    }

    // Cross-checking Configuration.storekit against these IDs cannot run here —
    // the test host is sandboxed and cannot read the source tree. That check
    // lives in scripts/verify_products.py instead.
}
