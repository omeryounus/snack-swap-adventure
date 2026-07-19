import SpriteKit
import UIKit

/// SpriteKit scene that renders the snack board and drives the match-3 loop.
final class GameScene: SKScene {

    // MARK: - Config

    /// Top chrome is SwiftUI GameHUD — leave room for the full panel.
    private let boardPadding: CGFloat = 8
    private let topHUDReserved: CGFloat = 172
    private let bottomReserved: CGFloat = 118
    /// Grow tiles 10% vs the original padded layout.
    private let tileScaleBoost: CGFloat = 1.10

    // MARK: - State

    private weak var gameState: GameState?
    private var boardSize = 8
    private var tileSize: CGFloat = 44
    private var boardOrigin: CGPoint = .zero

    /// Visual nodes keyed by board position (row, col).
    private var tileNodes: [[SnackNode?]] = []
    private var selectedPosition: BoardPosition?
    private var isBusy = false
    private var lastAnnouncedOutcome: GameOutcome = .playing

    private var boardBackground: SKShapeNode?
    private var selectionRing: SKShapeNode?
    private var goalLabel: SKLabelNode?
    private var movesLabel: SKLabelNode?
    private var scoreLabel: SKLabelNode?
    private var messageLabel: SKLabelNode?
    private var monsterLabel: SKLabelNode?
    private var levelLabel: SKLabelNode?

    // MARK: - Lifecycle

