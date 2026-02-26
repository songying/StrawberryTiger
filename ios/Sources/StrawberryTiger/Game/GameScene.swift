import SpriteKit

@MainActor
final class GameScene: SKScene {

    // MARK: - Game State

    private enum GameState {
        case menu, playing, gameOver
    }

    // MARK: - Entity Structs

    private struct Tiger {
        var x: CGFloat
        var y: CGFloat          // game-coords (top-down)
        var width: CGFloat
        var height: CGFloat
        var velocityY: CGFloat
        var isOnGround: Bool
        var groundY: CGFloat    // game-coords
    }

    private struct Strawberry {
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat
        var isGolden: Bool
        var collected: Bool
        var node: SKSpriteNode
    }

    private struct Rock {
        var x: CGFloat
        var y: CGFloat
        var width: CGFloat
        var height: CGFloat
        var node: SKSpriteNode
    }

    private struct Cloud {
        var x: CGFloat
        var y: CGFloat
        var width: CGFloat
        var height: CGFloat
        var speed: CGFloat
        var node: SKNode
    }

    private struct ScoreParticle {
        var x: CGFloat
        var y: CGFloat
        var text: String
        var color: UIColor
        var life: CGFloat
        var velocityY: CGFloat
        var node: SKLabelNode
    }

    // MARK: - Properties

    private var gameState: GameState = .menu
    private var score: Int = 0
    private var bestScore: Int = 0
    private var scrollSpeed: CGFloat = GameConstants.baseScrollSpeed
    private var scrollOffset: CGFloat = 0
    private var frameCount: Int = 0
    private var playTime: CGFloat = 0
    private var lastUpdateTime: TimeInterval = 0

    private var tiger = Tiger(
        x: GameConstants.tigerX,
        y: GameConstants.groundY - GameConstants.tigerHeight,
        width: GameConstants.tigerWidth,
        height: GameConstants.tigerHeight,
        velocityY: 0,
        isOnGround: true,
        groundY: GameConstants.groundY - GameConstants.tigerHeight
    )

    private var strawberries: [Strawberry] = []
    private var rocks: [Rock] = []
    private var clouds: [Cloud] = []
    private var scoreParticles: [ScoreParticle] = []
    private var strawberrySpawnTimer: CGFloat = 1.0
    private var rockSpawnTimer: CGFloat = 2.0

    // MARK: - Nodes

    private var skyNode: SKSpriteNode!
    private var groundNode: SKNode!
    private var grassDetailNode: SKNode!
    private var tigerNode: SKSpriteNode!
    private var scoreLabelNode: SKLabelNode!
    private var scoreShadowNode: SKLabelNode!
    private var menuOverlay: SKNode?
    private var gameOverOverlay: SKNode?
    private var menuStrawberryNode: SKSpriteNode?

    // MARK: - Cached Textures

    private var regularStrawberryTexture: SKTexture!
    private var goldenStrawberryTexture: SKTexture!
    private var rockTexture: SKTexture!

    // MARK: - Y-flip helper
    // game.js Y=0 at top, SpriteKit Y=0 at bottom
    private func skY(_ gameY: CGFloat) -> CGFloat {
        GameConstants.canvasHeight - gameY
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .white

        // Pre-render textures
        regularStrawberryTexture = StrawberryRenderer.makeTexture(
            radius: GameConstants.strawberryRadius, isGolden: false)
        goldenStrawberryTexture = StrawberryRenderer.makeTexture(
            radius: GameConstants.strawberryRadius, isGolden: true)
        rockTexture = RockRenderer.makeTexture(
            width: GameConstants.rockWidth, height: GameConstants.rockHeight)

        setupBackground()
        setupTiger()
        setupScoreLabel()

        bestScore = ScoreManager.getHighScore()
        showMenu()
    }

    // MARK: - Setup

