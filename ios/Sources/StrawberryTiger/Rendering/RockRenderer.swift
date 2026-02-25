import SpriteKit
import UIKit

enum RockRenderer {

    static func makeTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { uiCtx in
            let ctx = uiCtx.cgContext
            let w = width
            let h = height

            // Main rock shape
            ctx.setFillColor(UIColor(red: 0.412, green: 0.412, blue: 0.412, alpha: 1).cgColor) // #696969
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 0, y: h))
            ctx.addLine(to: CGPoint(x: 5, y: 5))
            ctx.addLine(to: CGPoint(x: 15, y: 0))
            ctx.addLine(to: CGPoint(x: 25, y: 3))
            ctx.addLine(to: CGPoint(x: w, y: h))
            ctx.closePath()
            ctx.fillPath()

            // Highlight
            ctx.setFillColor(UIColor(red: 0.663, green: 0.663, blue: 0.663, alpha: 1).cgColor) // #A9A9A9
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 10, y: 5))
            ctx.addLine(to: CGPoint(x: 15, y: 1))
            ctx.addLine(to: CGPoint(x: 22, y: 5))
            ctx.closePath()
            ctx.fillPath()
        }
        return SKTexture(image: image)
    }
}