    func configure(with state: GameState) {
        self.gameState = state
        self.boardSize = state.level.boardSize
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.10, blue: 0.20, alpha: 1)
        rebuildBoard()
    }

    func rebuildBoard() {
        removeAllChildren()
        selectedPosition = nil
        isBusy = false
        lastAnnouncedOutcome = .playing

        guard let state = gameState else { return }
        boardSize = state.level.boardSize

        layoutMetrics()
        drawBoardFrame()
        buildTilesFromModel()
        buildHUD()
        refreshHUD()
        bounceInTiles()
    }

    // MARK: - Layout

    private func layoutMetrics() {
        let usableWidth = size.width - boardPadding * 2
        let usableHeight = size.height - topHUDReserved - bottomReserved - boardPadding * 2
        let side = min(usableWidth, usableHeight)

        // Original layout used 16pt padding + larger HUD chrome (~32 / 292).
        // Target tiles 10% larger than that baseline, then clamp to what still fits.
        let baselineSide = min(size.width - 32, size.height - 292)
        let baselineTile = floor(baselineSide / CGFloat(boardSize))
        let targetTile = max(1, floor(baselineTile * tileScaleBoost))
        let maxFit = floor(side / CGFloat(boardSize))
        tileSize = min(targetTile, maxFit)

        let boardPixel = tileSize * CGFloat(boardSize)
        boardOrigin = CGPoint(
            x: (size.width - boardPixel) / 2,
            y: bottomReserved + max(0, (usableHeight - boardPixel) / 2)
        )
    }

    private func point(for pos: BoardPosition) -> CGPoint {
        CGPoint(
            x: boardOrigin.x + CGFloat(pos.col) * tileSize + tileSize / 2,
            y: boardOrigin.y + CGFloat(pos.row) * tileSize + tileSize / 2
        )
    }

    private func position(at point: CGPoint) -> BoardPosition? {
        let localX = point.x - boardOrigin.x
        let localY = point.y - boardOrigin.y
        let boardPixel = tileSize * CGFloat(boardSize)
        guard localX >= 0, localY >= 0, localX < boardPixel, localY < boardPixel else {
            return nil
        }
        let col = Int(localX / tileSize)
        let row = Int(localY / tileSize)
        let pos = BoardPosition(row: row, col: col)
        return (row >= 0 && row < boardSize && col >= 0 && col < boardSize) ? pos : nil
    }

    // MARK: - Visual setup

    private func drawBoardFrame() {
        let boardPixel = tileSize * CGFloat(boardSize)
        let rect = CGRect(
            x: boardOrigin.x - 6,
            y: boardOrigin.y - 6,
            width: boardPixel + 12,
            height: boardPixel + 12
        )
        let frame = SKShapeNode(rect: rect, cornerRadius: 16)
        frame.fillColor = SKColor(red: 0.18, green: 0.15, blue: 0.28, alpha: 1)
        frame.strokeColor = SKColor(red: 0.45, green: 0.35, blue: 0.70, alpha: 1)
        frame.lineWidth = 3
        frame.zPosition = 0
        addChild(frame)
        boardBackground = frame

        // Subtle checkerboard
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if (row + col) % 2 == 0 {
                    let cell = SKShapeNode(
                        rectOf: CGSize(width: tileSize - 2, height: tileSize - 2),
                        cornerRadius: 8
                    )
                    cell.fillColor = SKColor(white: 1, alpha: 0.04)
                    cell.strokeColor = .clear
                    cell.position = point(for: BoardPosition(row: row, col: col))
                    cell.zPosition = 1
                    addChild(cell)
                }
            }
        }
    }

    private func buildTilesFromModel() {
        guard let state = gameState else { return }
        tileNodes = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let pos = BoardPosition(row: row, col: col)
                guard let cell = state.board.cell(at: pos) else { continue }
                let node = makeSnackNode(cell: cell, at: pos)
                tileNodes[row][col] = node
                addChild(node)
            }
        }
    }

    private func makeSnackNode(cell: BoardCell, at pos: BoardPosition) -> SnackNode {
        let node = SnackNode(cell: cell, tileSize: tileSize)
        node.position = point(for: pos)
        node.zPosition = 10
        node.name = "snack_\(pos.row)_\(pos.col)"
        return node
    }

    private func buildHUD() {
        // Top stats live in SwiftUI GameHUD. SpriteKit only keeps bottom feedback + selection.
        levelLabel = nil
        movesLabel = nil
        scoreLabel = nil
        goalLabel = nil

        monsterLabel = SKLabelNode(text: "👾")
        monsterLabel?.fontSize = 52
        monsterLabel?.verticalAlignmentMode = .center
        monsterLabel?.horizontalAlignmentMode = .center
        monsterLabel?.position = CGPoint(x: size.width / 2, y: 70)
        monsterLabel?.zPosition = 100
        if let monsterLabel { addChild(monsterLabel) }

        messageLabel = makeLabel(fontSize: 13, color: SKColor(white: 0.92, alpha: 1))
        messageLabel?.horizontalAlignmentMode = .center
        messageLabel?.position = CGPoint(x: size.width / 2, y: 28)
        messageLabel?.zPosition = 100
        if let messageLabel { addChild(messageLabel) }

        let ring = SKShapeNode(rectOf: CGSize(width: tileSize - 4, height: tileSize - 4), cornerRadius: 10)
        ring.strokeColor = .white
        ring.lineWidth = 3
        ring.fillColor = .clear
        ring.glowWidth = 2
        ring.isHidden = true
        ring.zPosition = 20
        addChild(ring)
        selectionRing = ring
    }

    private func makeLabel(fontSize: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        return label
    }

    private func bounceInTiles() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                guard let node = tileNodes[row][col] else { continue }
                node.setScale(0.01)
                node.alpha = 0
                let delay = Double(row + col) * 0.012
                node.run(.sequence([
                    .wait(forDuration: delay),
                    .group([
                        .fadeIn(withDuration: 0.12),
                        .sequence([
                            .scale(to: 1.18, duration: 0.14),
                            .scale(to: 0.94, duration: 0.08),
                            .scale(to: 1.0, duration: 0.08)
                        ])
                    ])
                ]))
            }
        }
    }

    // MARK: - HUD refresh

    private func refreshHUD() {
        guard let state = gameState else { return }
        // Level / timer / score / goal are rendered by SwiftUI GameHUD.
        messageLabel?.text = state.lastFeedMessage
        monsterLabel?.text = state.monsterMood.emoji

        // Play win/lose once when outcome flips.
        if lastAnnouncedOutcome == .playing || lastAnnouncedOutcome == .timedOut {
            switch state.outcome {
            case .won:
                SoundManager.shared.playWin()
                lastAnnouncedOutcome = state.outcome
            case .lost:
                SoundManager.shared.playLose()
                lastAnnouncedOutcome = state.outcome
            case .timedOut:
                lastAnnouncedOutcome = state.outcome
            case .playing:
                break
            }
        }

        // Gentle monster pulse on happy moods
        monsterLabel?.removeAction(forKey: "mood")
        switch state.monsterMood {
        case .happy, .ecstatic:
            let pulse = SKAction.sequence([
                .scale(to: 1.2, duration: 0.12),
                .scale(to: 1.0, duration: 0.18)
            ])
            monsterLabel?.run(pulse, withKey: "mood")
        case .sad:
            let shake = SKAction.sequence([
                .moveBy(x: -6, y: 0, duration: 0.04),
                .moveBy(x: 12, y: 0, duration: 0.08),
                .moveBy(x: -6, y: 0, duration: 0.04)
            ])
            monsterLabel?.run(shake, withKey: "mood")
        case .idle:
            break
        }
    }

    // MARK: - Touch / swap

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBusy, gameState?.outcome == .playing, gameState?.isPaused != true, let touch = touches.first else { return }
        guard let pos = position(at: touch.location(in: self)) else {
            clearSelection()
            return
        }

        if let selected = selectedPosition {
            if selected == pos {
                clearSelection()
                return
            }
            if selected.isAdjacent(to: pos) {
                attemptSwap(from: selected, to: pos)
            } else {
                select(pos)
            }
        } else {
            select(pos)
        }
    }

    private func select(_ pos: BoardPosition) {
        selectedPosition = pos
        selectionRing?.position = point(for: pos)
        selectionRing?.isHidden = false
        SoundManager.shared.playSelect()
        if let node = tileNodes[pos.row][pos.col] {
            node.run(.sequence([
                .scale(to: 1.12, duration: 0.08),
                .scale(to: 1.0, duration: 0.08)
            ]))
        }
    }

    private func clearSelection() {
        selectedPosition = nil
        selectionRing?.isHidden = true
    }

    private func attemptSwap(from: BoardPosition, to: BoardPosition) {
        guard let state = gameState else { return }
        clearSelection()

        guard state.board.wouldCreateMatch(swapping: from, with: to) else {
            // Visual bump then reject
            isBusy = true
            SoundManager.shared.playSwap()
            animateSwap(from: from, to: to, duration: 0.12) { [weak self] in
                self?.animateSwap(from: to, to: from, duration: 0.12) {
                    SoundManager.shared.playInvalid()
                    state.registerInvalidSwap()
                    self?.refreshHUD()
                    self?.isBusy = false
                }
            }
            return
        }

        isBusy = true
        SoundManager.shared.playSwap()
        state.board.swap(from, to)
        animateSwap(from: from, to: to, duration: 0.15) { [weak self] in
            self?.swapNodeReferences(from, to)
            state.registerSuccessfulSwap()
            self?.refreshHUD()
            self?.resolveMatches(cascadeDepth: 0)
        }
    }

    private func swapNodeReferences(_ a: BoardPosition, _ b: BoardPosition) {
        let temp = tileNodes[a.row][a.col]
        tileNodes[a.row][a.col] = tileNodes[b.row][b.col]
        tileNodes[b.row][b.col] = temp
        tileNodes[a.row][a.col]?.name = "snack_\(a.row)_\(a.col)"
        tileNodes[b.row][b.col]?.name = "snack_\(b.row)_\(b.col)"
    }

    private func animateSwap(from: BoardPosition, to: BoardPosition, duration: TimeInterval, completion: @escaping () -> Void) {
        let nodeA = tileNodes[from.row][from.col]
        let nodeB = tileNodes[to.row][to.col]
        let posA = point(for: from)
        let posB = point(for: to)

        let group = DispatchGroup()
        if let nodeA {
            group.enter()
            nodeA.zPosition = 15
            nodeA.run(.sequence([
                .group([
                    .move(to: posB, duration: duration),
                    .sequence([.scale(to: 1.12, duration: duration * 0.45), .scale(to: 1.0, duration: duration * 0.55)])
                ]),
                .run { nodeA.zPosition = 10; group.leave() }
            ]))
        }
        if let nodeB {
            group.enter()
            nodeB.run(.sequence([
                .group([
                    .move(to: posA, duration: duration),
                    .sequence([.scale(to: 0.92, duration: duration * 0.45), .scale(to: 1.0, duration: duration * 0.55)])
                ]),
                .run { group.leave() }
            ]))
        }
        group.notify(queue: .main, execute: completion)
    }

    // MARK: - Match resolution cascade

    private func resolveMatches(cascadeDepth: Int) {
        guard let state = gameState else {
            isBusy = false
            return
        }

        let groups = state.board.matchGroups()
        var matched = state.board.findMatches()

        guard !matched.isEmpty else {
            state.evaluateOutcome()
            refreshHUD()
            isBusy = false
            return
        }

        // Specials created by big groups (plant after clear on one cell)
        var spawn: (BoardPosition, SpecialKind, SnackType)?
        for group in groups {
            if let (pos, kind) = state.board.specialToSpawn(for: group),
               let snack = state.board.snack(at: pos) {
                spawn = (pos, kind, snack)
                break
            }
        }

        // Expand with special activations
        let specialsBefore = matched.filter { state.board.cell(at: $0)?.special != nil }.count
        matched = state.board.expandWithSpecials(matched)
        let specialsActivated = matched.filter { state.board.cell(at: $0)?.special != nil }.count

        // Count collect goals before clearing (after special expansion)
        if case .collect(let type, _) = state.level.goal {
            var count = 0
            for pos in matched {
                if state.board.snack(at: pos) == type { count += 1 }
            }
            state.countCollected(type: type, amount: count)
        }

        let points = BoardModel.score(
            for: groups,
            cascadeDepth: cascadeDepth,
            specialsActivated: max(specialsActivated, specialsBefore)
        )
        state.registerClear(positions: matched, cascadeDepth: cascadeDepth, points: points)
        SoundManager.shared.playMatch(cascadeDepth: cascadeDepth)

        // Particle juice
        spawnParticles(at: matched)

        // Pop matched tiles
        let popDuration: TimeInterval = 0.18
        let group = DispatchGroup()

        for pos in matched {
            // Keep spawn cell if we're planting a special there
            if let spawn, spawn.0 == pos { continue }
            guard let node = tileNodes[pos.row][pos.col] else { continue }
            tileNodes[pos.row][pos.col] = nil
            group.enter()
            node.popAway(duration: popDuration) {
                node.removeFromParent()
                group.leave()
            }
        }

        if cascadeDepth >= 1 || specialsActivated > 0 {
            let shake = SKAction.sequence([
                .moveBy(x: 4, y: 0, duration: 0.03),
                .moveBy(x: -8, y: 0, duration: 0.06),
                .moveBy(x: 4, y: 0, duration: 0.03)
            ])
            boardBackground?.run(shake)
        }

        spawnScorePopup(points, near: matched)
        state.board.clear(matched, spawnSpecial: spawn)

        // Visual for planted special
        if let spawn {
            SoundManager.shared.playSpecial()
            tileNodes[spawn.0.row][spawn.0.col]?.removeFromParent()
            let node = makeSnackNode(cell: BoardCell(snack: spawn.2, special: spawn.1), at: spawn.0)
            tileNodes[spawn.0.row][spawn.0.col] = node
            addChild(node)
            node.setScale(0.2)
            node.run(.sequence([
                .scale(to: 1.25, duration: 0.14),
                .scale(to: 0.92, duration: 0.08),
                .scale(to: 1.0, duration: 0.08)
            ]))
            // Burst ring
            let ring = SKShapeNode(circleOfRadius: tileSize * 0.55)
            ring.strokeColor = spawn.1.accent
            ring.lineWidth = 3
            ring.fillColor = .clear
            ring.position = point(for: spawn.0)
            ring.zPosition = 25
            ring.alpha = 0.9
            addChild(ring)
            ring.run(.sequence([
                .group([.scale(to: 1.8, duration: 0.28), .fadeOut(withDuration: 0.28)]),
                .removeFromParent()
            ]))
        }

        refreshHUD()

        group.notify(queue: .main) { [weak self] in
            self?.applyGravityAndRefill(cascadeDepth: cascadeDepth)
        }
    }

    private func spawnParticles(at positions: Set<BoardPosition>) {
        guard !positions.isEmpty else { return }
        for pos in positions.prefix(12) {
            let spark = SKLabelNode(text: "✨")
            spark.fontSize = 14
            spark.position = point(for: pos)
            spark.zPosition = 40
            spark.alpha = 0.9
            addChild(spark)
            let dx = CGFloat.random(in: -30...30)
            let dy = CGFloat.random(in: 20...50)
            spark.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.4),
                    .fadeOut(withDuration: 0.4),
                    .scale(to: 0.3, duration: 0.4)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func applyGravityAndRefill(cascadeDepth: Int) {
        guard let state = gameState else {
            isBusy = false
            return
        }

        let gravityMoves = state.board.applyGravity()
        let fallDuration: TimeInterval = 0.18
        let group = DispatchGroup()

        // Update node grid after gravity
        var newNodes: [[SnackNode?]] = Array(
            repeating: Array(repeating: nil, count: boardSize),
            count: boardSize
        )

        // Place remaining nodes at their pre-gravity positions first
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if let node = tileNodes[row][col] {
                    // Will be remapped via gravity moves
                    newNodes[row][col] = node
                }
            }
        }

        // Apply moves in reverse order of distance so we don't overwrite
        // Build destination map
        var destMap: [BoardPosition: BoardPosition] = [:] // from -> to
        for move in gravityMoves {
            destMap[move.from] = move.to
        }

        // Clear and rebuild node matrix from current physical nodes
        var working: [[SnackNode?]] = tileNodes
        var next: [[SnackNode?]] = Array(
            repeating: Array(repeating: nil, count: boardSize),
            count: boardSize
        )

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let from = BoardPosition(row: row, col: col)
                guard let node = working[row][col] else { continue }
                if let to = destMap[from] {
                    next[to.row][to.col] = node
                    node.name = "snack_\(to.row)_\(to.col)"
                    group.enter()
                    let target = point(for: to)
                    let distance = abs(to.row - from.row)
                    let duration = fallDuration + Double(distance) * 0.03
                    node.run(.sequence([
                        .move(to: target, duration: duration),
                        .scale(to: 1.08, duration: 0.05),
                        .scale(to: 1.0, duration: 0.05)
                    ])) { group.leave() }
                } else {
                    next[row][col] = node
                }
            }
        }
        tileNodes = next

        // Refill empties from above
        let spawned = state.board.refill()
        var maxFallDuration: TimeInterval = 0
        for item in spawned {
            let node = makeSnackNode(cell: item.cell, at: item.pos)
            // Start above the board
            let start = CGPoint(
                x: point(for: item.pos).x,
                y: boardOrigin.y + CGFloat(boardSize) * tileSize + tileSize
            )
            node.position = start
            node.setScale(0.8)
            addChild(node)
            tileNodes[item.pos.row][item.pos.col] = node

            group.enter()
            let distance = boardSize - item.pos.row
            let duration = fallDuration + Double(distance) * 0.025
            maxFallDuration = max(maxFallDuration, duration)
            node.run(.sequence([
                .group([
                    .move(to: point(for: item.pos), duration: duration),
                    .scale(to: 1.0, duration: duration)
                ]),
                .scale(to: 1.06, duration: 0.05),
                .scale(to: 1.0, duration: 0.05)
            ])) { group.leave() }
        }

        // Soft land thud once pieces settle.
        if !gravityMoves.isEmpty || !spawned.isEmpty {
            run(.sequence([
                .wait(forDuration: max(maxFallDuration, fallDuration) * 0.85),
                .run { SoundManager.shared.playLand() }
            ]))
        }

        // Silence unused warning
        _ = newNodes

        group.notify(queue: .main) { [weak self] in
            // Small delay then check for new matches
            self?.run(.wait(forDuration: 0.05)) {
                self?.resolveMatches(cascadeDepth: cascadeDepth + 1)
            }
        }
    }

    private func spawnScorePopup(_ points: Int, near positions: Set<BoardPosition>) {
        guard !positions.isEmpty else { return }
        let avgRow = positions.map(\.row).reduce(0, +) / positions.count
        let avgCol = positions.map(\.col).reduce(0, +) / positions.count
        let anchor = point(for: BoardPosition(row: avgRow, col: avgCol))

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "+\(points)"
        label.fontSize = 22
        label.fontColor = SKColor(red: 1, green: 0.95, blue: 0.4, alpha: 1)
        label.position = anchor
        label.zPosition = 50
        addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 40, duration: 0.55),
                .fadeOut(withDuration: 0.55),
                .scale(to: 1.3, duration: 0.55)
            ]),
            .removeFromParent()
        ]))
    }
}

