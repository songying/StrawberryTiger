import SpriteKit
import UIKit

enum StrawberryRenderer {

    // The strawberry is drawn centered at (radius+4, radius+4) in a slightly larger texture
    // to accommodate glow, leaves, and stem.
    static func textureSize(radius: CGFloat) -> CGSize {
        CGSize(width: (radius + 12) * 2, height: (radius + 12) * 2)
    }

    static func makeTexture(radius: CGFloat, isGolden: Bool) -> SKTexture {
        let r = radius
        let pad: CGFloat = 12 // extra padding for glow + leaves + stem
        let size = CGSize(width: (r + pad) * 2, height: (r + pad) * 2)
        let cx = size.width / 2
        let cy = size.height / 2

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { uiCtx in
            let ctx = uiCtx.cgContext
            let x = cx
            let y = cy

            // Glow for golden
            if isGolden {
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 15,
                              color: UIColor(red: 1, green: 0.843, blue: 0, alpha: 0.8).cgColor)
            }

            // Berry body
            let bodyColor: UIColor = isGolden
                ? UIColor(red: 1, green: 0.843, blue: 0, alpha: 1)    // #FFD700
                : UIColor(red: 1, green: 0.176, blue: 0.333, alpha: 1) // #FF2D55
            ctx.setFillColor(bodyColor.cgColor)

            let bodyPath = UIBezierPath()
            bodyPath.move(to: CGPoint(x: x, y: y - r * 0.6))
            bodyPath.addQuadCurve(
                to: CGPoint(x: x + r * 0.9, y: y + r * 0.2),
                controlPoint: CGPoint(x: x + r, y: y - r * 0.6))
            bodyPath.addQuadCurve(
                to: CGPoint(x: x, y: y + r * 1.2),
                controlPoint: CGPoint(x: x + r * 0.5, y: y + r * 1.3))
            bodyPath.addQuadCurve(
                to: CGPoint(x: x - r * 0.9, y: y + r * 0.2),
                controlPoint: CGPoint(x: x - r * 0.5, y: y + r * 1.3))
            bodyPath.addQuadCurve(
                to: CGPoint(x: x, y: y - r * 0.6),
                controlPoint: CGPoint(x: x - r, y: y - r * 0.6))
            bodyPath.close()
            ctx.addPath(bodyPath.cgPath)
            ctx.fillPath()

            if isGolden {
                ctx.restoreGState()
            }

            // Seeds
            let seedColor: UIColor = isGolden
                ? .white
                : UIColor(red: 1, green: 0.843, blue: 0, alpha: 1)
            ctx.setFillColor(seedColor.cgColor)
            let seeds: [(CGFloat, CGFloat)] = [
                (x - 3, y), (x + 3, y),
                (x - 4, y + r * 0.5), (x + 4, y + r * 0.5),
                (x, y + r * 0.8)
            ]
            for (sx, sy) in seeds {
                ctx.fillEllipse(in: CGRect(x: sx - 1, y: sy - 2, width: 2, height: 4))
            }

            // Leaves
            let leafColor = UIColor(red: 0.133, green: 0.545, blue: 0.133, alpha: 1) // #228B22
            ctx.setFillColor(leafColor.cgColor)
            // Left leaf
            ctx.saveGState()
            ctx.translateBy(x: x - 4, y: y - r * 0.7)
            ctx.rotate(by: -0.4)
            ctx.fillEllipse(in: CGRect(x: -5, y: -3, width: 10, height: 6))
            ctx.restoreGState()
            // Right leaf
            ctx.saveGState()
            ctx.translateBy(x: x + 4, y: y - r * 0.7)
            ctx.rotate(by: 0.4)
            ctx.fillEllipse(in: CGRect(x: -5, y: -3, width: 10, height: 6))
            ctx.restoreGState()

            // Stem
            ctx.setStrokeColor(leafColor.cgColor)
            ctx.setLineWidth(2)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: y - r * 0.6))
            ctx.addLine(to: CGPoint(x: x, y: y - r * 0.9))
            ctx.strokePath()

            // Golden sparkle (static – we'll animate alpha in the scene)
            if isGolden {
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.beginPath()
                ctx.move(to: CGPoint(x: x + r + 4, y: y - 4))
                ctx.addLine(to: CGPoint(x: x + r + 7, y: y))
                ctx.addLine(to: CGPoint(x: x + r + 4, y: y + 4))
                ctx.addLine(to: CGPoint(x: x + r + 1, y: y))
                ctx.closePath()
                ctx.fillPath()
            }
        }
        return SKTexture(image: image)
    }
}