    private func setupBackground() {
        // Sky
        let skyTex = BackgroundRenderer.makeSkyTexture(
            width: GameConstants.canvasWidth, height: GameConstants.groundY)
        skyNode = SKSpriteNode(texture: skyTex, size: CGSize(
            width: GameConstants.canvasWidth, height: GameConstants.groundY))
        skyNode.anchorPoint = CGPoint(x: 0, y: 0)
        skyNode.position = CGPoint(x: 0, y: skY(GameConstants.groundY))
        skyNode.zPosition = -10
        addChild(skyNode)

        // Ground
        groundNode = BackgroundRenderer.makeGroundNode(
            canvasWidth: GameConstants.canvasWidth,
            groundY: GameConstants.groundY,
            canvasHeight: GameConstants.canvasHeight)
        groundNode.position = CGPoint(x: 0, y: skY(GameConstants.groundY))
        groundNode.zPosition = -5
        addChild(groundNode)

        // Grass detail
        grassDetailNode = BackgroundRenderer.makeGrassDetailNode(
            canvasWidth: GameConstants.canvasWidth)
        grassDetailNode.position = CGPoint(x: 0, y: skY(GameConstants.groundY))
        grassDetailNode.zPosition = -4
        addChild(grassDetailNode)

        // Clouds
        initClouds()
    }

    private func initClouds() {
        for c in clouds { c.node.removeFromParent() }
        clouds.removeAll()
        for _ in 0..<5 {
            let w = 60 + CGFloat.random(in: 0..<80)
            let h = 20 + CGFloat.random(in: 0..<20)
            let x = CGFloat.random(in: 0..<GameConstants.canvasWidth)
            let y = 30 + CGFloat.random(in: 0..<100)
            let speed: CGFloat = 0.2 + CGFloat.random(in: 0..<0.3)

            let node = BackgroundRenderer.makeCloudNode(width: w, height: h)
            node.position = CGPoint(x: x + w / 2, y: skY(y + h / 2))
            node.zPosition = -8
            addChild(node)

            clouds.append(Cloud(x: x, y: y, width: w, height: h, speed: speed, node: node))
        }
    }

    private func setupTiger() {
        let tex = TigerRenderer.makeTexture(isOnGround: true, isPlaying: false, frameCount: 0)
        tigerNode = SKSpriteNode(texture: tex, size: CGSize(
            width: TigerRenderer.textureWidth, height: TigerRenderer.textureHeight))
        tigerNode.anchorPoint = CGPoint(x: 0, y: 1) // top-left in SpriteKit
        tigerNode.zPosition = 50
        updateTigerPosition()
        addChild(tigerNode)
    }

    private func setupScoreLabel() {
        scoreShadowNode = UIRenderer.makeScoreShadowLabel()
        scoreShadowNode.position = CGPoint(x: 22, y: skY(14))
        addChild(scoreShadowNode)

        scoreLabelNode = UIRenderer.makeScoreLabel()
        scoreLabelNode.position = CGPoint(x: 20, y: skY(12))
        addChild(scoreLabelNode)

        scoreLabelNode.isHidden = true
        scoreShadowNode.isHidden = true
    }

    // MARK: - Menu / Game Over

    private func showMenu() {
        gameState = .menu
        scoreLabelNode.isHidden = true
        scoreShadowNode.isHidden = true

        menuOverlay?.removeFromParent()
        menuOverlay = UIRenderer.makeMenuOverlay(
            canvasWidth: GameConstants.canvasWidth,
            canvasHeight: GameConstants.canvasHeight,
            bestScore: bestScore)
        addChild(menuOverlay!)

        // Decorative strawberry above title
        let texSize = StrawberryRenderer.textureSize(radius: 18)
        let berryNode = SKSpriteNode(texture: StrawberryRenderer.makeTexture(radius: 18, isGolden: false),
                                      size: texSize)
        berryNode.position = CGPoint(x: GameConstants.canvasWidth / 2, y: skY(100))
        berryNode.zPosition = 201
        menuOverlay!.addChild(berryNode)
        menuStrawberryNode = berryNode
    }

