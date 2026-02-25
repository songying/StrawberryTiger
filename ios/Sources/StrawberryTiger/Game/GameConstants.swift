import Foundation

enum GameConstants {
    static let canvasWidth: CGFloat = 800
    static let canvasHeight: CGFloat = 450
    static let groundY: CGFloat = 380

    static let gravity: CGFloat = 1800
    static let jumpVelocity: CGFloat = -650
    static let maxFallSpeed: CGFloat = 1200

    static let baseScrollSpeed: CGFloat = 250
    static let maxScrollSpeed: CGFloat = 500
    static let speedIncreaseRate: CGFloat = 2

    static let strawberrySpawnInterval: CGFloat = 1.2
    static let spawnIntervalVariance: CGFloat = 0.6
    static let goldenProbability: CGFloat = 0.10
    static let strawberryMinY: CGFloat = 220
    static let strawberryMaxY: CGFloat = 330
    static let strawberryRadius: CGFloat = 14
    static let clusterChance: CGFloat = 0.25

    static let rockSpawnInterval: CGFloat = 3.0
    static let rockSpawnVariance: CGFloat = 1.5
    static let rockWidth: CGFloat = 30
    static let rockHeight: CGFloat = 25

    static let tigerX: CGFloat = 120
    static let tigerWidth: CGFloat = 60
    static let tigerHeight: CGFloat = 50
    static let hitboxInset: CGFloat = 8
}