// MARK: - Snack visual node

final class SnackNode: SKNode {
    let type: SnackType
    let special: SpecialKind?
    private let sprite: SKSpriteNode
    private let plate: SKShapeNode
    private let badgeSprite: SKSpriteNode?

    convenience init(type: SnackType, tileSize: CGFloat) {
        self.init(cell: BoardCell(snack: type), tileSize: tileSize)
    }

    init(cell: BoardCell, tileSize: CGFloat) {
        self.type = cell.snack
        self.special = cell.special

        let inset = tileSize * 0.06
        let plateSize = tileSize - inset * 2
        plate = SKShapeNode(
            rectOf: CGSize(width: plateSize, height: plateSize),
            cornerRadius: plateSize * 0.28
        )
        plate.fillColor = SKColor(white: 1, alpha: 0.10)
        plate.strokeColor = cell.special != nil
            ? (cell.special?.accent ?? .white)
            : SKColor(white: 1, alpha: 0.22)
        plate.lineWidth = cell.special != nil ? 2.4 : 1.2

        let texture = SKTexture(imageNamed: cell.snack.textureName)
        let hasArt = texture.size().width > 1
        if hasArt {
            sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: plateSize * 0.86, height: plateSize * 0.86)
        } else {
            // Fallback: solid color + emoji if texture missing
            sprite = SKSpriteNode(color: cell.snack.color, size: CGSize(width: plateSize * 0.86, height: plateSize * 0.86))
        }

