import SpriteKit
import UIKit

enum TigerRenderer {

    /// The tiger drawing area: origin at (0,0) in the texture corresponds to
    /// the top-left corner of the bounding box that is 14px left of tiger.x and 1px above tiger.y.
    /// Texture size: 90 x 55 (covers tail tip through right whisker, ears through legs).
    static let textureWidth: CGFloat = 90
    static let textureHeight: CGFloat = 55

    /// Offset from tiger.x/tiger.y to the texture origin (top-left in game coords).
    /// The tail extends 14px left of tiger.x, ears ~1px above tiger.y.
    static let originOffsetX: CGFloat = 14
    static let originOffsetY: CGFloat = 1

    static func makeTexture(
        isOnGround: Bool,
        isPlaying: Bool,
        frameCount: Int
    ) -> SKTexture {
        let w = textureWidth
        let h = textureHeight
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { uiCtx in
            let ctx = uiCtx.cgContext

            // The local coordinate origin (lx, ly) maps to what game.js calls (tiger.x, tiger.y).
            let lx: CGFloat = originOffsetX
            let ly: CGFloat = originOffsetY

            // Helper: draw rounded rect into current path
            func addRoundedRect(_ rect: CGRect, radius: CGFloat) {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
                ctx.addPath(path.cgPath)
            }

            ctx.setLineCap(.round)

            // --- Tail ---
            let tipWag = sin(CGFloat(frameCount) * 0.12) * 4

            ctx.setStrokeColor(UIColor(red: 1, green: 0.549, blue: 0, alpha: 1).cgColor) // #FF8C00
            ctx.setLineWidth(5)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: lx + 8, y: ly + 20))
            ctx.addQuadCurve(to: CGPoint(x: lx - 14, y: ly + 12 + tipWag),
                             control: CGPoint(x: lx - 6, y: ly + 16))
            ctx.strokePath()

