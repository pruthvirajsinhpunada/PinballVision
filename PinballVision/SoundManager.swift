import AVFoundation
import Observation

// MARK: - SoundManager
//
// Synthesises all game sounds via AVAudioEngine so no audio asset files
// are required.  Every public method is safe to call from the main thread.

@Observable
final class SoundManager {

    private let engine     = AVAudioEngine()
    private let sampleRate : Double = 44_100
    private let mono       : AVAudioFormat

    init() {
        mono = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        try? engine.start()
    }

    // MARK: - Public API

    /// Short metallic ping; pitch rises with multiplier tier.
    func playBumperHit(multiplier: Int = 1) {
        let freq = Double(500 + multiplier * 100)
        fire(sineEnvelope(freq: freq, duration: 0.10,
                          attack: 0.003, sustain: 0.02, release: 0.075),
             volume: 0.55)
    }

    /// Quick noise burst — the flipper "thwack".
    func playFlipper() {
        fire(noiseDecay(duration: 0.055), volume: 0.40)
    }

    /// Short punchy hit for slingshot kickers.
    func playSlingshotHit() {
        fire(sineEnvelope(freq: 720, duration: 0.07,
                          attack: 0.002, sustain: 0.01, release: 0.055),
             volume: 0.60)
    }

    /// Bright chime when the ball crosses a rollover lane.
    func playLaneScore() {
        fire(sineEnvelope(freq: 900, duration: 0.13,
                          attack: 0.004, sustain: 0.04, release: 0.085),
             volume: 0.38)
    }

    /// Rising sweep as the ball launches.
    func playLaunch() {
        fire(freqSweep(from: 150, to: 850, duration: 0.28), volume: 0.65)
    }

    /// Descending whoop when a ball drains.
    func playBallLost() {
        fire(freqSweep(from: 380, to: 80, duration: 0.65), volume: 0.75)
    }

    /// Four descending notes — C5 → G#4 → E4 → C4.
    func playGameOver() {
        let notes: [(Double, Double)] = [
            (523.25, 0.00),
            (415.30, 0.22),
            (329.63, 0.44),
            (261.63, 0.66),
        ]
        for (freq, delay) in notes {
            guard let buf = sineEnvelope(freq: freq, duration: 0.30,
                                         attack: 0.01, sustain: 0.10,
                                         release: 0.18) else { continue }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.fire(buf, volume: 0.70)
            }
        }
    }

    // MARK: - Engine

    private func fire(_ buffer: AVAudioPCMBuffer?, volume: Float) {
        guard let buffer else { return }
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: mono)
        node.volume = volume
        node.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async { [weak self, weak node] in
                guard let self, let node else { return }
                self.engine.detach(node)
            }
        }
        if !engine.isRunning { try? engine.start() }
        node.play()
    }

    // MARK: - Waveform generators

    /// ADSR sine tone.
    private func sineEnvelope(freq: Double, duration: Double,
                               attack: Double, sustain: Double,
                               release: Double) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(sampleRate * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: count) else { return nil }
        buf.frameLength = count
        let data = buf.floatChannelData![0]
        for i in 0..<Int(count) {
            let t   = Double(i) / sampleRate
            let env : Double
            if t < attack {
                env = t / attack
            } else if t < attack + sustain {
                env = 1.0
            } else {
                env = max(0, 1.0 - (t - attack - sustain) / release)
            }
            data[i] = Float(env * sin(2.0 * .pi * freq * t))
        }
        return buf
    }

    /// Linear frequency sweep with fade-out.
    private func freqSweep(from startHz: Double, to endHz: Double,
                            duration: Double) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(sampleRate * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: count) else { return nil }
        buf.frameLength = count
        let data = buf.floatChannelData![0]
        var phase = 0.0
        for i in 0..<Int(count) {
            let t    = Double(i) / sampleRate
            let prog = t / duration
            let freq = startHz + (endHz - startHz) * prog
            let env  = 1.0 - prog * 0.65
            phase   += 2.0 * .pi * freq / sampleRate
            data[i]  = Float(sin(phase) * env)
        }
        return buf
    }

    /// White noise with linear decay — used for the flipper thwack.
    private func noiseDecay(duration: Double) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(sampleRate * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: count) else { return nil }
        buf.frameLength = count
        let data = buf.floatChannelData![0]
        for i in 0..<Int(count) {
            let env  = 1.0 - Double(i) / Double(count)
            data[i]  = Float(Float.random(in: -1...1) * Float(env))
        }
        return buf
    }
}
