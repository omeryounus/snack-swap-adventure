import XCTest
@testable import SnackSwapAdventure

final class PlayfieldGeometryTests: XCTestCase {
    func testNoOverlapsOnReferenceDevices() {
        for device in PlayfieldGeometry.referenceDevices {
            let isLandscape = device.size.width > device.size.height + 12
            let geometry = PlayfieldGeometry.make(
                container: device.size,
                isLandscape: isLandscape,
                isPad: device.isPad
            )
            let overlaps = geometry.overlappingPairs()
            XCTAssertTrue(
                overlaps.isEmpty,
                "\(device.name) overlapping \(overlaps)"
            )
            XCTAssertTrue(
                geometry.isFullyContained(in: device.size),
                "\(device.name) leaked outside \(device.size) hud=\(geometry.hud) board=\(geometry.board) dock=\(geometry.dock)"
            )
            XCTAssertGreaterThanOrEqual(
                min(geometry.board.width, geometry.board.height),
                PlayfieldGeometry.minimumBoardSide - 0.5,
                "\(device.name) board too small: \(geometry.board)"
            )
        }
    }

    func testPortraitBoardIsSquareAndBelowHUD() {
        let geometry = PlayfieldGeometry.make(
            container: CGSize(width: 390, height: 844),
            isLandscape: false,
            isPad: false
        )
        XCTAssertEqual(geometry.board.width, geometry.board.height, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(geometry.board.minY, geometry.hud.maxY)
        XCTAssertGreaterThanOrEqual(geometry.dock.minY, geometry.board.maxY)
        XCTAssertFalse(geometry.isLandscape)
    }

    func testPortraitHUDStaysCompact() {
        let phone = PlayfieldGeometry.make(
            container: CGSize(width: 390, height: 844),
            isLandscape: false,
            isPad: false
        )
        XCTAssertLessThanOrEqual(phone.hud.height, 76.5)
        XCTAssertLessThanOrEqual(phone.hud.maxY, 86)
        XCTAssertLessThanOrEqual(phone.board.minY, 94)

        let maxPhone = PlayfieldGeometry.make(
            container: CGSize(width: 440, height: 956),
            isLandscape: false,
            isPad: false
        )
        XCTAssertLessThanOrEqual(maxPhone.hud.height, 76.5)
        XCTAssertLessThanOrEqual(maxPhone.board.minY, 94)
    }

    func testLandscapeBoardDoesNotEnterSidebar() {
        let geometry = PlayfieldGeometry.make(
            container: CGSize(width: 956, height: 440),
            isLandscape: true,
            isPad: false
        )
        XCTAssertTrue(geometry.isLandscape)
        XCTAssertGreaterThanOrEqual(geometry.board.minX, geometry.hud.maxX)
        XCTAssertGreaterThanOrEqual(geometry.board.minX, geometry.dock.maxX)
        XCTAssertTrue(geometry.overlappingPairs().isEmpty)
    }

    func testLandscapeGameplayAreaIsSeventyPercent() {
        let sizes = [
            CGSize(width: 844, height: 390),
            CGSize(width: 956, height: 440),
            CGSize(width: 1194, height: 834)
        ]
        for size in sizes {
            let isPad = size.height > 500
            let geometry = PlayfieldGeometry.make(
                container: size,
                isLandscape: true,
                isPad: isPad
            )
            let pad: CGFloat = isPad ? 12 : 8
            let contentW = size.width - pad * 2
            let ratio = geometry.board.width / contentW
            XCTAssertEqual(
                ratio,
                PlayfieldGeometry.landscapeGameplayRatio,
                accuracy: 0.02,
                "\(size) gameplay width ratio \(ratio)"
            )
            XCTAssertEqual(geometry.board.height, size.height - pad * 2, accuracy: 0.5)
        }
    }

    func testNarrowLandscapeFallsBackToStackedPortrait() {
        let geometry = PlayfieldGeometry.make(
            container: CGSize(width: 480, height: 320),
            isLandscape: true,
            isPad: false
        )
        XCTAssertFalse(geometry.isLandscape)
        XCTAssertTrue(geometry.overlappingPairs().isEmpty)
        XCTAssertGreaterThanOrEqual(geometry.board.minY, geometry.hud.maxY)
    }

    func testSplitViewSliceDoesNotOverlap() {
        let geometry = PlayfieldGeometry.make(
            container: CGSize(width: 320, height: 834),
            isLandscape: false,
            isPad: true
        )
        XCTAssertTrue(geometry.overlappingPairs().isEmpty)
        XCTAssertTrue(geometry.isFullyContained(in: CGSize(width: 320, height: 834)))
    }
}