    private func showGameOver() {
        gameState = .gameOver
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = UIRenderer.makeGameOverOverlay(
            canvasWidth: GameConstants.canvasWidth,
            canvasHeight: GameConstants.canvasHeight,
            score: score,
            bestScore: bestScore)
        addChild(gameOverOverlay!)
    }

    // MARK: - Reset / Start

    private func resetGame() {
        // Remove entities
        for s in strawberries { s.node.removeFromParent() }
        strawberries.removeAll()
        for r in rocks { r.node.removeFromParent() }
        rocks.removeAll()
        for p in scoreParticles { p.node.removeFromParent() }
        scoreParticles.removeAll()

        initTiger()
        score = 0
        scrollSpeed = GameConstants.baseScrollSpeed
        scrollOffset = 0
        playTime = 0
        frameCount = 0
        strawberrySpawnTimer = 1.0
        rockSpawnTimer = 2.0
        bestScore = ScoreManager.getHighScore()
    }

    private func initTiger() {
        tiger = Tiger(
            x: GameConstants.tigerX,
            y: GameConstants.groundY - GameConstants.tigerHeight,
            width: GameConstants.tigerWidth,
            height: GameConstants.tigerHeight,
            velocityY: 0,
            isOnGround: true,
            groundY: GameConstants.groundY - GameConstants.tigerHeight
        )
    }

    private func startGame() {
        resetGame()
        menuOverlay?.removeFromParent()
        menuOverlay = nil
        gameState = .playing
        scoreLabelNode.isHidden = false
        scoreShadowNode.isHidden = false
        updateScoreText()
        SoundManager.shared.startBGM()
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .menu:
            startGame()
        case .playing:
            if tiger.isOnGround {
                tiger.velocityY = GameConstants.jumpVelocity
                tiger.isOnGround = false
                SoundManager.shared.playJumpSound()
            }
        case .gameOver:
            gameOverOverlay?.removeFromParent()
            gameOverOverlay = nil
            resetGame()
            showMenu()
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let dt = CGFloat(min(deltaTime, 0.05))

        guard gameState == .playing else {
            // Still update tiger texture on menu for standing pose
            updateTigerNode()
            return
        }

        frameCount += 1
        scrollOffset += scrollSpeed * dt

        updateTigerPhysics(dt: dt)
        spawnStrawberries(dt: dt)
        updateStrawberries(dt: dt)
        spawnRocks(dt: dt)
        updateRocks(dt: dt)
        updateCloudsLogic(dt: dt)
        updateScoreParticlesLogic(dt: dt)
        checkCollisions()
        updateDifficulty(dt: dt)

        // Update visuals
        updateTigerNode()
        updateGrassDetail()
        updateScoreText()
    }

    // MARK: - Physics

    private func updateTigerPhysics(dt: CGFloat) {
        if !tiger.isOnGround {
            tiger.velocityY += GameConstants.gravity * dt
            tiger.velocityY = min(tiger.velocityY, GameConstants.maxFallSpeed)
            tiger.y += tiger.velocityY * dt

            if tiger.y >= tiger.groundY {
                tiger.y = tiger.groundY
                tiger.velocityY = 0
                tiger.isOnGround = true
            }
        }
    }

    // MARK: - Spawning

    private func spawnStrawberries(dt: CGFloat) {
        strawberrySpawnTimer -= dt
        if strawberrySpawnTimer <= 0 {
            strawberrySpawnTimer = GameConstants.strawberrySpawnInterval
                + (CGFloat.random(in: 0..<1) - 0.5) * GameConstants.spawnIntervalVariance * 2

            let count: Int = CGFloat.random(in: 0..<1) < GameConstants.clusterChance
                ? Int.random(in: 2...3)
                : 1

            for i in 0..<count {
                let isGolden = CGFloat.random(in: 0..<1) < GameConstants.goldenProbability
                let r = (CGFloat.random(in: 0..<1) + CGFloat.random(in: 0..<1)) / 2
                let yPos = GameConstants.strawberryMinY + r * (GameConstants.strawberryMaxY - GameConstants.strawberryMinY)
                let xPos = GameConstants.canvasWidth + 20 + CGFloat(i) * 45

                let tex = isGolden ? goldenStrawberryTexture! : regularStrawberryTexture!
                let texSize = StrawberryRenderer.textureSize(radius: GameConstants.strawberryRadius)
                let node = SKSpriteNode(texture: tex, size: texSize)
                node.position = CGPoint(x: xPos, y: skY(yPos))
                node.zPosition = 30
                addChild(node)

                strawberries.append(Strawberry(
                    x: xPos, y: yPos,
                    radius: GameConstants.strawberryRadius,
                    isGolden: isGolden, collected: false,
                    node: node))
            }
        }
    }