            // Tail rings
            ctx.setStrokeColor(UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1).cgColor) // #1a1a1a
            ctx.setLineWidth(2)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: lx - 1, y: ly + 17.5))
            ctx.addLine(to: CGPoint(x: lx - 3, y: ly + 19))
            ctx.strokePath()
            ctx.beginPath()
            ctx.move(to: CGPoint(x: lx - 7, y: ly + 15))
            ctx.addLine(to: CGPoint(x: lx - 9, y: ly + 16.5))
            ctx.strokePath()
            ctx.beginPath()
            ctx.move(to: CGPoint(x: lx - 12, y: ly + 12.5 + tipWag * 0.7))
            ctx.addLine(to: CGPoint(x: lx - 14, y: ly + 14 + tipWag * 0.7))
            ctx.strokePath()

            // --- Body ---
            ctx.setFillColor(UIColor(red: 1, green: 0.549, blue: 0, alpha: 1).cgColor)
            addRoundedRect(CGRect(x: lx + 6, y: ly + 10, width: 46, height: 32), radius: 8)
            ctx.fillPath()

            // White belly
            ctx.setFillColor(UIColor(red: 1, green: 0.953, blue: 0.878, alpha: 1).cgColor) // #FFF3E0
            let bellyPath = UIBezierPath(ovalIn: CGRect(
                x: lx + 30 - 18, y: ly + 36 - 6, width: 36, height: 12))
            ctx.addPath(bellyPath.cgPath)
            ctx.fillPath()

            // Body stripes
            ctx.setStrokeColor(UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1).cgColor)
            ctx.setLineWidth(2.5)

            let stripes: [(CGPoint, CGPoint, CGPoint)] = [
                (CGPoint(x: lx + 16, y: ly + 12), CGPoint(x: lx + 14, y: ly + 24), CGPoint(x: lx + 17, y: ly + 36)),
                (CGPoint(x: lx + 24, y: ly + 11), CGPoint(x: lx + 22, y: ly + 22), CGPoint(x: lx + 25, y: ly + 35)),
                (CGPoint(x: lx + 32, y: ly + 11), CGPoint(x: lx + 34, y: ly + 22), CGPoint(x: lx + 31, y: ly + 36)),
                (CGPoint(x: lx + 40, y: ly + 12), CGPoint(x: lx + 42, y: ly + 24), CGPoint(x: lx + 39, y: ly + 35)),
            ]
            for (start, ctrl, end) in stripes {
                ctx.beginPath()
                ctx.move(to: start)
                ctx.addQuadCurve(to: end, control: ctrl)
                ctx.strokePath()
            }

            // --- Ears ---
            func drawEllipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, rotation: CGFloat, color: UIColor, startAngle: CGFloat = 0, endAngle: CGFloat = .pi * 2) {
                ctx.saveGState()
                ctx.translateBy(x: cx, y: cy)
                ctx.rotate(by: rotation)
                ctx.setFillColor(color.cgColor)
                let rect = CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)
                if startAngle == 0 && endAngle == .pi * 2 {
                    ctx.fillEllipse(in: rect)
                } else {
                    // For half ellipse (ear backs): scale a circle arc
                    ctx.scaleBy(x: 1, y: ry / rx)
                    ctx.beginPath()
                    ctx.addArc(center: .zero, radius: rx, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    ctx.closePath()
                    ctx.fillPath()
                }
                ctx.restoreGState()
            }

            // Left ear
            drawEllipse(cx: lx + 43, cy: ly + 3, rx: 5, ry: 6, rotation: -0.15,
                        color: UIColor(red: 1, green: 0.549, blue: 0, alpha: 1))
            // Right ear
            drawEllipse(cx: lx + 57, cy: ly + 3, rx: 5, ry: 6, rotation: 0.15,
                        color: UIColor(red: 1, green: 0.549, blue: 0, alpha: 1))

            // Black ear backs (half ellipse, PI to 2*PI in canvas = top half in flipped coords)
            drawEllipse(cx: lx + 43, cy: ly + 1, rx: 4, ry: 4, rotation: -0.15,
                        color: UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1),
                        startAngle: .pi, endAngle: .pi * 2)
            drawEllipse(cx: lx + 57, cy: ly + 1, rx: 4, ry: 4, rotation: 0.15,
                        color: UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1),
                        startAngle: .pi, endAngle: .pi * 2)

            // White ear spots
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: lx + 43 - 2, y: ly + 1 - 2, width: 4, height: 4))
            ctx.fillEllipse(in: CGRect(x: lx + 57 - 2, y: ly + 1 - 2, width: 4, height: 4))

            // --- Head ---
            ctx.setFillColor(UIColor(red: 1, green: 0.647, blue: 0, alpha: 1).cgColor) // #FFA500
            ctx.fillEllipse(in: CGRect(x: lx + 50 - 13, y: ly + 13 - 12, width: 26, height: 24))

            // White muzzle
            ctx.setFillColor(UIColor(red: 1, green: 0.973, blue: 0.882, alpha: 1).cgColor) // #FFF8E1
            ctx.fillEllipse(in: CGRect(x: lx + 50 - 8, y: ly + 18 - 6, width: 16, height: 12))

            // White cheek patches
            ctx.setFillColor(UIColor(red: 1, green: 0.953, blue: 0.878, alpha: 1).cgColor)
            drawEllipse(cx: lx + 42, cy: ly + 15, rx: 4, ry: 3, rotation: -0.3,
                        color: UIColor(red: 1, green: 0.953, blue: 0.878, alpha: 1))
            drawEllipse(cx: lx + 58, cy: ly + 15, rx: 4, ry: 3, rotation: 0.3,
                        color: UIColor(red: 1, green: 0.953, blue: 0.878, alpha: 1))

            // Face stripes
            ctx.setStrokeColor(UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1).cgColor)
            ctx.setLineWidth(2)
            let faceStripes: [(CGPoint, CGPoint, CGPoint)] = [
                (CGPoint(x: lx + 40, y: ly + 6), CGPoint(x: lx + 42, y: ly + 9), CGPoint(x: lx + 44, y: ly + 8)),
                (CGPoint(x: lx + 38, y: ly + 9), CGPoint(x: lx + 41, y: ly + 12), CGPoint(x: lx + 43, y: ly + 11)),
                (CGPoint(x: lx + 60, y: ly + 6), CGPoint(x: lx + 58, y: ly + 9), CGPoint(x: lx + 56, y: ly + 8)),
                (CGPoint(x: lx + 62, y: ly + 9), CGPoint(x: lx + 59, y: ly + 12), CGPoint(x: lx + 57, y: ly + 11)),
            ]
            for (start, ctrl, end) in faceStripes {
                ctx.beginPath()
                ctx.move(to: start)
                ctx.addQuadCurve(to: end, control: ctrl)
                ctx.strokePath()
            }

            // Eyes - white
            ctx.setFillColor(UIColor.white.cgColor)
            drawEllipse(cx: lx + 45, cy: ly + 11, rx: 3.5, ry: 2.5, rotation: -0.1, color: .white)
            drawEllipse(cx: lx + 55, cy: ly + 11, rx: 3.5, ry: 2.5, rotation: 0.1, color: .white)

            // Amber iris
            ctx.setFillColor(UIColor(red: 0.902, green: 0.659, blue: 0, alpha: 1).cgColor) // #E6A800
            ctx.fillEllipse(in: CGRect(x: lx + 46 - 2, y: ly + 11 - 2, width: 4, height: 4))
            ctx.fillEllipse(in: CGRect(x: lx + 56 - 2, y: ly + 11 - 2, width: 4, height: 4))

            // Black pupils
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fillEllipse(in: CGRect(x: lx + 46 - 1, y: ly + 11 - 1, width: 2, height: 2))
            ctx.fillEllipse(in: CGRect(x: lx + 56 - 1, y: ly + 11 - 1, width: 2, height: 2))

            // Nose
            ctx.setFillColor(UIColor(red: 0.831, green: 0.341, blue: 0.42, alpha: 1).cgColor) // #D4576B
            ctx.fillEllipse(in: CGRect(x: lx + 50 - 3, y: ly + 16 - 2, width: 6, height: 4))
            ctx.setFillColor(UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1).cgColor)
            // Bottom half of nose
            ctx.saveGState()
            ctx.translateBy(x: lx + 50, y: ly + 15.5)
            ctx.scaleBy(x: 1, y: 1.5 / 2.5)
            ctx.beginPath()
            ctx.addArc(center: .zero, radius: 2.5, startAngle: 0, endAngle: .pi, clockwise: false)
            ctx.closePath()
            ctx.fillPath()
            ctx.restoreGState()

            // Mouth line
            ctx.setStrokeColor(UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1).cgColor)
            ctx.setLineWidth(1)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: lx + 50, y: ly + 17.5))
            ctx.addLine(to: CGPoint(x: lx + 50, y: ly + 19))
            ctx.strokePath()
            // Mouth arcs
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: lx + 47, y: ly + 19), radius: 3,
                       startAngle: 0, endAngle: .pi, clockwise: false)
            ctx.strokePath()
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: lx + 53, y: ly + 19), radius: 3,
                       startAngle: 0, endAngle: .pi, clockwise: false)
            ctx.strokePath()

            // Whiskers
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)
            let whiskers: [(CGPoint, CGPoint)] = [
                (CGPoint(x: lx + 43, y: ly + 17), CGPoint(x: lx + 32, y: ly + 15)),
                (CGPoint(x: lx + 43, y: ly + 18), CGPoint(x: lx + 31, y: ly + 19)),
                (CGPoint(x: lx + 43, y: ly + 19), CGPoint(x: lx + 33, y: ly + 23)),
                (CGPoint(x: lx + 57, y: ly + 17), CGPoint(x: lx + 68, y: ly + 15)),
                (CGPoint(x: lx + 57, y: ly + 18), CGPoint(x: lx + 69, y: ly + 19)),
                (CGPoint(x: lx + 57, y: ly + 19), CGPoint(x: lx + 67, y: ly + 23)),
            ]
            for (from, to) in whiskers {
                ctx.beginPath()
                ctx.move(to: from)
                ctx.addLine(to: to)
                ctx.strokePath()
            }

            // --- Legs ---
            ctx.setStrokeColor(UIColor(red: 1, green: 0.549, blue: 0, alpha: 1).cgColor)
            ctx.setLineWidth(4)
            ctx.setLineCap(.round)

            if isOnGround && isPlaying {
                let legPhase = sin(CGFloat(frameCount) * 0.3)
                let legs: [(CGPoint, CGPoint)] = [
                    (CGPoint(x: lx + 38, y: ly + 40), CGPoint(x: lx + 38 + legPhase * 6, y: ly + 50)),
                    (CGPoint(x: lx + 44, y: ly + 40), CGPoint(x: lx + 44 - legPhase * 6, y: ly + 50)),
                    (CGPoint(x: lx + 16, y: ly + 40), CGPoint(x: lx + 16 - legPhase * 6, y: ly + 50)),
                    (CGPoint(x: lx + 22, y: ly + 40), CGPoint(x: lx + 22 + legPhase * 6, y: ly + 50)),
                ]
                for (from, to) in legs {
                    ctx.beginPath()
                    ctx.move(to: from)
                    ctx.addLine(to: to)
                    ctx.strokePath()
                }
            } else if !isOnGround {
                let legs: [(CGPoint, CGPoint)] = [
                    (CGPoint(x: lx + 38, y: ly + 40), CGPoint(x: lx + 42, y: ly + 46)),
                    (CGPoint(x: lx + 44, y: ly + 40), CGPoint(x: lx + 48, y: ly + 46)),
                    (CGPoint(x: lx + 16, y: ly + 40), CGPoint(x: lx + 12, y: ly + 46)),
                    (CGPoint(x: lx + 22, y: ly + 40), CGPoint(x: lx + 18, y: ly + 46)),
                ]
                for (from, to) in legs {
                    ctx.beginPath()
                    ctx.move(to: from)
                    ctx.addLine(to: to)
                    ctx.strokePath()
                }
            } else {
                let legs: [(CGPoint, CGPoint)] = [
                    (CGPoint(x: lx + 38, y: ly + 40), CGPoint(x: lx + 38, y: ly + 50)),
                    (CGPoint(x: lx + 44, y: ly + 40), CGPoint(x: lx + 44, y: ly + 50)),
                    (CGPoint(x: lx + 16, y: ly + 40), CGPoint(x: lx + 16, y: ly + 50)),
                    (CGPoint(x: lx + 22, y: ly + 40), CGPoint(x: lx + 22, y: ly + 50)),
                ]
                for (from, to) in legs {
                    ctx.beginPath()
                    ctx.move(to: from)
                    ctx.addLine(to: to)
                    ctx.strokePath()
                }
            }
        }
        return SKTexture(image: image)
    }
}
