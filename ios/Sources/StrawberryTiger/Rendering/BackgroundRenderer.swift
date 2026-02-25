import SpriteKit
import UIKit

enum BackgroundRenderer {

    // MARK: - Sky gradient texture (full canvas size)

    static func makeSkyTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { uiCtx in
            let ctx = uiCtx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors: [CGColor] = [
                UIColor(red: 0.529, green: 0.808, blue: 0.922, alpha: 1).cgColor, // #87CEEB
                UIColor(red: 0.878, green: 0.941, blue: 1, alpha: 1).cgColor       // #E0F0FF
            ]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1]) {
                ctx.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: 0),
                                       end: CGPoint(x: 0, y: height),
                                       options: [])
            }
        }
        return SKTexture(image: image)
    }

    // MARK: - Cloud node

    static func makeCloudNode(width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()
        let color = UIColor(white: 1, alpha: 0.8)

        let main = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
        main.fillColor = color
        main.strokeColor = .clear
        main.position = .zero
        container.addChild(main)

        let puff1 = SKShapeNode(ellipseOf: CGSize(width: width * 0.6, height: height * 0.8))
        puff1.fillColor = color
        puff1.strokeColor = .clear
        puff1.position = CGPoint(x: -width * 0.2, y: -height * 0.1)
        container.addChild(puff1)

        let puff2 = SKShapeNode(ellipseOf: CGSize(width: width * 0.7, height: height * 0.7))
        puff2.fillColor = color
        puff2.strokeColor = .clear
        puff2.position = CGPoint(x: width * 0.2, y: -height * 0.1)
        container.addChild(puff2)

        return container
    }

    // MARK: - Ground node (full width, fixed height)

    static func makeGroundNode(canvasWidth: CGFloat, groundY: CGFloat, canvasHeight: CGFloat) -> SKNode {
        let container = SKNode()

        // SpriteKit Y: groundY in game coords → spriteKitY = canvasHeight - groundY
        // The ground starts at game y = groundY going down.
        // In SpriteKit coords (bottom-up), the ground top is at canvasHeight - groundY.
        // We don't set position here; the caller handles that.

        // Grass strip: 20px tall
        let grass = SKSpriteNode(color: UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1), // #4CAF50
                                 size: CGSize(width: canvasWidth, height: 20))
        grass.anchorPoint = CGPoint(x: 0, y: 1) // top-left
        grass.position = .zero
        container.addChild(grass)

        // Dirt: 50px tall
        let dirt = SKSpriteNode(
            color: UIColor(red: 0.545, green: 0.271, blue: 0.075, alpha: 1), // #8B4513
            size: CGSize(width: canvasWidth, height: 50))
        dirt.anchorPoint = CGPoint(x: 0, y: 1)
        dirt.position = CGPoint(x: 0, y: -20)
        container.addChild(dirt)

        return container
    }

    // MARK: - Grass detail lines (scrolling)
    // Returns a node with grass detail lines covering extra width for scrolling offset.

    static func makeGrassDetailNode(canvasWidth: CGFloat) -> SKNode {
        let container = SKNode()
        let strokeColor = UIColor(red: 0.22, green: 0.557, blue: 0.235, alpha: 1) // #388E3C

        // We draw from -20 to canvasWidth+20, stepping by 20
        var x: CGFloat = 0
        while x < canvasWidth + 40 {
            let line1 = SKShapeNode()
            let path1 = CGMutablePath()
            path1.move(to: CGPoint(x: x, y: 0))
            path1.addLine(to: CGPoint(x: x + 5, y: 6))
            line1.path = path1
            line1.strokeColor = strokeColor
            line1.lineWidth = 1
            container.addChild(line1)

            let line2 = SKShapeNode()
            let path2 = CGMutablePath()
            path2.move(to: CGPoint(x: x + 10, y: 0))
            path2.addLine(to: CGPoint(x: x + 13, y: 4))
            line2.path = path2
            line2.strokeColor = strokeColor
            line2.lineWidth = 1
            container.addChild(line2)

            x += 20
        }

        return container
    }
}
