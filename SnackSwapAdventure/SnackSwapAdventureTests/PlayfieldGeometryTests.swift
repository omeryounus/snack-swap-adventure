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
