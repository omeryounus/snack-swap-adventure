import XCTest
@testable import SnackSwapAdventure

final class PlayfieldGeometryTests: XCTestCase {
    /// The core contract: on every supported size, in every orientation, with
    /// every combination of transient HUD rows, the three regions stay disjoint
    /// and on screen.
    func testNoOverlapsOnReferenceDevices() {
        for device in PlayfieldGeometry.referenceDevices {
            for rows in PlayfieldGeometry.accessoryRowCases {
                let isLandscape = device.size.width > device.size.height + 12
                let geometry = PlayfieldGeometry.make(
                    container: device.size,
                    isLandscape: isLandscape,
                    isPad: device.isPad,
                    hudAccessoryRows: rows
                )
                let overlaps = geometry.overlappingPairs()
                XCTAssertTrue(
                    overlaps.isEmpty,
                    "\(device.name) rows=\(rows) overlapping \(overlaps)"
                )
                XCTAssertTrue(
                    geometry.isFullyContained(in: device.size),
                    "\(device.name) rows=\(rows) leaked outside \(device.size) "
                        + "hud=\(geometry.hud) board=\(geometry.board) dock=\(geometry.dock)"
                )
                XCTAssertGreaterThanOrEqual(
                    min(geometry.board.width, geometry.board.height),
                    PlayfieldGeometry.minimumBoardSide - 0.5,
                    "\(device.name) rows=\(rows) board too small: \(geometry.board)"
                )
            }
        }
    }