    private func spawnRocks(dt: CGFloat) {
        rockSpawnTimer -= dt
        if rockSpawnTimer <= 0 {
            rockSpawnTimer = GameConstants.rockSpawnInterval
                + (CGFloat.random(in: 0..<1) - 0.5) * GameConstants.rockSpawnVariance * 2

            let x = GameConstants.canvasWidth + 20
            let y = GameConstants.groundY - GameConstants.rockHeight

            let node = SKSpriteNode(texture: rockTexture,
                                     size: CGSize(width: GameConstants.rockWidth,
                                                  height: GameConstants.rockHeight))
            node.anchorPoint = CGPoint(x: 0, y: 0)
            node.position = CGPoint(x: x, y: skY(y + GameConstants.rockHeight))
            node.zPosition = 25
            addChild(node)

            rocks.append(Rock(x: x, y: y,
                              width: GameConstants.rockWidth,
                              height: GameConstants.rockHeight,
                              node: node))
        }
    }

    // MARK: - Entity Updates

    private func updateStrawberries(dt: CGFloat) {
        var toRemove: [Int] = []
        for i in stride(from: strawberries.count - 1, through: 0, by: -1) {
            strawberries[i].x -= scrollSpeed * dt
            strawberries[i].node.position = CGPoint(
                x: strawberries[i].x, y: skY(strawberries[i].y))
            if strawberries[i].x < -30 {
                toRemove.append(i)
            }
        }
        for i in toRemove {
            strawberries[i].node.removeFromParent()
            strawberries.remove(at: i)
        }
    }

    private func updateRocks(dt: CGFloat) {
        var toRemove: [Int] = []
        for i in stride(from: rocks.count - 1, through: 0, by: -1) {
            rocks[i].x -= scrollSpeed * dt
            rocks[i].node.position = CGPoint(
                x: rocks[i].x,
                y: skY(rocks[i].y + rocks[i].height))
            if rocks[i].x < -40 {
                toRemove.append(i)
            }
        }
        for i in toRemove {
            rocks[i].node.removeFromParent()
            rocks.remove(at: i)
        }
    }

    private func updateCloudsLogic(dt: CGFloat) {
        for i in 0..<clouds.count {
            clouds[i].x -= clouds[i].speed * scrollSpeed * dt
            if clouds[i].x + clouds[i].width < 0 {
                clouds[i].x = GameConstants.canvasWidth + CGFloat.random(in: 0..<100)
                clouds[i].y = 30 + CGFloat.random(in: 0..<100)
            }
            clouds[i].node.position = CGPoint(
                x: clouds[i].x + clouds[i].width / 2,
                y: skY(clouds[i].y + clouds[i].height / 2))
        }
    }

    private func updateScoreParticlesLogic(dt: CGFloat) {
        var toRemove: [Int] = []
        for i in stride(from: scoreParticles.count - 1, through: 0, by: -1) {
            // In game coords, velocityY is -80 (moving up in screen = decreasing y in game coords)
            scoreParticles[i].y += scoreParticles[i].velocityY * dt
            scoreParticles[i].life -= dt
            scoreParticles[i].node.position = CGPoint(
                x: scoreParticles[i].x,
                y: skY(scoreParticles[i].y))
            scoreParticles[i].node.alpha = max(0, scoreParticles[i].life)
            if scoreParticles[i].life <= 0 {
                toRemove.append(i)
            }
        }
        for i in toRemove {
            scoreParticles[i].node.removeFromParent()
            scoreParticles.remove(at: i)
        }
    }

