import Foundation

enum ScoreManager {
    private static let key = "strawberrytiger_best"

    static func getHighScore() -> Int {
        UserDefaults.standard.integer(forKey: key)
    }

    static func saveHighScore(_ score: Int) {
        let best = getHighScore()
        if score > best {
            UserDefaults.standard.set(score, forKey: key)
        }
    }
}
