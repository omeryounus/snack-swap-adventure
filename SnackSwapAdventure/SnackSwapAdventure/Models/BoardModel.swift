import Foundation

/// Pure match-3 board logic with special tile support.
final class BoardModel {
    private(set) var size: Int
    private(set) var grid: [[BoardCell?]]
    private var snackPool: [SnackType]

    init(size: Int = 8, snackTypes: [SnackType] = SnackType.allCases) {
        self.size = size
        self.snackPool = snackTypes.isEmpty ? SnackType.allCases : snackTypes
        self.grid = Array(repeating: Array(repeating: nil, count: size), count: size)
        fillWithoutInitialMatches()
    }

    func reset(size: Int, snackTypes: [SnackType]) {
        self.size = size
        self.snackPool = snackTypes.isEmpty ? SnackType.allCases : snackTypes
        self.grid = Array(repeating: Array(repeating: nil, count: size), count: size)
        fillWithoutInitialMatches()
    }

    func cell(at pos: BoardPosition) -> BoardCell? {
        guard isValid(pos) else { return nil }
        return grid[pos.row][pos.col]
    }

    func snack(at pos: BoardPosition) -> SnackType? {
        cell(at: pos)?.snack
    }

    func isValid(_ pos: BoardPosition) -> Bool {
        pos.row >= 0 && pos.row < size && pos.col >= 0 && pos.col < size
    }

    func fillWithoutInitialMatches() {
        for row in 0..<size {
            for col in 0..<size {
                let type = randomSnackAvoidingMatch(at: BoardPosition(row: row, col: col))
                grid[row][col] = BoardCell(snack: type)
            }
        }
    }

    private func randomSnackAvoidingMatch(at pos: BoardPosition) -> SnackType {
        var excluded = Set<SnackType>()
        if pos.col >= 2,
           let a = grid[pos.row][pos.col - 1]?.snack,
           let b = grid[pos.row][pos.col - 2]?.snack,
           a == b {
            excluded.insert(a)
        }
        if pos.row >= 2,
           let a = grid[pos.row - 1][pos.col]?.snack,
           let b = grid[pos.row - 2][pos.col]?.snack,
           a == b {
            excluded.insert(a)
        }
        let pool = snackPool.filter { !excluded.contains($0) }
        return pool.randomElement() ?? snackPool[0]
    }

    @discardableResult
    func swap(_ a: BoardPosition, _ b: BoardPosition) -> Bool {
        guard isValid(a), isValid(b), a.isAdjacent(to: b),
              grid[a.row][a.col] != nil, grid[b.row][b.col] != nil else {
            return false
        }
        let temp = grid[a.row][a.col]
        grid[a.row][a.col] = grid[b.row][b.col]
        grid[b.row][b.col] = temp
        return true
    }

    func wouldCreateMatch(swapping a: BoardPosition, with b: BoardPosition) -> Bool {
        guard swap(a, b) else { return false }
        // Rainbow special can always swap with any snack.
        let rainbowSwap = cell(at: a)?.special == .rainbow || cell(at: b)?.special == .rainbow
        let matched = rainbowSwap || !findMatches().isEmpty
        swap(a, b)
        return matched
    }

    // MARK: - Matches

    func findMatches() -> Set<BoardPosition> {
        var matched = Set<BoardPosition>()

        for row in 0..<size {
            var col = 0
            while col < size {
                guard let type = grid[row][col]?.snack else { col += 1; continue }
                var end = col + 1
                while end < size, grid[row][end]?.snack == type { end += 1 }
                if end - col >= 3 {
                    for c in col..<end { matched.insert(BoardPosition(row: row, col: c)) }
                }
                col = end
            }
        }

        for col in 0..<size {
            var row = 0
            while row < size {
                guard let type = grid[row][col]?.snack else { row += 1; continue }
                var end = row + 1
                while end < size, grid[end][col]?.snack == type { end += 1 }
                if end - row >= 3 {
                    for r in row..<end { matched.insert(BoardPosition(row: r, col: col)) }
                }
                row = end
            }
        }
        return matched
    }

    func matchGroups() -> [[BoardPosition]] {
        let positions = findMatches()
        guard !positions.isEmpty else { return [] }
        var visited = Set<BoardPosition>()
        var groups: [[BoardPosition]] = []

        for start in positions.sorted(by: { $0.row == $1.row ? $0.col < $1.col : $0.row < $1.row }) {
            guard !visited.contains(start) else { continue }
            var queue = [start]
            var group: [BoardPosition] = []
            visited.insert(start)
            while let current = queue.popLast() {
                group.append(current)
                for n in [current.offset(row: 1), current.offset(row: -1),
                          current.offset(col: 1), current.offset(col: -1)]
                where positions.contains(n) && !visited.contains(n)
                      && snack(at: n) == snack(at: current) {
                    visited.insert(n)
                    queue.append(n)
                }
            }
            groups.append(group)
        }
        return groups
    }

