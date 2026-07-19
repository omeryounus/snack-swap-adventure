import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    private var boardSize = 8
    private var tileSize: CGFloat = 60
    private var snacks: [[SKSpriteNode?]] = []
    private var movesLeft = 20
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupBoard()
    }
    
    // MARK: - Board Setup
    private func setupBoard() {
        snacks = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let snack = createSnack(at: CGPoint(x: CGFloat(col) * tileSize + tileSize/2, 
                                                    y: CGFloat(row) * tileSize + tileSize/2))
                addChild(snack)
                snacks[row][col] = snack
            }
        }
    }
    
    private func createSnack(at position: CGPoint) -> SKSpriteNode {
        let snack = SKSpriteNode(color: .red, size: CGSize(width: tileSize - 4, height: tileSize - 4))
        snack.position = position
        snack.name = "snack"
        return snack
    }
    
    // MARK: - Touch Handling (Basic Swap)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // TODO: Detect which tile was touched and implement swap logic
        print("Touched at: \(location)")
    }
    
    // MARK: - Match Detection (To be implemented)
    private func checkForMatches() {
        // TODO: Scan rows and columns for 3+ matching snacks
        // If found, remove them and trigger gravity
    }
    
    private func applyGravity() {
        // TODO: Make snacks fall down when there are empty spaces below
    }
    
    private func refillBoard() {
        // TODO: Create new snacks at the top to fill empty spaces
    }
    
    // MARK: - Game Loop Helpers
    private func updateMovesLeft() {
        movesLeft -= 1
        // Update HUD label
    }
}
