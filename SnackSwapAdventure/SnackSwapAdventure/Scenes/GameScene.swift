import SpriteKit
import UIKit

/// SpriteKit scene that renders the snack board and drives the match-3 loop.
final class GameScene: SKScene {

    // MARK: - Config

    /// Top chrome is SwiftUI GameHUD — leave room for the full panel.
    private let boardPadding: CGFloat = 8
    private let topHUDReserved: CGFloat = 286
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
    private var monsterNode: MonsterMascotNode?
    private var levelLabel: SKLabelNode?

    // MARK: - Lifecycle

    func configure(with state: GameState) {
        self.gameState = state
        self.boardSize = state.level.boardSize
    }

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.preferredFramesPerSecond = 60
        // Warm bakery night backdrop — less pure purple so snacks contrast better
        backgroundColor = SKColor(red: 0.16, green: 0.10, blue: 0.14, alpha: 1)
        rebuildBoard()
    }

    func rebuildBoard() {
        removeAllChildren()
        selectedPosition = nil
        isBusy = false
        lastAnnouncedOutcome = .playing

        guard let state = gameState else { return }
        boardSize = state.level.boardSize
        if state.board.findMatches().isEmpty, state.board.firstAvailableMove() == nil {
            _ = state.board.reshuffleToPlayable()
        }

        layoutMetrics()
        drawStageBackdrop()
        drawBoardFrame()
        buildTilesFromModel()
        buildHUD()
        refreshHUD()
        bounceInTiles()
        scheduleHint()
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
        let lowerAvailableY = bottomReserved
        let upperAvailableY = size.height - topHUDReserved
        let centeredY = lowerAvailableY + max(0, (usableHeight - boardPixel) / 2)
        let highestNonOverlappingY = upperAvailableY - boardPixel

        boardOrigin = CGPoint(
            x: (size.width - boardPixel) / 2,
            y: min(centeredY, highestNonOverlappingY)
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

    private func drawStageBackdrop() {
        let boardPixel = tileSize * CGFloat(boardSize)
        let topY = boardOrigin.y + boardPixel

        let backdrop = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        backdrop.fillColor = SKColor(red: 0.17, green: 0.09, blue: 0.13, alpha: 1)
        backdrop.strokeColor = .clear
        backdrop.zPosition = -20
        addChild(backdrop)

        let worldColors = worldPalette()
        for index in 0..<10 {
            let radius = CGFloat(3 + (index % 3) * 2)
            let crumb = SKShapeNode(circleOfRadius: radius)
            crumb.position = CGPoint(
                x: CGFloat((index * 47) % Int(max(size.width, 1))) + 8,
                y: CGFloat((index * 83) % Int(max(size.height, 1))) + 18
            )
            crumb.fillColor = worldColors.accent.withAlphaComponent(index.isMultiple(of: 2) ? 0.26 : 0.16)
            crumb.strokeColor = .clear
            crumb.zPosition = -18
            addChild(crumb)
        }

        for index in 0..<5 {
            let ribbon = SKShapeNode(
                rectOf: CGSize(width: size.width * 0.34, height: 5),
                cornerRadius: 2.5
            )
            ribbon.position = CGPoint(
                x: CGFloat(index) * size.width * 0.23 + 24,
                y: size.height - CGFloat(index) * 112 - 86
            )
            ribbon.zRotation = index.isMultiple(of: 2) ? -0.18 : 0.15
            ribbon.fillColor = worldColors.secondary.withAlphaComponent(0.10)
            ribbon.strokeColor = .clear
            ribbon.zPosition = -19
            addChild(ribbon)
        }

        let glow = SKShapeNode(ellipseOf: CGSize(width: boardPixel * 0.95, height: boardPixel * 0.28))
        glow.position = CGPoint(x: size.width / 2, y: boardOrigin.y - tileSize * 0.15)
        glow.fillColor = worldColors.accent.withAlphaComponent(0.14)
        glow.strokeColor = .clear
        glow.zPosition = -8
        addChild(glow)

        let stage = SKShapeNode(
            rect: CGRect(
                x: max(12, boardOrigin.x - 18),
                y: max(76, boardOrigin.y - 18),
                width: min(size.width - 24, boardPixel + 36),
                height: boardPixel + 36
            ),
            cornerRadius: 24
        )
        stage.fillColor = SKColor(red: 0.24, green: 0.14, blue: 0.18, alpha: 0.52)
        stage.strokeColor = worldColors.accent.withAlphaComponent(0.24)
        stage.lineWidth = 1
        stage.zPosition = -6
        addChild(stage)

        let titlePlate = SKShapeNode(
            rectOf: CGSize(width: min(size.width - 64, boardPixel * 0.82), height: 32),
            cornerRadius: 16
        )
        titlePlate.position = CGPoint(x: size.width / 2, y: topY + 20)
        titlePlate.fillColor = SKColor(red: 0.12, green: 0.07, blue: 0.10, alpha: 0.34)
        titlePlate.strokeColor = SKColor(white: 1, alpha: 0.08)
        titlePlate.lineWidth = 1
        titlePlate.zPosition = -5
        addChild(titlePlate)
    }

    private func worldPalette() -> (accent: SKColor, secondary: SKColor) {
        guard let state = gameState else {
            return (
                SKColor(red: 1.0, green: 0.58, blue: 0.25, alpha: 1),
                SKColor(red: 1.0, green: 0.34, blue: 0.55, alpha: 1)
            )
        }
        switch state.level.levelNumber {
        case 1...10:
            return (
                SKColor(red: 1.0, green: 0.66, blue: 0.34, alpha: 1),
                SKColor(red: 0.62, green: 0.34, blue: 0.22, alpha: 1)
            )
        case 11...20:
            return (
                SKColor(red: 1.0, green: 0.84, blue: 0.30, alpha: 1),
                SKColor(red: 0.54, green: 0.72, blue: 0.38, alpha: 1)
            )
        default:
            return (
                SKColor(red: 1.0, green: 0.35, blue: 0.72, alpha: 1),
                SKColor(red: 0.48, green: 0.40, blue: 1.0, alpha: 1)
            )
        }
    }

    private func drawBoardFrame() {
        let boardPixel = tileSize * CGFloat(boardSize)
        let rect = CGRect(
            x: boardOrigin.x - 6,
            y: boardOrigin.y - 6,
            width: boardPixel + 12,
            height: boardPixel + 12
        )
        let frame = SKShapeNode(rect: rect, cornerRadius: 18)
        // Lighter bakery tray so dark snacks (and any dark frosting) pop forward
        frame.fillColor = SKColor(red: 0.42, green: 0.34, blue: 0.40, alpha: 1)
        frame.strokeColor = SKColor(red: 0.72, green: 0.55, blue: 0.48, alpha: 1)
        frame.lineWidth = 3
        frame.zPosition = 0
        addChild(frame)
        boardBackground = frame

        let innerGlow = SKShapeNode(rect: rect.insetBy(dx: 8, dy: 8), cornerRadius: 14)
        innerGlow.fillColor = .clear
        innerGlow.strokeColor = SKColor(white: 1, alpha: 0.13)
        innerGlow.lineWidth = 2
        innerGlow.glowWidth = 2
        innerGlow.zPosition = 0.5
        addChild(innerGlow)

        for index in 0..<12 {
            let rivet = SKShapeNode(circleOfRadius: 2.2)
            let t = CGFloat(index) / 11
            let onTop = index < 6
            rivet.position = CGPoint(
                x: rect.minX + 22 + t * (rect.width - 44),
                y: onTop ? rect.maxY - 9 : rect.minY + 9
            )
            rivet.fillColor = SKColor(red: 1.0, green: 0.79, blue: 0.54, alpha: 0.38)
            rivet.strokeColor = .clear
            rivet.zPosition = 2
            addChild(rivet)
        }

        // High-contrast checker slots — desaturated gray-lavender, clearly lighter than snacks
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let cell = SKShapeNode(
                    rectOf: CGSize(width: tileSize - 3, height: tileSize - 3),
                    cornerRadius: 10
                )
                let even = (row + col) % 2 == 0
                // Light gray-purple slots (empty wells)
                cell.fillColor = even
                    ? SKColor(red: 0.58, green: 0.50, blue: 0.56, alpha: 1)
                    : SKColor(red: 0.50, green: 0.43, blue: 0.50, alpha: 1)
                cell.strokeColor = SKColor(white: 1, alpha: 0.12)
                cell.lineWidth = 1
                cell.position = point(for: BoardPosition(row: row, col: col))
                cell.zPosition = 1
                addChild(cell)
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
        // Stagger idle so the board feels alive, not synchronized.
        let phase = Double((pos.row * 3 + pos.col * 5) % 17) * 0.07
        let featured = cell.special != nil || (pos.row + pos.col) % 5 == 0
        node.startLiveEffects(phaseOffset: phase, featured: featured)
        return node
    }

    private func buildHUD() {
        // Top stats live in SwiftUI GameHUD. SpriteKit only keeps bottom feedback + selection.
        levelLabel = nil
        movesLabel = nil
        scoreLabel = nil
        goalLabel = nil

        let messagePlate = SKShapeNode(rectOf: CGSize(width: min(size.width - 72, 270), height: 34), cornerRadius: 17)
        messagePlate.position = CGPoint(x: size.width / 2, y: 28)
        messagePlate.fillColor = SKColor(red: 0.12, green: 0.07, blue: 0.10, alpha: 0.40)
        messagePlate.strokeColor = SKColor(white: 1, alpha: 0.08)
        messagePlate.lineWidth = 1
        messagePlate.zPosition = 98
        addChild(messagePlate)

        monsterLabel = SKLabelNode(text: "👾")
        monsterLabel?.fontSize = 1
        monsterLabel?.verticalAlignmentMode = .center
        monsterLabel?.horizontalAlignmentMode = .center
        monsterLabel?.position = CGPoint(x: size.width / 2, y: 66)
        monsterLabel?.zPosition = 100
        if let monsterLabel { addChild(monsterLabel) }

        let mascot = MonsterMascotNode(size: 58)
        mascot.position = CGPoint(x: size.width / 2, y: 70)
        mascot.zPosition = 101
        addChild(mascot)
        monsterNode = mascot

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
                // Keep every well represented during the entrance animation;
                // scaling from a readable size avoids a screenshot catching a
                // fully empty slot while the scene is still settling.
                node.setScale(0.86)
                node.alpha = 1
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
        monsterLabel?.text = ""
        monsterNode?.setMood(state.monsterMood)

        // Play win/lose once when outcome flips.
        if lastAnnouncedOutcome == .playing || lastAnnouncedOutcome == .timedOut {
            switch state.outcome {
            case .won:
                SoundManager.shared.playWin()
                VoiceAnnouncer.shared.praiseWin()
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
            monsterNode?.celebrate()
        case .sad:
            let shake = SKAction.sequence([
                .moveBy(x: -6, y: 0, duration: 0.04),
                .moveBy(x: 12, y: 0, duration: 0.08),
                .moveBy(x: -6, y: 0, duration: 0.04)
            ])
            monsterLabel?.run(shake, withKey: "mood")
            monsterNode?.sadWobble()
        case .idle:
            break
        }
    }

    // MARK: - Touch / swap

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBusy, gameState?.outcome == .playing, gameState?.isPaused != true, let touch = touches.first else { return }
        scheduleHint()
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
        spawnTapRipple(at: pos, color: SKColor(red: 1.0, green: 0.78, blue: 0.86, alpha: 1))
        if let node = tileNodes[pos.row][pos.col] {
            node.pressPulse()
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
            animateTapNudge(from: from, toward: to)
            animateTapNudge(from: to, toward: from)
            animateSwap(from: from, to: to, duration: 0.12) { [weak self] in
                self?.animateSwap(from: to, to: from, duration: 0.12) {
                    SoundManager.shared.playInvalid()
                    self?.spawnInvalidTapFeedback(at: to)
                    state.registerInvalidSwap()
                    self?.refreshHUD()
                    self?.isBusy = false
                }
            }
            return
        }

        isBusy = true
        SoundManager.shared.playSwap()
        animateTapNudge(from: from, toward: to)
        animateTapNudge(from: to, toward: from)
        let activatesSpecial = state.board.cell(at: from)?.special != nil
            || state.board.cell(at: to)?.special != nil
        state.board.swap(from, to)
        animateSwap(from: from, to: to, duration: 0.15) { [weak self] in
            self?.swapNodeReferences(from, to)
            state.registerSuccessfulSwap()
            self?.refreshHUD()
            self?.resolveMatches(
                cascadeDepth: 0,
                forcedPositions: activatesSpecial ? Set([from, to]) : []
            )
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

    private func animateTapNudge(from: BoardPosition, toward: BoardPosition) {
        guard let node = tileNodes[from.row][from.col] else { return }
        let origin = point(for: from)
        let target = point(for: toward)
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let length = max(1, hypot(dx, dy))
        let nudge = CGPoint(
            x: origin.x + dx / length * tileSize * 0.09,
            y: origin.y + dy / length * tileSize * 0.09
        )
        node.removeAction(forKey: "tapNudge")
        node.run(.sequence([
            .move(to: nudge, duration: 0.045),
            .move(to: origin, duration: 0.07)
        ]), withKey: "tapNudge")
    }

    private func spawnTapRipple(at pos: BoardPosition, color: SKColor) {
        let ring = SKShapeNode(circleOfRadius: tileSize * 0.34)
        ring.position = point(for: pos)
        ring.strokeColor = color.withAlphaComponent(0.85)
        ring.lineWidth = 2
        ring.glowWidth = 3
        ring.fillColor = .clear
        ring.zPosition = 30
        addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 1.55, duration: 0.22),
                .fadeOut(withDuration: 0.22)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnInvalidTapFeedback(at pos: BoardPosition) {
        spawnTapRipple(at: pos, color: SKColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1))
        guard let node = tileNodes[pos.row][pos.col] else { return }
        node.removeAction(forKey: "invalidWobble")
        node.run(.sequence([
            .rotate(toAngle: -0.13, duration: 0.045),
            .rotate(toAngle: 0.13, duration: 0.07),
            .rotate(toAngle: -0.08, duration: 0.055),
            .rotate(toAngle: 0, duration: 0.045)
        ]), withKey: "invalidWobble")
    }

    // MARK: - Match resolution cascade

    private func resolveMatches(cascadeDepth: Int, forcedPositions: Set<BoardPosition> = []) {
        guard let state = gameState else {
            isBusy = false
            return
        }

        let groups = state.board.matchGroups()
        var matched = state.board.findMatches()
        matched.formUnion(forcedPositions)

        guard !matched.isEmpty else {
            state.finishMoveResolution()
            state.evaluateOutcome()
            refreshHUD()
            if state.outcome == .playing, state.board.firstAvailableMove() == nil {
                reshufflePlayableBoard()
                return
            }
            isBusy = false
            scheduleHint()
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
        let reward = state.registerClear(
            positions: matched,
            cascadeDepth: cascadeDepth,
            points: points,
            specialsActivated: max(specialsActivated, specialsBefore)
        )
        SoundManager.shared.playMatch(cascadeDepth: cascadeDepth)
        VoiceAnnouncer.shared.praiseMatch(
            cascadeDepth: cascadeDepth,
            matchedCount: matched.count,
            specialsActivated: specialsActivated
        )

        // Expressive combo callout for 2x+
        if cascadeDepth >= 1 {
            spawnComboBanner(multiplier: cascadeDepth + 1, near: matched)
        }
        if reward.multiplier > 1 {
            spawnComboBanner(multiplier: reward.multiplier, near: matched, prefix: "SUGAR RUSH")
        }
        if reward.streakBonus > 0 {
            spawnStreakBadge(streak: state.streakCount, near: matched)
        }
        if reward.feverActivated {
            spawnFeverCelebration()
        }

        // Particle juice
        spawnParticles(at: matched)
        spawnSnackBurst(at: matched)

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
            shakeBoard(strength: specialsActivated > 0 ? 8 : 4)
        }

        spawnScorePopup(reward.awardedPoints, near: matched)
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

    private func spawnSnackBurst(at positions: Set<BoardPosition>) {
        for pos in positions.prefix(10) {
            let center = point(for: pos)
            let snack = gameState?.board.snack(at: pos)
            let color = snack?.color ?? SKColor(red: 1, green: 0.82, blue: 0.35, alpha: 1)
            for index in 0..<5 {
                let crumb = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...4.0))
                crumb.fillColor = index.isMultiple(of: 2) ? color : SKColor(white: 1, alpha: 0.95)
                crumb.strokeColor = .clear
                crumb.position = center
                crumb.zPosition = 42
                addChild(crumb)

                let angle = CGFloat(index) / 5 * .pi * 2 + CGFloat.random(in: -0.25...0.25)
                let distance = CGFloat.random(in: tileSize * 0.25...tileSize * 0.75)
                crumb.run(.sequence([
                    .group([
                        .moveBy(x: cos(angle) * distance, y: sin(angle) * distance + 12, duration: 0.34),
                        .scale(to: 0.2, duration: 0.34),
                        .fadeOut(withDuration: 0.34)
                    ]),
                    .removeFromParent()
                ]))
            }

            if let snack {
                let emoji = SKLabelNode(text: snack.emoji)
                emoji.fontSize = tileSize * 0.28
                emoji.position = center
                emoji.zPosition = 43
                addChild(emoji)
                emoji.run(.sequence([
                    .group([
                        .moveBy(x: CGFloat.random(in: -14...14), y: tileSize * 0.45, duration: 0.38),
                        .rotate(byAngle: CGFloat.random(in: -0.8...0.8), duration: 0.38),
                        .fadeOut(withDuration: 0.38)
                    ]),
                    .removeFromParent()
                ]))
            }
        }
    }

    private func shakeBoard(strength: CGFloat) {
        let shake = SKAction.sequence([
            .moveBy(x: strength, y: 0, duration: 0.025),
            .moveBy(x: -strength * 2, y: 0, duration: 0.05),
            .moveBy(x: strength, y: 0, duration: 0.025)
        ])
        boardBackground?.run(shake)
    }

    private func applyGravityAndRefill(cascadeDepth: Int) {
        guard let state = gameState else {
            isBusy = false
            return
        }

        // Update the model first, then rebuild the visual matrix from it. The
        // previous incremental source/destination mapping could assign a node
        // twice during fast cascades, producing both holes and overlaps.
        let gravityMoves = state.board.applyGravity()
        let spawned = state.board.refill()

        // Purge every snack node attached to the scene, not only the nodes in
        // the matrix. A completed pop or special animation can otherwise leave
        // an orphan node behind for one frame, which is how overlaps persisted.
        let oldNodes = children.compactMap { $0 as? SnackNode }
        oldNodes.forEach { node in
            node.removeAllActions()
            node.removeFromParent()
        }

        tileNodes = Array(
            repeating: Array(repeating: nil, count: boardSize),
            count: boardSize
        )

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let pos = BoardPosition(row: row, col: col)
                guard let cell = state.board.cell(at: pos) else { continue }
                let node = makeSnackNode(cell: cell, at: pos)
                node.position = point(for: pos)
                // The model is already settled when this method runs. Keep the
                // full matrix visible immediately so cascades never expose
                // permanent-looking empty wells between animation frames.
                node.setScale(1.0)
                node.alpha = 1.0
                tileNodes[row][col] = node
                addChild(node)

                node.run(.sequence([
                    .scale(to: 1.06, duration: 0.08),
                    .scale(to: 0.98, duration: 0.06),
                    .scale(to: 1.0, duration: 0.06)
                ]))
            }
        }

        if !gravityMoves.isEmpty || !spawned.isEmpty {
            run(.sequence([
                .wait(forDuration: 0.32),
                .run { SoundManager.shared.playLand() }
            ]))
        }

        run(.sequence([
            .wait(forDuration: 0.45),
            .run { [weak self] in
                self?.resolveMatches(cascadeDepth: cascadeDepth + 1)
            }
        ]), withKey: "cascadeResolution")
    }

    // MARK: - Player guidance and dead-board recovery

    private func scheduleHint() {
        removeAction(forKey: "hintTimer")
        clearHint()
        guard gameState?.outcome == .playing, gameState?.isPaused != true else { return }
        run(.sequence([
            .wait(forDuration: 6.0),
            .run { [weak self] in self?.showHint() }
        ]), withKey: "hintTimer")
    }

    private func showHint() {
        guard !isBusy, let state = gameState, state.outcome == .playing,
              let move = state.board.firstAvailableMove() else { return }

        clearHint()
        for pos in [move.from, move.to] {
            tileNodes[pos.row][pos.col]?.hintPulse()

            let ring = SKShapeNode(
                rectOf: CGSize(width: tileSize - 8, height: tileSize - 8),
                cornerRadius: 11
            )
            ring.name = "hintRing"
            ring.position = point(for: pos)
            ring.fillColor = .clear
            ring.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.32, alpha: 0.95)
            ring.lineWidth = 2.5
            ring.glowWidth = 4
            ring.zPosition = 24
            addChild(ring)
            ring.run(.repeatForever(.sequence([
                .group([
                    .scale(to: 1.08, duration: 0.42),
                    .fadeAlpha(to: 0.45, duration: 0.42)
                ]),
                .group([
                    .scale(to: 1.0, duration: 0.42),
                    .fadeAlpha(to: 0.95, duration: 0.42)
                ])
            ])))
        }
        SoundManager.shared.playSelect()
    }

    private func clearHint() {
        enumerateChildNodes(withName: "hintRing") { node, _ in
            node.removeAllActions()
            node.removeFromParent()
        }
        let nodes = tileNodes.reduce(into: [SnackNode]()) { result, row in
            result.append(contentsOf: row.compactMap { $0 })
        }
        nodes.forEach { $0.clearHintPulse() }
    }

    private func reshufflePlayableBoard() {
        guard let state = gameState, state.outcome == .playing else {
            isBusy = false
            return
        }

        isBusy = true
        clearSelection()
        clearHint()
        _ = state.board.reshuffleToPlayable()

        let oldNodes = tileNodes.flatMap { $0 }.compactMap { $0 }
        oldNodes.forEach { node in
            node.run(.sequence([
                .group([
                    .scale(to: 0.72, duration: 0.16),
                    .fadeOut(withDuration: 0.16)
                ]),
                .removeFromParent()
            ]))
        }

        let banner = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        banner.text = "BOARD SHUFFLED!"
        banner.fontSize = 19
        banner.fontColor = SKColor(red: 1.0, green: 0.86, blue: 0.32, alpha: 1)
        banner.position = CGPoint(x: size.width / 2, y: boardOrigin.y + tileSize * CGFloat(boardSize) * 0.5)
        banner.zPosition = 60
        banner.alpha = 0
        addChild(banner)
        banner.run(.sequence([
            .wait(forDuration: 0.16),
            .group([
                .fadeIn(withDuration: 0.12),
                .scale(to: 1.08, duration: 0.25)
            ]),
            .wait(forDuration: 0.20),
            .group([
                .moveBy(x: 0, y: 24, duration: 0.28),
                .fadeOut(withDuration: 0.28)
            ]),
            .removeFromParent()
        ]))

        run(.sequence([
            .wait(forDuration: 0.22),
            .run { [weak self] in
                guard let self else { return }
                self.tileNodes = Array(
                    repeating: Array(repeating: nil, count: self.boardSize),
                    count: self.boardSize
                )
                self.buildTilesFromModel()
                self.bounceInTiles()
            },
            .wait(forDuration: 0.65),
            .run { [weak self] in
                self?.isBusy = false
                self?.scheduleHint()
            }
        ]), withKey: "reshuffle")
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

        for index in 0..<min(6, max(1, points / 60)) {
            let chip = SKLabelNode(text: index.isMultiple(of: 2) ? "★" : "+")
            chip.fontName = "AvenirNext-Heavy"
            chip.fontSize = 12
            chip.fontColor = SKColor(red: 1, green: 0.82, blue: 0.25, alpha: 1)
            chip.position = anchor
            chip.zPosition = 49
            addChild(chip)
            chip.run(.sequence([
                .wait(forDuration: Double(index) * 0.025),
                .group([
                    .moveBy(x: CGFloat.random(in: -34...34), y: CGFloat.random(in: 18...58), duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                    .scale(to: 0.4, duration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnComboBanner(multiplier: Int, near positions: Set<BoardPosition>, prefix: String = "COMBO") {
        guard !positions.isEmpty else { return }
        let avgRow = positions.map(\.row).reduce(0, +) / positions.count
        let avgCol = positions.map(\.col).reduce(0, +) / positions.count
        var anchor = point(for: BoardPosition(row: avgRow, col: avgCol))
        anchor.y += tileSize * 0.6

        let text: String
        let color: SKColor
        switch multiplier {
        case 2:
            text = "\(prefix) x2!"
            color = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        case 3:
            text = "\(prefix) x3!!"
            color = SKColor(red: 1, green: 0.55, blue: 0.2, alpha: 1)
        case 4:
            text = "\(prefix) x4!!!"
            color = SKColor(red: 1, green: 0.35, blue: 0.55, alpha: 1)
        case 5:
            text = "INSANE x5!"
            color = SKColor(red: 0.7, green: 0.4, blue: 1, alpha: 1)
        default:
            text = "MEGA x\(multiplier)!"
            color = SKColor(red: 0.4, green: 1, blue: 0.75, alpha: 1)
        }

        let label = SKLabelNode(fontNamed: "AvenirNext-Black")
        label.text = text
        label.fontSize = multiplier >= 4 ? 28 : 24
        label.fontColor = color
        label.position = anchor
        label.zPosition = 55
        label.setScale(0.4)
        addChild(label)

        label.run(.sequence([
            .group([
                .scale(to: 1.25, duration: 0.14),
                .moveBy(x: 0, y: 28, duration: 0.7)
            ]),
            .group([
                .scale(to: 1.0, duration: 0.1),
                .fadeOut(withDuration: 0.35)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnStreakBadge(streak: Int, near positions: Set<BoardPosition>) {
        guard !positions.isEmpty else { return }
        let avgRow = positions.map(\.row).reduce(0, +) / positions.count
        let avgCol = positions.map(\.col).reduce(0, +) / positions.count
        var anchor = point(for: BoardPosition(row: avgRow, col: avgCol))
        anchor.y -= tileSize * 0.35

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "\(streak) STREAK"
        label.fontSize = 15
        label.fontColor = SKColor(red: 1.0, green: 0.78, blue: 0.86, alpha: 1)
        label.position = anchor
        label.zPosition = 56
        label.alpha = 0
        addChild(label)

        label.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.08),
                .scale(to: 1.18, duration: 0.12)
            ]),
            .wait(forDuration: 0.22),
            .group([
                .moveBy(x: 0, y: -20, duration: 0.35),
                .fadeOut(withDuration: 0.35),
                .scale(to: 0.9, duration: 0.35)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnFeverCelebration() {
        let flash = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        flash.fillColor = SKColor(red: 1.0, green: 0.46, blue: 0.62, alpha: 0.18)
        flash.strokeColor = .clear
        flash.zPosition = 90
        addChild(flash)
        flash.run(.sequence([
            .fadeOut(withDuration: 0.35),
            .removeFromParent()
        ]))

        let label = SKLabelNode(fontNamed: "AvenirNext-Black")
        label.text = "SUGAR RUSH!"
        label.fontSize = 32
        label.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.25, alpha: 1)
        label.position = CGPoint(x: size.width / 2, y: boardOrigin.y + tileSize * CGFloat(boardSize) + 28)
        label.zPosition = 95
        label.setScale(0.35)
        addChild(label)

        label.run(.sequence([
            .group([
                .scale(to: 1.16, duration: 0.18),
                .moveBy(x: 0, y: 14, duration: 0.18)
            ]),
            .wait(forDuration: 0.38),
            .group([
                .fadeOut(withDuration: 0.35),
                .moveBy(x: 0, y: 20, duration: 0.35),
                .scale(to: 0.92, duration: 0.35)
            ]),
            .removeFromParent()
        ]))

        for index in 0..<14 {
            let spark = SKLabelNode(text: index.isMultiple(of: 3) ? "🍬" : "✨")
            spark.fontSize = CGFloat.random(in: 13...19)
            spark.position = CGPoint(x: size.width / 2, y: boardOrigin.y + tileSize * CGFloat(boardSize) + 22)
            spark.zPosition = 96
            addChild(spark)
            spark.run(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -size.width * 0.42...size.width * 0.42), y: CGFloat.random(in: -30...90), duration: 0.55),
                    .fadeOut(withDuration: 0.55),
                    .rotate(byAngle: CGFloat.random(in: -1.8...1.8), duration: 0.55)
                ]),
                .removeFromParent()
            ]))
        }
    }
}

// MARK: - Monster mascot

final class MonsterMascotNode: SKNode {
    private let body: SKShapeNode
    private let belly: SKShapeNode
    private let leftEye: SKShapeNode
    private let rightEye: SKShapeNode
    private let mouth: SKShapeNode
    private let leftAntenna: SKShapeNode
    private let rightAntenna: SKShapeNode
    private let sizeValue: CGFloat

    init(size: CGFloat) {
        self.sizeValue = size
        body = SKShapeNode(rectOf: CGSize(width: size, height: size * 0.78), cornerRadius: size * 0.16)
        belly = SKShapeNode(ellipseOf: CGSize(width: size * 0.36, height: size * 0.20))
        leftEye = SKShapeNode(circleOfRadius: size * 0.055)
        rightEye = SKShapeNode(circleOfRadius: size * 0.055)
        mouth = SKShapeNode(rectOf: CGSize(width: size * 0.24, height: size * 0.055), cornerRadius: size * 0.025)
        leftAntenna = SKShapeNode(rectOf: CGSize(width: size * 0.08, height: size * 0.30), cornerRadius: size * 0.04)
        rightAntenna = SKShapeNode(rectOf: CGSize(width: size * 0.08, height: size * 0.30), cornerRadius: size * 0.04)
        super.init()

        let shadow = SKShapeNode(ellipseOf: CGSize(width: size * 0.88, height: size * 0.18))
        shadow.fillColor = SKColor(white: 0, alpha: 0.28)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -size * 0.48)
        shadow.zPosition = -1
        addChild(shadow)

        body.fillColor = SKColor(red: 0.55, green: 0.40, blue: 0.95, alpha: 1)
        body.strokeColor = SKColor(red: 0.22, green: 0.17, blue: 0.38, alpha: 1)
        body.lineWidth = 3
        body.zPosition = 1
        addChild(body)

        belly.fillColor = SKColor(red: 0.74, green: 0.58, blue: 1.0, alpha: 0.55)
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -size * 0.10)
        belly.zPosition = 2
        addChild(belly)

        for eye in [leftEye, rightEye] {
            eye.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.12, alpha: 1)
            eye.strokeColor = .clear
            eye.zPosition = 3
            addChild(eye)
        }
        leftEye.position = CGPoint(x: -size * 0.16, y: size * 0.07)
        rightEye.position = CGPoint(x: size * 0.16, y: size * 0.07)

        mouth.fillColor = SKColor(red: 0.12, green: 0.06, blue: 0.12, alpha: 1)
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: 0, y: -size * 0.14)
        mouth.zPosition = 3
        addChild(mouth)

        for (antenna, x, angle) in [(leftAntenna, -size * 0.28, -0.52), (rightAntenna, size * 0.28, 0.52)] {
            antenna.fillColor = body.fillColor
            antenna.strokeColor = body.strokeColor
            antenna.lineWidth = 2
            antenna.position = CGPoint(x: x, y: size * 0.43)
            antenna.zRotation = angle
            antenna.zPosition = 0
            addChild(antenna)
        }

        let footY = -size * 0.45
        for x in [-size * 0.22, size * 0.22] {
            let foot = SKShapeNode(rectOf: CGSize(width: size * 0.16, height: size * 0.10), cornerRadius: size * 0.03)
            foot.fillColor = body.fillColor
            foot.strokeColor = body.strokeColor
            foot.lineWidth = 2
            foot.position = CGPoint(x: x, y: footY)
            foot.zPosition = 0
            addChild(foot)
        }

        runIdle()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMood(_ mood: MonsterMood) {
        switch mood {
        case .idle:
            body.fillColor = SKColor(red: 0.55, green: 0.40, blue: 0.95, alpha: 1)
            mouth.setScale(1)
        case .happy:
            body.fillColor = SKColor(red: 0.61, green: 0.45, blue: 1.0, alpha: 1)
            mouth.setScale(1.25)
        case .ecstatic:
            body.fillColor = SKColor(red: 0.72, green: 0.46, blue: 1.0, alpha: 1)
            mouth.setScale(1.45)
        case .sad:
            body.fillColor = SKColor(red: 0.38, green: 0.34, blue: 0.64, alpha: 1)
            mouth.setScale(0.75)
        }
    }

    func celebrate() {
        removeAction(forKey: "celebrate")
        run(.sequence([
            .group([
                .scale(to: 1.18, duration: 0.10),
                .moveBy(x: 0, y: sizeValue * 0.10, duration: 0.10)
            ]),
            .group([
                .scale(to: 1.0, duration: 0.14),
                .moveBy(x: 0, y: -sizeValue * 0.10, duration: 0.14)
            ])
        ]), withKey: "celebrate")
    }

    func sadWobble() {
        removeAction(forKey: "sad")
        run(.sequence([
            .rotate(toAngle: -0.10, duration: 0.06),
            .rotate(toAngle: 0.10, duration: 0.10),
            .rotate(toAngle: 0, duration: 0.06)
        ]), withKey: "sad")
    }

    private func runIdle() {
        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3, duration: 0.75),
            .moveBy(x: 0, y: -3, duration: 0.75)
        ])), withKey: "idle")
        leftAntenna.run(.repeatForever(.sequence([
            .rotate(toAngle: -0.64, duration: 0.9),
            .rotate(toAngle: -0.46, duration: 0.9)
        ])), withKey: "wiggle")
        rightAntenna.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.64, duration: 0.9),
            .rotate(toAngle: 0.46, duration: 0.9)
        ])), withKey: "wiggle")
    }
}