        if cell.special != nil {
            let badgeTex = SKTexture(imageNamed: "Snack_special_star")
            if badgeTex.size().width > 1 {
                let badge = SKSpriteNode(texture: badgeTex)
                badge.size = CGSize(width: tileSize * 0.34, height: tileSize * 0.34)
                badge.position = CGPoint(x: tileSize * 0.28, y: tileSize * 0.28)
                badge.zPosition = 2
                badgeSprite = badge
            } else {
                badgeSprite = nil
            }
            plate.fillColor = SKColor(white: 1, alpha: 0.16)
        } else {
            badgeSprite = nil
        }

        super.init()
        addChild(plate)
        addChild(sprite)
        sprite.zPosition = 1
        if let badgeSprite { addChild(badgeSprite) }

        if !hasArt {
            let fallback = SKLabelNode(text: cell.snack.emoji)
            fallback.fontSize = tileSize * 0.45
            fallback.verticalAlignmentMode = .center
            fallback.horizontalAlignmentMode = .center
            fallback.zPosition = 3
            addChild(fallback)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func popAway(duration: TimeInterval, completion: @escaping () -> Void) {
        run(.sequence([
            .group([
                .scale(to: 1.28, duration: duration * 0.35),
                .fadeAlpha(to: 0.0, duration: duration),
                .rotate(byAngle: .pi / 8, duration: duration)
            ]),
            .run(completion)
        ]))
    }
}
