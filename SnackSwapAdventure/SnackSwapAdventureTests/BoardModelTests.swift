import XCTest
@testable import SnackSwapAdventure

final class BoardModelTests: XCTestCase {
    func testNewBoardIsCompletelyFilled() {
        for size in 6...9 {
            let board = BoardModel(size: size, snackTypes: Array(SnackType.allCases.prefix(4)))
            XCTAssertTrue(board.isCompletelyFilled, "size \(size) has empty cells: \(board.emptyPositions())")
        }
    }

    func testNewBoardHasNoImmediateMatches() {
        for _ in 0..<40 {
            let board = BoardModel(size: 8, snackTypes: SnackType.allCases)
            XCTAssertTrue(board.findMatches().isEmpty, "fresh board contained a match")
        }
    }

    func testReshuffleAlwaysLeavesALegalMove() {
        let board = BoardModel(size: 8)
        XCTAssertTrue(board.reshuffleToPlayable())
        XCTAssertNotNil(board.firstAvailableMove())
        XCTAssertTrue(board.isCompletelyFilled)
        XCTAssertTrue(board.findMatches().isEmpty)
    }

    func testGravityPacksTowardRowZeroAndRefillFillsTheRest() {
        let board = BoardModel(size: 6)
        let cleared: Set<BoardPosition> = [
            BoardPosition(row: 0, col: 1),
            BoardPosition(row: 2, col: 1),
            BoardPosition(row: 5, col: 1)
        ]
        board.clear(cleared)
        XCTAssertEqual(board.emptyPositions().count, 3)

        _ = board.applyGravity()
        let emptiesAfterGravity = board.emptyPositions()
        XCTAssertEqual(emptiesAfterGravity.count, 3)
        XCTAssertTrue(emptiesAfterGravity.allSatisfy { $0.col == 1 && $0.row >= 3 })

        _ = board.refill()
        XCTAssertTrue(board.isCompletelyFilled)
        XCTAssertTrue(board.emptyPositions().isEmpty)
    }

    func testSwapRequiresAdjacency() {
        let board = BoardModel(size: 6)
        let a = BoardPosition(row: 0, col: 0)
        let far = BoardPosition(row: 2, col: 2)
        XCTAssertFalse(board.swap(a, far))
        XCTAssertTrue(board.swap(a, BoardPosition(row: 0, col: 1)))
        XCTAssertTrue(board.isCompletelyFilled)
    }

    func testResetRestoresFullPlayableBoard() {
        let board = BoardModel(size: 6)
        board.clear([BoardPosition(row: 0, col: 0)])
        board.reset(size: 8, snackTypes: SnackType.allCases)
        XCTAssertEqual(board.size, 8)
        XCTAssertTrue(board.isCompletelyFilled)
        XCTAssertTrue(board.findMatches().isEmpty)
    }
}