// MARK: - Snack visual node (live candy look)

final class SnackNode: SKNode {
    let type: SnackType
    let special: SpecialKind?
    private let tileSize: CGFloat
    private let contentRoot = SKNode()
    private let shadow: SKShapeNode
    private let plate: SKShapeNode
    private let sprite: SKSpriteNode
    private let gloss: SKShapeNode
    private let sheen: SKShapeNode
    private let rimLight: SKShapeNode
    private let badgeSprite: SKSpriteNode?
    private var liveStarted = false

    convenience init(type: SnackType, tileSize: CGFloat) {
        self.init(cell: BoardCell(snack: type), tileSize: tileSize)
    }

    init(cell: BoardCell, tileSize: CGFloat) {
        self.type = cell.snack
        self.special = cell.special
        self.tileSize = tileSize

        let inset = tileSize * 0.05
        let plateSize = tileSize - inset * 2
        let snackSize = plateSize * 0.90

        // Soft ground shadow for depth
        shadow = SKShapeNode(ellipseOf: CGSize(width: snackSize * 0.72, height: snackSize * 0.22))
        shadow.fillColor = SKColor(white: 0, alpha: 0.28)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -snackSize * 0.34)
        shadow.zPosition = 0

        // Subtle plate / tile seat
        plate = SKShapeNode(
            rectOf: CGSize(width: plateSize, height: plateSize),
            cornerRadius: plateSize * 0.30
        )
        // Slightly brighter plate seat so snack sprites separate from board wells
        plate.fillColor = SKColor(white: 1, alpha: cell.special != nil ? 0.20 : 0.14)
        plate.strokeColor = cell.special != nil
            ? (cell.special?.accent.withAlphaComponent(0.95) ?? .white)
            : SKColor(white: 1, alpha: 0.28)
        plate.lineWidth = cell.special != nil ? 2.2 : 1.15
        plate.zPosition = 1

