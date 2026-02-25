import SpriteKit

enum UIRenderer {

    static func makeScoreLabel() -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.fontSize = 28
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.zPosition = 100
        return label
    }

    static func makeScoreShadowLabel() -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.fontSize = 28
        label.fontColor = .black
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.zPosition = 99
        return label
    }

    static func makeScoreParticleNode(text: String, color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.fontSize = 22
        label.fontColor = color
        label.text = text
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 90
        return label
    }

    // MARK: - Menu Screen

    static func makeMenuOverlay(
        canvasWidth: CGFloat, canvasHeight: CGFloat, bestScore: Int
    ) -> SKNode {
        let container = SKNode()
        container.zPosition = 200

        // Title shadow
        let titleShadow = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleShadow.fontSize = 42
        titleShadow.fontColor = .black
        titleShadow.text = "STRAWBERRY TIGER"
        titleShadow.horizontalAlignmentMode = .center
        titleShadow.verticalAlignmentMode = .center
        titleShadow.position = CGPoint(x: canvasWidth / 2 + 2,
                                        y: canvasHeight - 162 + 2)
        container.addChild(titleShadow)

        // Title
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.fontSize = 42
        title.fontColor = UIColor(red: 0.776, green: 0.157, blue: 0.157, alpha: 1) // #C62828
        title.text = "STRAWBERRY TIGER"
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: canvasWidth / 2,
                                  y: canvasHeight - 160)
        container.addChild(title)

        // Best score
        if bestScore > 0 {
            let best = SKLabelNode(fontNamed: "Helvetica")
            best.fontSize = 20
            best.fontColor = UIColor(red: 0.333, green: 0.333, blue: 0.333, alpha: 1)
            best.text = "Best: \(bestScore)"
            best.horizontalAlignmentMode = .center
            best.verticalAlignmentMode = .center
            best.position = CGPoint(x: canvasWidth / 2,
                                     y: canvasHeight - 195)
            container.addChild(best)
        }

        // Click to jump
        let tap = SKLabelNode(fontNamed: "Helvetica")
        tap.fontSize = 24
        tap.fontColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        tap.text = "Tap to Jump"
        tap.horizontalAlignmentMode = .center
        tap.verticalAlignmentMode = .center
        tap.position = CGPoint(x: canvasWidth / 2,
                                y: canvasHeight - 240)
        tap.name = "tapToJump"
        // Pulse animation
        let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        tap.run(.repeatForever(.sequence([fadeOut, fadeIn])))
        container.addChild(tap)

        // Footer credit
        let footer = SKLabelNode(fontNamed: "Helvetica")
        footer.fontSize = 13
        footer.fontColor = UIColor(red: 0.467, green: 0.467, blue: 0.467, alpha: 1)
        footer.text = "Designed and Created by Jiashi, Powered by Claude Code"
        footer.horizontalAlignmentMode = .center
        footer.verticalAlignmentMode = .center
        footer.position = CGPoint(x: canvasWidth / 2, y: 20)
        container.addChild(footer)

        return container
    }

    // MARK: - Game Over Screen

    static func makeGameOverOverlay(
        canvasWidth: CGFloat, canvasHeight: CGFloat, score: Int, bestScore: Int
    ) -> SKNode {
        let container = SKNode()
        container.zPosition = 200

        // Dark overlay
        let overlay = SKSpriteNode(color: UIColor(white: 0, alpha: 0.6),
                                    size: CGSize(width: canvasWidth, height: canvasHeight))
        overlay.anchorPoint = .zero
        overlay.position = .zero
        container.addChild(overlay)

        // Game Over text
        let gameOver = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameOver.fontSize = 44
        gameOver.fontColor = UIColor(red: 1, green: 0.176, blue: 0.333, alpha: 1) // #FF2D55
        gameOver.text = "GAME OVER"
        gameOver.horizontalAlignmentMode = .center
        gameOver.verticalAlignmentMode = .center
        gameOver.position = CGPoint(x: canvasWidth / 2, y: canvasHeight - 160)
        container.addChild(gameOver)

        // Score
        let scoreLbl = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLbl.fontSize = 30
        scoreLbl.fontColor = .white
        scoreLbl.text = "Score: \(score)"
        scoreLbl.horizontalAlignmentMode = .center
        scoreLbl.verticalAlignmentMode = .center
        scoreLbl.position = CGPoint(x: canvasWidth / 2, y: canvasHeight - 210)
        container.addChild(scoreLbl)

        // Best
        let bestLbl = SKLabelNode(fontNamed: "Helvetica")
        bestLbl.fontSize = 22
        bestLbl.fontColor = UIColor(red: 1, green: 0.843, blue: 0, alpha: 1) // #FFD700
        bestLbl.text = "Best: \(bestScore)"
        bestLbl.horizontalAlignmentMode = .center
        bestLbl.verticalAlignmentMode = .center
        bestLbl.position = CGPoint(x: canvasWidth / 2, y: canvasHeight - 245)
        container.addChild(bestLbl)

        // Tap to restart
        let tap = SKLabelNode(fontNamed: "Helvetica")
        tap.fontSize = 22
        tap.fontColor = .white
        tap.text = "Tap to Restart"
        tap.horizontalAlignmentMode = .center
        tap.verticalAlignmentMode = .center
        tap.position = CGPoint(x: canvasWidth / 2, y: canvasHeight - 300)
        let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        tap.run(.repeatForever(.sequence([fadeOut, fadeIn])))
        container.addChild(tap)

        return container
    }
}
