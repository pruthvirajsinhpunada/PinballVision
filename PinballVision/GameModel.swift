import SwiftUI
import Observation

// MARK: - GameState

enum GameState: Equatable {
    case splash
    case playing
    case gameOver
}

// MARK: - ScoreEvent  (drives animated popup)

struct ScoreEvent: Identifiable, Equatable {
    let id        = UUID()
    let points    : Int
    let multiplier: Int
}

// MARK: - GameModel

@Observable
final class GameModel {

    // MARK: Persistent
    var highScore: Int = UserDefaults.standard.integer(forKey: "PinballHighScore")

    // MARK: Live state
    var state          : GameState  = .splash
    var score          : Int        = 0
    var lives          : Int        = 3
    var combo          : Int        = 0
    var isNewRecord    : Bool       = false
    var lastEvent      : ScoreEvent?
    var ballSaveActive : Bool       = false     // true for 2.5 s after each launch

    // Flipper state
    var leftFlipperActive  : Bool = false
    var rightFlipperActive : Bool = false

    // Commands consumed by PinballVolumeView
    var launchCommand    : Bool = false
    var resetBallCommand : Bool = false

    // MARK: Derived

    var multiplier: Int {
        switch combo {
        case 0..<3  : return 1
        case 3..<6  : return 2
        case 6..<10 : return 3
        default     : return 5
        }
    }

    var multiplierLabel: String? {
        combo >= 3 ? "×\(multiplier)" : nil
    }

    // MARK: - Actions

    func startGame() {
        score           = 0
        lives           = 3
        combo           = 0
        isNewRecord     = false
        ballSaveActive  = false
        ballSaveUsed    = false
        state           = .playing
        launchCommand   = true
    }

    func hitBumper(base: Int = 100) {
        comboResetTask?.cancel()
        combo = min(combo + 1, 20)
        let earned = base * multiplier
        score += earned
        lastEvent = ScoreEvent(points: earned, multiplier: multiplier)

        comboResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            self?.combo = 0
        }
    }

    /// Slingshot hit — scores flat points without advancing the combo chain.
    func hitSlingshot(base: Int = 50) {
        let earned = base * multiplier
        score += earned
        lastEvent = ScoreEvent(points: earned, multiplier: multiplier)
    }

    /// Rollover lane hit — scores flat points without advancing the combo chain.
    func hitLane(base: Int = 25) {
        let earned = base * multiplier
        score += earned
        lastEvent = ScoreEvent(points: earned, multiplier: multiplier)
    }

    func ballLost() {
        guard state == .playing else { return }

        // Ball save: absorb the drain, relaunch, but mark the save as used
        // so it can't trigger again on the same ball.
        if ballSaveActive {
            ballSaveTask?.cancel()
            ballSaveActive = false
            ballSaveUsed   = true
            launchCommand  = true   // auto-relaunch without activating save
            return
        }

        comboResetTask?.cancel()
        combo = 0
        lives -= 1
        if lives <= 0 {
            if score > highScore {
                highScore = score
                UserDefaults.standard.set(highScore, forKey: "PinballHighScore")
                isNewRecord = true
            }
            state = .gameOver
        } else {
            ballSaveUsed = false    // new ball → ball save eligible again
            resetBallCommand = true
        }
    }

    /// Call this immediately after the ball is physically launched.
    /// Has no effect if ball save was already used for this ball.
    func activateBallSave(duration: Double = 2.5) {
        guard !ballSaveUsed else { return }
        ballSaveTask?.cancel()
        ballSaveActive = true
        ballSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            self?.ballSaveActive = false
        }
    }

    // MARK: - Private
    private var comboResetTask : Task<Void, Never>?
    private var ballSaveTask   : Task<Void, Never>?
    private var ballSaveUsed   : Bool = false
}