        let texture = SKTexture(imageNamed: cell.snack.textureName)
        texture.filteringMode = .linear
        let hasArt = texture.size().width > 1
        if hasArt {
            sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: snackSize, height: snackSize)
        } else {
            sprite = SKSpriteNode(color: cell.snack.color, size: CGSize(width: snackSize, height: snackSize))
        }
        sprite.zPosition = 2

        // Specular oval highlight (candy glaze)
        gloss = SKShapeNode(ellipseOf: CGSize(width: snackSize * 0.42, height: snackSize * 0.22))
        gloss.fillColor = SKColor(white: 1, alpha: 0.38)
        gloss.strokeColor = .clear
        gloss.position = CGPoint(x: -snackSize * 0.12, y: snackSize * 0.22)
        gloss.zPosition = 3
        gloss.alpha = 0.85

        // Moving sheen stripe for "live" light
        sheen = SKShapeNode(rectOf: CGSize(width: snackSize * 0.18, height: snackSize * 0.95), cornerRadius: 6)
        sheen.fillColor = SKColor(white: 1, alpha: 0.22)
        sheen.strokeColor = .clear
        sheen.zRotation = .pi / 7
        sheen.position = CGPoint(x: -snackSize * 0.55, y: 0)
        sheen.zPosition = 4
        sheen.alpha = 0

        // Soft rim light for volume
        rimLight = SKShapeNode(circleOfRadius: snackSize * 0.48)
        rimLight.fillColor = .clear
        rimLight.strokeColor = SKColor(white: 1, alpha: 0.16)
        rimLight.lineWidth = 2
        rimLight.glowWidth = 1.5
        rimLight.zPosition = 2.5

        if cell.special != nil {
            let badgeTex = SKTexture(imageNamed: "Snack_special_star")
            badgeTex.filteringMode = .linear
            if badgeTex.size().width > 1 {
                let badge = SKSpriteNode(texture: badgeTex)
                badge.size = CGSize(width: tileSize * 0.36, height: tileSize * 0.36)
                badge.position = CGPoint(x: tileSize * 0.30, y: tileSize * 0.30)
                badge.zPosition = 6
                badgeSprite = badge
            } else {
                badgeSprite = nil
            }
            plate.fillColor = SKColor(white: 1, alpha: 0.18)
            rimLight.strokeColor = (cell.special?.accent ?? .white).withAlphaComponent(0.55)
            rimLight.glowWidth = 4
        } else {
            badgeSprite = nil
        }

        super.init()

        addChild(shadow)
        contentRoot.zPosition = 1
        addChild(contentRoot)
        contentRoot.addChild(plate)
        contentRoot.addChild(sprite)
        contentRoot.addChild(rimLight)
        contentRoot.addChild(gloss)
        contentRoot.addChild(sheen)
        if let badgeSprite { contentRoot.addChild(badgeSprite) }

        if !hasArt {
            let fallback = SKLabelNode(text: cell.snack.emoji)
            fallback.fontSize = tileSize * 0.45
            fallback.verticalAlignmentMode = .center
            fallback.horizontalAlignmentMode = .center
            fallback.zPosition = 5
            contentRoot.addChild(fallback)
        }

        // Clip sheen roughly to snack area via crop is heavy; keep free-moving sheen subtle.
        sheen.alpha = 0
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Lightweight idle effects. Only featured tiles and specials animate continuously.
    func startLiveEffects(phaseOffset: TimeInterval = 0, featured: Bool) {
        guard !liveStarted else { return }
        liveStarted = true

        guard featured || special != nil else {
            gloss.alpha = 0.48
            sheen.isHidden = true
            return
        }

        let breatheIn = SKAction.scale(to: special == nil ? 1.018 : 1.035, duration: 1.15 + phaseOffset * 0.15)
        let breatheOut = SKAction.scale(to: special == nil ? 0.992 : 0.985, duration: 1.1)
        let breathe = SKAction.sequence([breatheIn, breatheOut])
        contentRoot.run(SKAction.repeatForever(breathe), withKey: "idle")

        // Gloss twinkle
        let glossPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.52, duration: 0.9),
            SKAction.fadeAlpha(to: special == nil ? 0.78 : 0.95, duration: 0.7),
            SKAction.fadeAlpha(to: 0.62, duration: 0.9)
        ])
        gloss.run(SKAction.repeatForever(glossPulse), withKey: "gloss")

        guard special != nil else {
            sheen.isHidden = true
            return
        }

        // Light sheen sweep across candy surface
        let sweepWidth = tileSize * 0.9
        sheen.isHidden = false
        sheen.position = CGPoint(x: -sweepWidth, y: 0)
        let waitIn = SKAction.wait(forDuration: 1.4 + phaseOffset.truncatingRemainder(dividingBy: 1.8))
        let sheenMove = SKAction.group([
            SKAction.fadeAlpha(to: 0.45, duration: 0.08),
            SKAction.moveTo(x: sweepWidth, duration: 0.55)
        ])
        let sheenReset = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.12),
            SKAction.moveTo(x: -sweepWidth, duration: 0.01),
            SKAction.wait(forDuration: 2.2 + Double.random(in: 0...1.2))
        ])
        let sweep = SKAction.sequence([waitIn, sheenMove, sheenReset])
        sheen.run(SKAction.repeatForever(sweep), withKey: "sheen")

        // Special power pulse ring
        if special != nil {
            let pulseUp = SKAction.group([
                SKAction.scale(to: 1.08, duration: 0.45),
                SKAction.fadeAlpha(to: 0.95, duration: 0.45)
            ])
            let pulseDown = SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.45),
                SKAction.fadeAlpha(to: 0.55, duration: 0.45)
            ])
            rimLight.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])), withKey: "specialPulse")
            if let badge = badgeSprite {
                let badgePulse = SKAction.sequence([
                    SKAction.scale(to: 1.12, duration: 0.4),
                    SKAction.scale(to: 0.95, duration: 0.4)
                ])
                badge.run(SKAction.repeatForever(badgePulse), withKey: "badgeSpin")
            }
        }
    }

    func stopLiveEffects() {
        contentRoot.removeAction(forKey: "idle")
        shadow.removeAction(forKey: "shadowIdle")
        gloss.removeAction(forKey: "gloss")
        sheen.removeAction(forKey: "sheen")
        rimLight.removeAction(forKey: "specialPulse")
        badgeSprite?.removeAction(forKey: "badgeSpin")
        liveStarted = false
    }

    func pressPulse() {
        contentRoot.removeAction(forKey: "pressPulse")
        let compress = SKAction.group([
            SKAction.scaleX(to: 1.10, duration: 0.045),
            SKAction.scaleY(to: 0.88, duration: 0.045),
            SKAction.moveBy(x: 0, y: -tileSize * 0.025, duration: 0.045)
        ])
        let rebound = SKAction.group([
            SKAction.scaleX(to: 0.96, duration: 0.07),
            SKAction.scaleY(to: 1.08, duration: 0.07),
            SKAction.moveBy(x: 0, y: tileSize * 0.04, duration: 0.07)
        ])
        let settle = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.08),
            SKAction.moveBy(x: 0, y: -tileSize * 0.015, duration: 0.08)
        ])
        contentRoot.run(SKAction.sequence([compress, rebound, settle]), withKey: "pressPulse")
    }

    func hintPulse() {
        contentRoot.removeAction(forKey: "hintPulse")
        contentRoot.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.32),
            .scale(to: 1.0, duration: 0.32)
        ])), withKey: "hintPulse")
    }

    func clearHintPulse() {
        contentRoot.removeAction(forKey: "hintPulse")
        contentRoot.run(.scale(to: 1.0, duration: 0.08))
    }

    func popAway(duration: TimeInterval, completion: @escaping () -> Void) {
        stopLiveEffects()
        let squashX = SKAction.scaleX(to: 1.2, duration: duration * 0.25)
        let squashY = SKAction.scaleY(to: 0.75, duration: duration * 0.25)
        let spin = SKAction.rotate(byAngle: .pi / 6, duration: duration)
        let squash = SKAction.group([squashX, squashY, spin])
        let expand = SKAction.scale(to: 1.35, duration: duration * 0.35)
        let fade = SKAction.fadeAlpha(to: 0.0, duration: duration * 0.75)
        let lift = SKAction.moveBy(x: 0, y: tileSize * 0.15, duration: duration * 0.75)
        let burst = SKAction.group([expand, fade, lift])
        let finish = SKAction.run(completion)
        run(SKAction.sequence([squash, burst, finish]))
    }
}
