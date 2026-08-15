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

    func testPortraitHasTopSpaceAndCenteredBoard() {
        let phone = PlayfieldGeometry.make(
            container: CGSize(width: 390, height: 844),
            isLandscape: false,
            isPad: false
        )
        XCTAssertGreaterThanOrEqual(phone.hud.minY, 844 * PlayfieldGeometry.portraitTopRatio - 0.5)
        XCTAssertLessThanOrEqual(phone.hud.height, 76.5)

        let midTop = phone.hud.maxY
        let midBottom = phone.dock.minY
        let boardMid = phone.board.midY
        let areaMid = (midTop + midBottom) / 2
        XCTAssertEqual(boardMid, areaMid, accuracy: 8)
        XCTAssertEqual(phone.board.midX, 195, accuracy: 1)

        let maxPhone = PlayfieldGeometry.make(
            container: CGSize(width: 440, height: 956),
            isLandscape: false,
            isPad: false
        )
        XCTAssertGreaterThanOrEqual(maxPhone.hud.minY, 956 * PlayfieldGeometry.portraitTopRatio - 0.5)
        XCTAssertEqual(maxPhone.board.midX, 220, accuracy: 1)
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

    func testLandscapeLeavesTenPercentBeforeDock() {
        let geometry = PlayfieldGeometry.make(
            container: CGSize(width: 956, height: 440),
            isLandscape: true,
            isPad: false
        )
        let contentH: CGFloat = 440 - 16
        let gap = geometry.dock.minY - geometry.hud.maxY
        XCTAssertGreaterThanOrEqual(gap + 0.5, contentH * PlayfieldGeometry.landscapeSectionGapRatio)
        XCTAssertGreaterThanOrEqual(geometry.hud.height, 184)
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
