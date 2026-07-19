import Foundation

/// Grid coordinate: row 0 is the bottom of the board (SpriteKit-style).
struct BoardPosition: Hashable, Equatable, CustomStringConvertible {
    let row: Int
    let col: Int

    var description: String { "(\(row),\(col))" }

    func isAdjacent(to other: BoardPosition) -> Bool {
        let dr = abs(row - other.row)
        let dc = abs(col - other.col)
        return (dr + dc) == 1
    }

    func offset(row dRow: Int = 0, col dCol: Int = 0) -> BoardPosition {
        BoardPosition(row: row + dRow, col: col + dCol)
    }
}
