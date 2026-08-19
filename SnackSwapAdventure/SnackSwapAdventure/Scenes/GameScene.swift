import SpriteKit
import UIKit

/// SpriteKit scene that renders the snack board and drives the match-3 loop.
final class GameScene: SKScene {

    // MARK: - Config

    /// Insets reserved for SwiftUI chrome. Portrait overlay mode uses large
    /// top/bottom values; landscape split mode only needs a small margin.
    var playfieldInsets: UIEdgeInsets = UIEdgeInsets(top: 155, left: 16, bottom: 90, right: 16)
    var maxTileSize: CGFloat = 56
    private let boardPadding: CGFloat = 8
    /// Grow tiles slightly vs the padded well.
    private let tileScaleBoost: CGFloat = 1.06
    private var lastLaidOutSize: CGSize = .zero

    // MARK: - State

    weak var gameState: GameState?
    var isHammerModeActive: Bool = false
    var onHammerUsed: (() -> Void)?

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

    private var hasPresentedBoard = false

    func configure(with state: GameState) {
        if gameState !== state {
            hasPresentedBoard = false
        }
        self.gameState = state
        self.boardSize = state.level.boardSize
    }

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        // Culling hid the top row when the SKView bounds lagged the scene size.
        view.shouldCullNonVisibleNodes = false
        view.preferredFramesPerSecond = 60
        // Transparent so the SwiftUI world plate shows through.
        backgroundColor = .clear
        rebuildBoard()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 1, size.height > 1 else { return }
        let deltaW = abs(size.width - lastLaidOutSize.width)
        let deltaH = abs(size.height - lastLaidOutSize.height)
        guard deltaW > 1 || deltaH > 1 else { return }
        rebuildBoard()
    }

    /// Apply live SwiftUI chrome insets and relayout if they actually changed.
    func applyPlayfield(insets: UIEdgeInsets, maxTile: CGFloat) {
        let insetsChanged =
            abs(insets.top - playfieldInsets.top) > 0.5 ||
            abs(insets.bottom - playfieldInsets.bottom) > 0.5 ||
            abs(insets.left - playfieldInsets.left) > 0.5 ||
            abs(insets.right - playfieldInsets.right) > 0.5
        let tileChanged = abs(maxTile - maxTileSize) > 0.5
        playfieldInsets = insets
        maxTileSize = maxTile
        if (insetsChanged || tileChanged), size.width > 1 {
            rebuildBoard()
        }
    }

    func rebuildBoard() {
        removeAllChildren()
        selectedPosition = nil
        isBusy = false

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
        if !hasPresentedBoard {
            bounceInTiles()
            hasPresentedBoard = true
        }
        scheduleHint()
    }

    // MARK: - Layout

    private func layoutMetrics() {
        lastLaidOutSize = size
        let usableWidth = max(8, size.width - playfieldInsets.left - playfieldInsets.right)
        let usableHeight = max(8, size.height - playfieldInsets.top - playfieldInsets.bottom)
        let side = min(usableWidth, usableHeight)
        let rawTile = floor(side / CGFloat(max(boardSize, 1)))
        let cap = maxTileSize > 0 ? maxTileSize : rawTile
        tileSize = max(24, min(cap, rawTile))

        let boardPixel = tileSize * CGFloat(boardSize)
        let originX = playfieldInsets.left + max(0, (usableWidth - boardPixel) / 2)
        let originY = playfieldInsets.bottom + max(0, (usableHeight - boardPixel) / 2)
        boardOrigin = CGPoint(x: originX, y: originY)
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
        // Fully transparent: the per-level palette is painted by the SwiftUI
        // GameplayBackgroundView sitting behind the SpriteView.
        let backdrop = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        backdrop.fillColor = .clear
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

    }

    private func worldPalette() -> (accent: SKColor, secondary: SKColor) {
        guard let state = gameState else {
            return (
                SKColor(red: 1.0, green: 0.58, blue: 0.25, alpha: 1),
                SKColor(red: 1.0, green: 0.34, blue: 0.55, alpha: 1)
            )
        }
        let theme = LevelTheme.forLevel(state.level.levelNumber)
        return (theme.boardStroke, SKColor(white: 1.0, alpha: 0.3))
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
        let frameShadow = SKShapeNode(rect: rect.offsetBy(dx: 0, dy: -7), cornerRadius: 18)
        frameShadow.fillColor = SKColor(white: 0, alpha: 0.38)
        frameShadow.strokeColor = .clear
        frameShadow.zPosition = -1
        addChild(frameShadow)

        let levelTheme = LevelTheme.forLevel(gameState?.level.levelNumber ?? 1)
        frame.fillColor = levelTheme.boardFill
        // Gilded tray edge rather than a flat themed stroke.
        frame.strokeColor = SKColor(red: 0.96, green: 0.78, blue: 0.36, alpha: 1)
        frame.lineWidth = 6
        frame.zPosition = 0
        addChild(frame)
        boardBackground = frame

        // Inner bevel + the level's own colour, so the theme still reads.
        let bevel = SKShapeNode(rect: rect.insetBy(dx: 5, dy: 5), cornerRadius: 15)
        bevel.fillColor = .clear
        bevel.strokeColor = levelTheme.boardStroke.withAlphaComponent(0.9)
        bevel.lineWidth = 2
        bevel.zPosition = 0.4
        addChild(bevel)

        // Corner gems, matching the gilded HUD frames.
        for corner in [
            CGPoint(x: rect.minX + 10, y: rect.minY + 10),
            CGPoint(x: rect.maxX - 10, y: rect.minY + 10),
            CGPoint(x: rect.minX + 10, y: rect.maxY - 10),
            CGPoint(x: rect.maxX - 10, y: rect.maxY - 10)
        ] {
            let gem = SKShapeNode(rectOf: CGSize(width: 11, height: 11), cornerRadius: 2)
            gem.position = corner
            gem.zRotation = .pi / 4
            gem.fillColor = SKColor(red: 1.0, green: 0.42, blue: 0.62, alpha: 1)
            gem.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1)
            gem.lineWidth = 1.5
            gem.glowWidth = 2
            gem.zPosition = 2.5
            addChild(gem)
        }

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

        // Glossy wells with a soft inset shadow. The alternating colors keep the
        // grid scannable without making the tray feel like a flat gray table.
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let position = point(for: BoardPosition(row: row, col: col))
                let wellShadow = SKShapeNode(
                    rectOf: CGSize(width: tileSize - 2, height: tileSize - 2),
                    cornerRadius: 10
                )
                wellShadow.fillColor = SKColor(white: 0, alpha: 0.24)
                wellShadow.strokeColor = .clear
                wellShadow.position = CGPoint(x: position.x, y: position.y - 2)
                wellShadow.zPosition = 0.7
                addChild(wellShadow)

                let cell = SKShapeNode(
                    rectOf: CGSize(width: tileSize - 3, height: tileSize - 3),
                    cornerRadius: 10
                )
                let even = (row + col) % 2 == 0
                cell.fillColor = even
                    ? SKColor(red: 0.66, green: 0.56, blue: 0.66, alpha: 1)
                    : SKColor(red: 0.57, green: 0.48, blue: 0.59, alpha: 1)
                cell.strokeColor = SKColor(white: 1, alpha: 0.24)
                cell.lineWidth = 1.2
                cell.position = position
                cell.zPosition = 1
                addChild(cell)

                let highlight = SKShapeNode(
                    rectOf: CGSize(width: tileSize - 8, height: tileSize - 8),
                    cornerRadius: 8
                )
                highlight.fillColor = .clear
                highlight.strokeColor = SKColor(white: 1, alpha: 0.11)
                highlight.lineWidth = 1
                highlight.position = CGPoint(x: position.x, y: position.y + 1)
                highlight.zPosition = 1.2
                addChild(highlight)
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
        
        // Add ambient glow behind specials
        if let special = cell.special {
            let glowSize = tileSize * 1.3
            let glow = SKShapeNode(circleOfRadius: glowSize / 2)
            glow.fillColor = special.accent.withAlphaComponent(0.25)
            glow.strokeColor = .clear
            glow.glowWidth = 8
            glow.blendMode = .add
            glow.zPosition = -1
            node.addChild(glow)
            
            // Pulse the glow
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.40, duration: 0.8),
                .fadeAlpha(to: 0.15, duration: 0.8)
            ])))
        }
        
        // Stagger idle so the board feels alive, not synchronized.
        let phase = Double((pos.row * 3 + pos.col * 5) % 17) * 0.07
        let featured = cell.special != nil || (pos.row + pos.col) % 5 == 0
        node.startLiveEffects(phaseOffset: phase, featured: featured)
        return node
    }

    private func buildHUD() {
        // Top stats and mascot feedback live in SwiftUI (GameHUD & GameContainerView).
        levelLabel = nil
        movesLabel = nil
        scoreLabel = nil
        goalLabel = nil
        monsterLabel = nil
        monsterNode = nil
        messageLabel = nil

        // Sized so the stroke and glow both stay inside one cell: the ring plus
        // half its line width plus its glow must not exceed tileSize.
        let ring = SKShapeNode(rectOf: CGSize(width: tileSize - 10, height: tileSize - 10), cornerRadius: 9)
        ring.strokeColor = .white
        ring.lineWidth = 2.5
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

    func refreshHUD() {
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

        if isHammerModeActive {
            smashTile(at: pos)
            isHammerModeActive = false
            onHammerUsed?()
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

    func smashTile(at pos: BoardPosition) {
        guard gameState != nil, !isBusy, tileNodes[pos.row][pos.col] != nil else { return }
        isBusy = true
        SoundManager.shared.playSpecial()
        spawnParticles(at: Set([pos]))
        spawnSnackBurst(at: Set([pos]))

        // Affordability was checked when hammer mode was armed in BoosterBarView.
        if PlayerProfile.shared.hammerCount > 0 {
            PlayerProfile.shared.hammerCount -= 1
        } else {
            PlayerProfile.shared.deductStars(ActiveBooster.hammer.cost)
        }

        resolveMatches(cascadeDepth: 0, forcedPositions: Set([pos]))
    }

    func plantSpecialOnBoard(_ special: SpecialKind) {
        guard let state = gameState, !isBusy else { return }
        let size = state.board.size
        let randomRow = Int.random(in: 0..<size)
        let randomCol = Int.random(in: 0..<size)
        let pos = BoardPosition(row: randomRow, col: randomCol)
        if let snack = state.board.snack(at: pos) {
            state.board.clear(Set([pos]), spawnSpecials: [pos: (special, snack)])
            if let oldNode = tileNodes[pos.row][pos.col] {
                oldNode.removeFromParent()
            }
            let cell = BoardCell(snack: snack, special: special)
            let node = makeSnackNode(cell: cell, at: pos)
            node.position = point(for: pos)
            node.zPosition = 10
            addChild(node)
            tileNodes[pos.row][pos.col] = node
            node.pressPulse()

            spawnParticles(at: Set([pos]))
            SoundManager.shared.playSpecial()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBusy, gameState?.outcome == .playing, gameState?.isPaused != true,
              let touch = touches.first,
              let selected = selectedPosition else { return }
        
        let startPt = point(for: selected)
        let currentPt = touch.location(in: self)
        
        let dx = currentPt.x - startPt.x
        let dy = currentPt.y - startPt.y
        let distance = sqrt(dx*dx + dy*dy)
        
        // Threshold: 32% of tile size for quick swipe recognition
        guard distance > tileSize * 0.32 else { return }
        
        let targetPos: BoardPosition
        if abs(dx) > abs(dy) {
            targetPos = selected.offset(col: dx > 0 ? 1 : -1)
        } else {
            targetPos = selected.offset(row: dy > 0 ? 1 : -1)
        }
        
        if targetPos.row >= 0 && targetPos.row < boardSize && targetPos.col >= 0 && targetPos.col < boardSize {
            attemptSwap(from: selected, to: targetPos)
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

        // A swap should never be allowed to start against a partially rebuilt
        // visual matrix. Repair the renderer first instead of creating a move
        // that can leave an empty well or a missing animation participant.
        guard tileNodes[from.row][from.col] != nil,
              tileNodes[to.row][to.col] != nil,
              state.board.cell(at: from) != nil,
              state.board.cell(at: to) != nil else {
            rebuildBoard()
            return
        }

        guard state.board.wouldCreateMatch(swapping: from, with: to) else {
            // Visual bump then reject
            isBusy = true
            SoundManager.shared.playSwap()
            animateSwap(from: from, to: to, duration: 0.12) { [weak self] in
                guard let self else { return }
                
                // Swap in local matrix so animateSwap finds them at their current visual positions
                let temp = self.tileNodes[from.row][from.col]
                self.tileNodes[from.row][from.col] = self.tileNodes[to.row][to.col]
                self.tileNodes[to.row][to.col] = temp
                
                self.animateSwap(from: from, to: to, duration: 0.12) {
                    // Swap back to restore logical state
                    let temp2 = self.tileNodes[from.row][from.col]
                    self.tileNodes[from.row][from.col] = self.tileNodes[to.row][to.col]
                    self.tileNodes[to.row][to.col] = temp2
                    
                    SoundManager.shared.playInvalid()
                    self.spawnInvalidTapFeedback(at: to)
                    state.registerInvalidSwap()
                    self.refreshHUD()
                    self.isBusy = false
                }
            }
            return
        }

        isBusy = true
        SoundManager.shared.playSwap()
        let cellFrom = state.board.cell(at: from)
        let cellTo = state.board.cell(at: to)
        var rainbowTarget: SnackType? = nil
        if cellFrom?.special == .rainbow {
            rainbowTarget = cellTo?.snack
        } else if cellTo?.special == .rainbow {
            rainbowTarget = cellFrom?.snack
        }

        let activatesSpecial = cellFrom?.special != nil || cellTo?.special != nil
        guard state.board.swap(from, to) else {
            isBusy = false
            rebuildBoard()
            return
        }
        animateSwap(from: from, to: to, duration: 0.15) { [weak self] in
            self?.swapNodeReferences(from, to)
            state.registerSuccessfulSwap()
            self?.refreshHUD()
            self?.resolveMatches(
                cascadeDepth: 0,
                forcedPositions: activatesSpecial ? Set([from, to]) : [],
                rainbowTarget: rainbowTarget,
                swappedPositions: Set([from, to])
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
            nodeA.removeAction(forKey: "tapNudge")
            nodeA.zPosition = 15
            nodeA.run(.sequence([
                .group([
                    .move(to: posB, duration: duration),
                    .sequence([.scale(to: 1.12, duration: duration * 0.45), .scale(to: 1.0, duration: duration * 0.55)])
                ]),
                .run { nodeA.zPosition = 10; group.leave() }
            ]), withKey: "swapMotion")
        }
        if let nodeB {
            group.enter()
            nodeB.removeAction(forKey: "tapNudge")
            nodeB.run(.sequence([
                .group([
                    .move(to: posA, duration: duration),
                    .sequence([.scale(to: 0.92, duration: duration * 0.45), .scale(to: 1.0, duration: duration * 0.55)])
                ]),
                .run { group.leave() }
            ]), withKey: "swapMotion")
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

    private func resolveMatches(cascadeDepth: Int, forcedPositions: Set<BoardPosition> = [], rainbowTarget: SnackType? = nil, swappedPositions: Set<BoardPosition> = []) {
        guard let state = gameState else {
            isBusy = false
            return
        }

        if cascadeDepth == 0 {
            VoiceAnnouncer.shared.resetCascadeTracking()
        }

        let groups = state.board.matchGroups()
        var matched = state.board.findMatches()
        matched.formUnion(forcedPositions)

        guard !matched.isEmpty else {
            VoiceAnnouncer.shared.announceFinalCombo()
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
        var spawns: [BoardPosition: (SpecialKind, SnackType)] = [:]
        for group in groups {
            if let (pos, kind) = state.board.specialToSpawn(for: group, swappedPositions: swappedPositions),
               let snack = state.board.snack(at: pos) {
                spawns[pos] = (kind, snack)
            }
        }

        // Expand with special activations
        let specialsBefore = matched.filter { state.board.cell(at: $0)?.special != nil }.count
        matched = state.board.expandWithSpecials(matched, rainbowTarget: rainbowTarget)
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
        VoiceAnnouncer.shared.trackCascadeStep(
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
            if spawns[pos] != nil { continue }
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
        state.board.clear(matched, spawnSpecials: spawns)

        // Visual for planted specials
        for (pos, (kind, snack)) in spawns {
            SoundManager.shared.playSpecial()
            tileNodes[pos.row][pos.col]?.removeFromParent()
            let node = makeSnackNode(cell: BoardCell(snack: snack, special: kind), at: pos)
            tileNodes[pos.row][pos.col] = node
            addChild(node)
            node.setScale(0.2)
            node.run(.sequence([
                .scale(to: 1.25, duration: 0.14),
                .scale(to: 0.92, duration: 0.08),
                .scale(to: 1.0, duration: 0.08)
            ]))
            // Burst ring
            let ring = SKShapeNode(circleOfRadius: tileSize * 0.55)
            ring.strokeColor = kind.accent
            ring.lineWidth = 3
            ring.fillColor = .clear
            ring.position = point(for: pos)
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

    private func createStarPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size))
        path.addLine(to: CGPoint(x: size * 0.2, y: size * 0.2))
        path.addLine(to: CGPoint(x: size, y: 0))
        path.addLine(to: CGPoint(x: size * 0.2, y: -size * 0.2))
        path.addLine(to: CGPoint(x: 0, y: -size))
        path.addLine(to: CGPoint(x: -size * 0.2, y: -size * 0.2))
        path.addLine(to: CGPoint(x: -size, y: 0))
        path.addLine(to: CGPoint(x: -size * 0.2, y: size * 0.2))
        path.closeSubpath()
        return path
    }

    private func spawnParticles(at positions: Set<BoardPosition>) {
        guard !positions.isEmpty else { return }
        for pos in positions.prefix(12) {
            let center = point(for: pos)
            let snack = gameState?.board.snack(at: pos)
            let color = snack?.color ?? SKColor(red: 1.0, green: 0.86, blue: 0.32, alpha: 1.0)

            // Spawn 4 rotating sparkle stars tinted to the matched snack
            for _ in 0..<4 {
                let size = CGFloat.random(in: 6...10)
                let star = SKShapeNode(path: createStarPath(size: size))
                star.fillColor = color
                star.strokeColor = .clear
                star.blendMode = .add
                star.position = center
                star.zPosition = 40
                star.alpha = 0.95
                addChild(star)
                
                let angle = CGFloat.random(in: 0...(.pi * 2))
                let distance = CGFloat.random(in: tileSize * 0.2...tileSize * 0.6)
                let duration = Double.random(in: 0.35...0.5)
                
                star.run(.sequence([
                    .group([
                        .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: duration),
                        .rotate(byAngle: CGFloat.random(in: -2...2), duration: duration),
                        .fadeOut(withDuration: duration),
                        .scale(to: 0.1, duration: duration)
                    ]),
                    .removeFromParent()
                ]))
            }
        }
    }

    private func spawnSnackBurst(at positions: Set<BoardPosition>) {
        for pos in positions.prefix(10) {
            let center = point(for: pos)
            let snack = gameState?.board.snack(at: pos)
            let color = snack?.color ?? SKColor(red: 1, green: 0.82, blue: 0.35, alpha: 1)
            
            for index in 0..<7 {
                let crumb = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5.0))
                crumb.fillColor = index.isMultiple(of: 2) ? color : SKColor(white: 1.0, alpha: 0.95)
                crumb.strokeColor = .clear
                crumb.position = center
                crumb.zPosition = 42
                addChild(crumb)

                let angle = CGFloat(index) / 7 * .pi * 2 + CGFloat.random(in: -0.2...0.2)
                let distance = CGFloat.random(in: tileSize * 0.3...tileSize * 0.8)
                let duration = Double.random(in: 0.3...0.45)
                
                crumb.run(.sequence([
                    .group([
                        .moveBy(x: cos(angle) * distance, y: sin(angle) * distance + 8, duration: duration),
                        .scale(to: 0.15, duration: duration),
                        .fadeOut(withDuration: duration)
                    ]),
                    .removeFromParent()
                ]))
            }

            if let snack {
                let emoji = SKLabelNode(text: snack.emoji)
                emoji.fontSize = tileSize * 0.32
                emoji.position = center
                emoji.zPosition = 43
                addChild(emoji)
                emoji.run(.sequence([
                    .group([
                        .moveBy(x: CGFloat.random(in: -16...16), y: tileSize * 0.5, duration: 0.4),
                        .rotate(byAngle: CGFloat.random(in: -1.0...1.0), duration: 0.4),
                        .fadeOut(withDuration: 0.4),
                        .scale(to: 0.6, duration: 0.4)
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
        
        NSLog("🤖 [GRAVITY] gravityMoves: \(gravityMoves.map { "(\($0.from.row),\($0.from.col)) -> (\($0.to.row),\($0.to.col))" })")
        NSLog("🤖 [REFILL] spawned: \(spawned.map { "(\($0.pos.row),\($0.pos.col))" })")
        
        var gravitySources: [BoardPosition: BoardPosition] = [:]
        for move in gravityMoves {
            gravitySources[move.to] = move.from
        }
        
        let spawnedPositions = Set(spawned.map(\.pos))
        var spawnedByCol: [Int: [BoardPosition]] = [:]
        for spawnItem in spawned {
            spawnedByCol[spawnItem.pos.col, default: []].append(spawnItem.pos)
        }
        for col in spawnedByCol.keys {
            spawnedByCol[col]?.sort(by: { $0.row < $1.row })
        }

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
                guard let cell = state.board.cell(at: pos) else {
                    NSLog("⚠️ [RENDER SKIP] position (\(row),\(col)) is nil in model grid!")
                    continue
                }
                let node = makeSnackNode(cell: cell, at: pos)
                let target = point(for: pos)
                node.position = target
                node.setScale(1.0)
                node.alpha = 1.0
                node.contentRoot.position = .zero
                tileNodes[row][col] = node
                addChild(node)

                if spawnedPositions.contains(pos) {
                    let spawnIndex = spawnedByCol[pos.col]?.firstIndex(of: pos) ?? 0
                    let spawnStartRow = boardSize + spawnIndex
                    let startY = boardOrigin.y + CGFloat(spawnStartRow) * tileSize + tileSize / 2
                    let offset = CGPoint(x: 0, y: startY - target.y)
                    node.contentRoot.position = offset
                    
                    let fallDuration = 0.24
                    node.contentRoot.run(.move(to: .zero, duration: fallDuration))
                    node.run(.sequence([
                        .wait(forDuration: fallDuration),
                        .group([
                            .scaleX(to: 1.15, duration: 0.08),
                            .scaleY(to: 0.82, duration: 0.08)
                        ]),
                        .group([
                            .scaleX(to: 0.94, duration: 0.06),
                            .scaleY(to: 1.06, duration: 0.06)
                        ]),
                        .group([
                            .scaleX(to: 1.0, duration: 0.06),
                            .scaleY(to: 1.0, duration: 0.06)
                        ])
                    ]), withKey: "settleMotion")
                } else if let fromPos = gravitySources[pos] {
                    let sourcePt = point(for: fromPos)
                    let offset = CGPoint(x: sourcePt.x - target.x, y: sourcePt.y - target.y)
                    node.contentRoot.position = offset
                    
                    let fallDuration = 0.22
                    node.contentRoot.run(.move(to: .zero, duration: fallDuration))
                    node.run(.sequence([
                        .wait(forDuration: fallDuration),
                        .group([
                            .scaleX(to: 1.15, duration: 0.08),
                            .scaleY(to: 0.82, duration: 0.08)
                        ]),
                        .group([
                            .scaleX(to: 0.94, duration: 0.06),
                            .scaleY(to: 1.06, duration: 0.06)
                        ]),
                        .group([
                            .scaleX(to: 1.0, duration: 0.06),
                            .scaleY(to: 1.0, duration: 0.06)
                        ])
                    ]), withKey: "settleMotion")
                }
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
                rectOf: CGSize(width: tileSize - 14, height: tileSize - 14),
                cornerRadius: 10
            )
            ring.name = "hintRing"
            ring.position = point(for: pos)
            ring.fillColor = .clear
            ring.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.32, alpha: 0.95)
            ring.lineWidth = 2.5
            ring.glowWidth = 3
            ring.zPosition = 24
            addChild(ring)
            ring.run(.repeatForever(.sequence([
                .group([
                    .scale(to: 1.04, duration: 0.42),
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
    let contentRoot = SKNode()
    private let shadow: SKShapeNode
    private let plate: SKShapeNode
    private let sprite: SKSpriteNode
    private let gloss: SKShapeNode
    private let sheen: SKShapeNode
    private let rimLight: SKShapeNode
    private let materialDetails: SKNode
    private let badgeSprite: SKSpriteNode?
    private var liveStarted = false

    convenience init(type: SnackType, tileSize: CGFloat) {
        self.init(cell: BoardCell(snack: type), tileSize: tileSize)
    }

    init(cell: BoardCell, tileSize: CGFloat) {
        self.type = cell.snack
        self.special = cell.special
        self.tileSize = tileSize
        materialDetails = SKNode()

        let plateSize = tileSize * 0.96
        let snackSize = tileSize * 0.94

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
        plate.fillColor = SKColor(white: 1, alpha: cell.special != nil ? 0.26 : 0.19)
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
                badge.size = CGSize(width: tileSize * 0.40, height: tileSize * 0.40)
                badge.position = CGPoint(x: tileSize * 0.31, y: tileSize * 0.31)
                badge.zPosition = 6
                badgeSprite = badge
            } else {
                badgeSprite = nil
            }
            plate.fillColor = SKColor(white: 1, alpha: 0.26)
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
        materialDetails.zPosition = 4.5
        contentRoot.addChild(materialDetails)
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
        buildMaterialDetails()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildMaterialDetails() {
        let detailAlpha: CGFloat = special == nil ? 0.32 : 0.44

        switch type {
        case .cookie:
            // Tiny warm glints sit above the existing chips and make the baked
            // surface read as textured instead of a flat painted disc.
            let crumbOffsets: [CGPoint] = [
                CGPoint(x: -0.24, y: 0.17), CGPoint(x: 0.02, y: 0.27),
                CGPoint(x: 0.25, y: 0.10), CGPoint(x: -0.03, y: -0.11),
                CGPoint(x: 0.20, y: -0.25)
            ]
            for (index, offset) in crumbOffsets.enumerated() {
                let crumb = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.045, height: tileSize * 0.022))
                crumb.fillColor = index.isMultiple(of: 2)
                    ? SKColor(white: 1, alpha: detailAlpha)
                    : SKColor(red: 0.58, green: 0.27, blue: 0.12, alpha: 0.26)
                crumb.strokeColor = .clear
                crumb.position = CGPoint(x: offset.x * tileSize, y: offset.y * tileSize)
                crumb.zRotation = CGFloat(index) * 0.4
                materialDetails.addChild(crumb)
            }

        case .donut:
            // A broad icing reflection follows the donut's curved top plane.
            let icingSheen = SKShapeNode(
                ellipseOf: CGSize(width: tileSize * 0.40, height: tileSize * 0.10)
            )
            icingSheen.fillColor = SKColor(white: 1, alpha: 0.25)
            icingSheen.strokeColor = .clear
            icingSheen.position = CGPoint(x: -tileSize * 0.15, y: tileSize * 0.23)
            icingSheen.zRotation = -0.16
            materialDetails.addChild(icingSheen)

            let icingSpark = SKShapeNode(circleOfRadius: tileSize * 0.035)
            icingSpark.fillColor = SKColor(white: 1, alpha: 0.58)
            icingSpark.strokeColor = .clear
            icingSpark.position = CGPoint(x: tileSize * 0.12, y: tileSize * 0.30)
            materialDetails.addChild(icingSpark)

        case .candy:
            // Two narrow reflections reinforce the hard sugar-shell material.
            for x: CGFloat in [-0.14, -0.03] {
                let candyStripe = SKShapeNode(
                    rectOf: CGSize(width: tileSize * 0.055, height: tileSize * 0.34),
                    cornerRadius: tileSize * 0.025
                )
                candyStripe.fillColor = SKColor(white: 1, alpha: x < -0.1 ? 0.42 : 0.18)
                candyStripe.strokeColor = .clear
                candyStripe.position = CGPoint(x: tileSize * x, y: tileSize * 0.13)
                candyStripe.zRotation = -0.42
                materialDetails.addChild(candyStripe)
            }

        case .popcorn:
            // Popcorn gets small hot highlights on separate kernels, rather
            // than one generic gloss that makes the cluster look plastic.
            let kernelOffsets: [CGPoint] = [
                CGPoint(x: -0.18, y: 0.20), CGPoint(x: 0.05, y: 0.27),
                CGPoint(x: 0.22, y: 0.07), CGPoint(x: -0.05, y: -0.02),
                CGPoint(x: 0.14, y: -0.20)
            ]
            for offset in kernelOffsets {
                let highlight = SKShapeNode(
                    ellipseOf: CGSize(width: tileSize * 0.075, height: tileSize * 0.040)
                )
                highlight.fillColor = SKColor(white: 1, alpha: 0.30)
                highlight.strokeColor = .clear
                highlight.position = CGPoint(x: offset.x * tileSize, y: offset.y * tileSize)
                materialDetails.addChild(highlight)
            }

        case .lollipop, .cupcake:
            let sparkle = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.18, height: tileSize * 0.07))
            sparkle.fillColor = SKColor(white: 1, alpha: detailAlpha)
            sparkle.strokeColor = .clear
            sparkle.position = CGPoint(x: -tileSize * 0.12, y: tileSize * 0.24)
            sparkle.zRotation = -0.25
            materialDetails.addChild(sparkle)
        }
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