    /// Detect specials to spawn for a match group. Returns (position, special).
    func specialToSpawn(for group: [BoardPosition]) -> (BoardPosition, SpecialKind)? {
        guard group.count >= 4, let anchor = group.first else { return nil }

        let rows = Set(group.map(\.row))
        let cols = Set(group.map(\.col))
        let isStraightRow = rows.count == 1
        let isStraightCol = cols.count == 1

        if group.count >= 5 && (isStraightRow || isStraightCol) {
            return (anchor, .rainbow)
        }

        // L / T shapes (not a single line)
        if !isStraightRow && !isStraightCol {
            return (anchor, .bomb)
        }

        if group.count >= 4 {
            if isStraightRow { return (anchor, .rowBlaster) }
            if isStraightCol { return (anchor, .colBlaster) }
            return (anchor, .bomb)
        }
        return nil
    }

    /// Expand match set with special activations.
    func expandWithSpecials(_ initial: Set<BoardPosition>, rainbowTarget: SnackType? = nil) -> Set<BoardPosition> {
        var result = initial
        var queue = Array(initial)
        var activated = Set<BoardPosition>()

        while let pos = queue.popLast() {
            guard let cell = cell(at: pos), let special = cell.special, !activated.contains(pos) else {
                continue
            }
            activated.insert(pos)
            let extra: Set<BoardPosition>
            switch special {
            case .rowBlaster:
                extra = Set((0..<size).map { BoardPosition(row: pos.row, col: $0) })
            case .colBlaster:
                extra = Set((0..<size).map { BoardPosition(row: $0, col: pos.col) })
            case .bomb:
                var set = Set<BoardPosition>()
                for r in (pos.row - 1)...(pos.row + 1) {
                    for c in (pos.col - 1)...(pos.col + 1) {
                        let p = BoardPosition(row: r, col: c)
                        if isValid(p) { set.insert(p) }
                    }
                }
                extra = set
            case .rainbow:
                let target = rainbowTarget ?? cell.snack
                var set = Set<BoardPosition>()
                for r in 0..<size {
                    for c in 0..<size {
                        let p = BoardPosition(row: r, col: c)
                        if snack(at: p) == target { set.insert(p) }
                    }
                }
                set.insert(pos)
                extra = set
            }
            for p in extra where !result.contains(p) {
                result.insert(p)
                queue.append(p)
            }
        }
        return result
    }

    /// Clear matched cells, optionally planting a special at spawnPos.
    func clear(_ positions: Set<BoardPosition>, spawnSpecial: (BoardPosition, SpecialKind, SnackType)? = nil) {
        for pos in positions where isValid(pos) {
            grid[pos.row][pos.col] = nil
        }
        if let spawn = spawnSpecial {
            grid[spawn.0.row][spawn.0.col] = BoardCell(snack: spawn.2, special: spawn.1)
        }
    }

    func applyGravity() -> [(from: BoardPosition, to: BoardPosition)] {
        var moves: [(from: BoardPosition, to: BoardPosition)] = []
        for col in 0..<size {
            var writeRow = 0
            for readRow in 0..<size {
                if let cell = grid[readRow][col] {
                    if readRow != writeRow {
                        grid[writeRow][col] = cell
                        grid[readRow][col] = nil
                        moves.append((
                            from: BoardPosition(row: readRow, col: col),
                            to: BoardPosition(row: writeRow, col: col)
                        ))
                    }
                    writeRow += 1
                }
            }
        }
        return moves
    }

    func refill() -> [(pos: BoardPosition, cell: BoardCell)] {
        var spawned: [(pos: BoardPosition, cell: BoardCell)] = []
        for col in 0..<size {
            for row in 0..<size where grid[row][col] == nil {
                let cell = BoardCell(snack: snackPool.randomElement() ?? .cookie)
                grid[row][col] = cell
                spawned.append((BoardPosition(row: row, col: col), cell))
            }
        }
        return spawned
    }

    static func score(for groups: [[BoardPosition]], cascadeDepth: Int, specialsActivated: Int) -> Int {
        var total = 0
        let multiplier = 1 + cascadeDepth
        for group in groups {
            let base: Int
            switch group.count {
            case 3: base = 60
            case 4: base = 140
            case 5: base = 220
            default: base = 220 + (group.count - 5) * 50
            }
            total += base * multiplier
        }
        total += specialsActivated * 80 * multiplier
        return total
    }
}
