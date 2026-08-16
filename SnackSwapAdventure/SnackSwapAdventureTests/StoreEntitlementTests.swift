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

    // MARK: - Boosters cost something

    /// The booster bar used to grant 100 free stars whenever the player could
    /// not pay, which made every booster free and the star bundles pointless.
    func testBoosterIsUnaffordableWithNoStockAndNoStars() {
        for booster in ActiveBooster.allCases {
            XCTAssertFalse(
                ActiveBooster.canAfford(stock: 0, stars: booster.cost - 1, cost: booster.cost),
                "\(booster.displayName) affordable while short of its \(booster.cost)⭐ cost"
            )
            XCTAssertFalse(
                ActiveBooster.canAfford(stock: 0, stars: 0, cost: booster.cost),
                "\(booster.displayName) affordable with nothing at all"
            )
        }
    }

    func testOwnedBoosterIsUsableWithoutStars() {
        for booster in ActiveBooster.allCases {
            XCTAssertTrue(
                ActiveBooster.canAfford(stock: 1, stars: 0, cost: booster.cost),
                "\(booster.displayName) unusable despite being owned"
            )
        }
    }

    func testStarsCoverABoosterWhenStockIsEmpty() {
        for booster in ActiveBooster.allCases {
            XCTAssertTrue(
                ActiveBooster.canAfford(stock: 0, stars: booster.cost, cost: booster.cost)
            )
        }
    }

    func testEveryBoosterCostsSomething() {
        for booster in ActiveBooster.allCases {
            XCTAssertGreaterThan(booster.cost, 0, "\(booster.displayName) is free")
        }
    }
}