    /// The board is where the 8×8 grid is drawn, so it must be square in both
    /// orientations — a stretched rect just wastes one axis.
    func testBoardIsSquareInEveryOrientation() {
        for device in PlayfieldGeometry.referenceDevices {
            let isLandscape = device.size.width > device.size.height + 12
            let geometry = PlayfieldGeometry.make(
                container: device.size,
                isLandscape: isLandscape,
                isPad: device.isPad
            )
            XCTAssertEqual(
                geometry.board.width,
                geometry.board.height,
                accuracy: 0.5,
                "\(device.name) board not square: \(geometry.board)"
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
        XCTAssertLessThanOrEqual(phone.hud.minY, 24, "top band is wasted space, keep it thin")

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

    /// The portrait HUD floor must clear its own contents. With comfortable
    /// chip padding the stat row and goal row measure ~82pt, so small screens
    /// get a fixed floor rather than a fraction of a short screen.
    func testPortraitHUDFloorClearsItsContents() {
        for size in [CGSize(width: 320, height: 568), CGSize(width: 375, height: 667)] {
            let geometry = PlayfieldGeometry.make(container: size, isLandscape: false, isPad: false)
            XCTAssertGreaterThanOrEqual(
                geometry.hud.height,
                198 + PlayfieldGeometry.hudAccessoryReserveRows * PlayfieldGeometry.hudAccessoryRowHeight,
                "\(size) portrait HUD shorter than its contents"
            )
        }
    }

    /// Tall phones have enough slack that the full-height HUD costs them
    /// nothing — the board there is bound by width, not height.
    func testTallPhonesKeepTheirFullBoard() {
        let expected: [(CGSize, CGFloat)] = [
            (CGSize(width: 390, height: 844), 374),
            (CGSize(width: 402, height: 874), 386),
            (CGSize(width: 440, height: 956), 424)
        ]
        for (size, board) in expected {
            let geometry = PlayfieldGeometry.make(container: size, isLandscape: false, isPad: false)
            XCTAssertEqual(
                geometry.board.width,
                board,
                accuracy: 1,
                "\(size) board shrank when the HUD grew"
            )
        }
    }

    /// Short screens do pay for the taller HUD, so the board must still be
    /// comfortably playable there — including with both transient rows open.
    func testShortScreensStayPlayableWithTheTallerHUD() {
        for size in [CGSize(width: 320, height: 568), CGSize(width: 375, height: 667)] {
            for rows in PlayfieldGeometry.accessoryRowCases {
                let geometry = PlayfieldGeometry.make(
                    container: size,
                    isLandscape: false,
                    isPad: false,
                    hudAccessoryRows: rows
                )
                XCTAssertGreaterThanOrEqual(
                    geometry.board.width,
                    PlayfieldGeometry.minimumBoardSide,
                    "\(size) rows=\(rows) board dropped below the playable minimum"
                )
                XCTAssertTrue(geometry.overlappingPairs().isEmpty)
            }
        }
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

    /// Landscape is height-bound, so the board should take the largest square
    /// the height allows rather than a fixed fraction of the width.
    func testLandscapeBoardTakesTheFullHeightSquare() {
        let sizes: [(CGSize, Bool)] = [
            (CGSize(width: 844, height: 390), false),
            (CGSize(width: 956, height: 440), false),
            (CGSize(width: 1194, height: 834), true)
        ]
        for (size, isPad) in sizes {
            let geometry = PlayfieldGeometry.make(
                container: size,
                isLandscape: true,
                isPad: isPad
            )
            let pad: CGFloat = isPad ? 12 : 8
            let contentH = size.height - pad * 2
            XCTAssertEqual(
                geometry.board.height,
                contentH,
                accuracy: 0.5,
                "\(size) board did not use the available height"
            )
            XCTAssertEqual(geometry.board.width, geometry.board.height, accuracy: 0.5)
        }
    }

    /// The sidebar stays within its bounds so it neither starves the HUD on
    /// small phones nor eats the board on wide screens.
    func testLandscapeSidebarStaysWithinBounds() {
        for device in PlayfieldGeometry.referenceDevices
        where device.size.width > device.size.height + 12 && device.size.width >= 520 {
            let geometry = PlayfieldGeometry.make(
                container: device.size,
                isLandscape: true,
                isPad: device.isPad
            )
            let maxSidebar = device.isPad
                ? PlayfieldGeometry.landscapeMaxSidebarPad
                : PlayfieldGeometry.landscapeMaxSidebarPhone
            XCTAssertGreaterThanOrEqual(
                geometry.hud.width,
                PlayfieldGeometry.landscapeMinSidebar - 0.5,
                "\(device.name) sidebar too narrow"
            )
            XCTAssertLessThanOrEqual(
                geometry.hud.width,
                maxSidebar + 0.5,
                "\(device.name) sidebar too wide"
            )
            XCTAssertEqual(geometry.dock.width, geometry.hud.width, accuracy: 0.5)
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

    /// The board must never move under the player. Sugar Rush and the hammer
    /// prompt appear mid-level, so if the HUD grew to fit them the board slid
    /// down by half the difference — which is exactly what it used to do.
    func testBoardIsIdenticalWhetherTransientRowsAreShowingOrNot() {
        for device in PlayfieldGeometry.referenceDevices {
            let isLandscape = device.size.width > device.size.height + 12
            let rects = PlayfieldGeometry.accessoryRowCases.map { rows in
                PlayfieldGeometry.make(
                    container: device.size,
                    isLandscape: isLandscape,
                    isPad: device.isPad,
                    hudAccessoryRows: rows
                )
            }
            guard let reference = rects.first else { return XCTFail("no cases") }
            for geometry in rects {
                XCTAssertEqual(geometry.board, reference.board, "\(device.name) board moved")
                XCTAssertEqual(geometry.hud, reference.hud, "\(device.name) HUD resized")
                XCTAssertEqual(geometry.dock, reference.dock, "\(device.name) dock moved")
            }
        }
    }

    /// …and the fixed height must actually be enough for those rows, or they
    /// would render outside the card and land on the board.
    func testHUDReservesRoomForEveryTransientRow() {
        for device in PlayfieldGeometry.referenceDevices
        where !(device.size.width > device.size.height + 12) {
            let geometry = PlayfieldGeometry.make(
                container: device.size,
                isLandscape: false,
                isPad: device.isPad
            )
            let reserve = PlayfieldGeometry.hudAccessoryReserveRows
                * PlayfieldGeometry.hudAccessoryRowHeight
            XCTAssertGreaterThanOrEqual(
                geometry.hud.height,
                reserve,
                "\(device.name) HUD cannot fit its transient rows"
            )
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