    // MARK: - Collision Detection

    private struct AABB {
        var x, y, width, height: CGFloat
    }

    private func aabbCollision(_ a: AABB, _ b: AABB) -> Bool {
        a.x < b.x + b.width &&
        a.x + a.width > b.x &&
        a.y < b.y + b.height &&
        a.y + a.height > b.y
    }

    private func checkCollisions() {
        let th = AABB(
            x: tiger.x + GameConstants.hitboxInset,
            y: tiger.y + GameConstants.hitboxInset,
            width: tiger.width - GameConstants.hitboxInset * 2,
            height: tiger.height - GameConstants.hitboxInset * 2)

        // Strawberry collisions
        for i in 0..<strawberries.count {
            if strawberries[i].collected { continue }
            let s = strawberries[i]
            let sb = AABB(
                x: s.x - s.radius,
                y: s.y - s.radius,
                width: s.radius * 2,
                height: s.radius * 2)

            if aabbCollision(th, sb) {
                strawberries[i].collected = true
                let points = s.isGolden ? 3 : 1
                score += points

                if s.isGolden {
                    SoundManager.shared.playGoldenSound()
                } else {
                    SoundManager.shared.playScoreSound()
                }

                // Score particle
                let color: UIColor = s.isGolden
                    ? UIColor(red: 1, green: 0.843, blue: 0, alpha: 1)
                    : .white
                let particleNode = UIRenderer.makeScoreParticleNode(
                    text: "+\(points)", color: color)
                particleNode.position = CGPoint(x: s.x, y: skY(s.y))
                addChild(particleNode)
                scoreParticles.append(ScoreParticle(
                    x: s.x, y: s.y, text: "+\(points)",
                    color: color, life: 1.0, velocityY: -80,
                    node: particleNode))
            }
        }

        // Remove collected
        for i in stride(from: strawberries.count - 1, through: 0, by: -1) where strawberries[i].collected {
            strawberries[i].node.removeFromParent()
            strawberries.remove(at: i)
        }

        // Rock collisions
        for rock in rocks {
            let rb = AABB(x: rock.x, y: rock.y, width: rock.width, height: rock.height)
            if aabbCollision(th, rb) {
                ScoreManager.saveHighScore(score)
                bestScore = ScoreManager.getHighScore()
                SoundManager.shared.stopBGM()
                SoundManager.shared.playGameOverSound()
                showGameOver()
                return
            }
        }
    }

    // MARK: - Difficulty

    private func updateDifficulty(dt: CGFloat) {
        playTime += dt
        scrollSpeed = min(
            GameConstants.baseScrollSpeed + playTime * GameConstants.speedIncreaseRate,
            GameConstants.maxScrollSpeed)
    }

    // MARK: - Visual Updates

    private func updateTigerNode() {
        let tex = TigerRenderer.makeTexture(
            isOnGround: tiger.isOnGround,
            isPlaying: gameState == .playing,
            frameCount: frameCount)
        tigerNode.texture = tex
        updateTigerPosition()
    }

    private func updateTigerPosition() {
        // The tiger texture origin is at (tiger.x - originOffsetX, tiger.y - originOffsetY) in game coords.
        // In SpriteKit, anchorPoint is (0, 1) (top-left), so position = top-left corner.
        let gameX = tiger.x - TigerRenderer.originOffsetX
        let gameY = tiger.y - TigerRenderer.originOffsetY
        tigerNode.position = CGPoint(x: gameX, y: skY(gameY))
    }

    private func updateGrassDetail() {
        let offset = scrollOffset.truncatingRemainder(dividingBy: 20)
        grassDetailNode.position = CGPoint(x: -offset, y: skY(GameConstants.groundY))
    }

    private func updateScoreText() {
        let text = "Score: \(score)"
        scoreLabelNode.text = text
        scoreShadowNode.text = text
    }
}
