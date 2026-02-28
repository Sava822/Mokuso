import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat
    private var playerIndex = 0

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    private init() {
        // Register default so .bool(forKey:) returns true when unset
        UserDefaults.standard.register(defaults: ["soundEnabled": true])

        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        // Pool of 4 player nodes for overlapping tones
        for _ in 0..<4 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }

        engine.mainMixerNode.outputVolume = 0.35

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            for player in players { player.play() }
        } catch {
            // Audio unavailable — fail silently
        }
    }

    // MARK: - Tone Generation

    private func makeTone(
        frequency: Double,
        duration: Double,
        volume: Float,
        fadeOut: Double = 0.05
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else { return nil }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let fadeInFrames = max(1, Int(sampleRate * 0.01))
        let fadeOutFrames = max(1, Int(sampleRate * min(fadeOut, duration * 0.4)))
        let total = Int(frameCount)

        for i in 0..<total {
            var s = Float(sin(2.0 * .pi * frequency * Double(i) / sampleRate))

            if i < fadeInFrames {
                s *= Float(i) / Float(fadeInFrames)
            } else if i > total - fadeOutFrames {
                s *= Float(total - i) / Float(fadeOutFrames)
            }

            data[i] = s * volume
        }
        return buffer
    }

    private func play(_ buffer: AVAudioPCMBuffer) {
        guard isEnabled else { return }
        if !engine.isRunning {
            try? engine.start()
            for p in players { p.play() }
        }
        let player = players[playerIndex % players.count]
        playerIndex += 1
        player.scheduleBuffer(buffer)
    }

    // MARK: - Sound Effects

    /// Gentle ascending tone for inhale (G4 ≈ 396 Hz)
    func breatheIn() {
        if let buf = makeTone(frequency: 396, duration: 0.5, volume: 0.12, fadeOut: 0.2) {
            play(buf)
        }
    }

    /// Gentle descending tone for exhale (C4 ≈ 264 Hz)
    func breatheOut() {
        if let buf = makeTone(frequency: 264, duration: 0.5, volume: 0.10, fadeOut: 0.2) {
            play(buf)
        }
    }

    /// Soft tick for countdown (A5 = 880 Hz)
    func countdownTick() {
        if let buf = makeTone(frequency: 880, duration: 0.06, volume: 0.18) {
            play(buf)
        }
    }

    /// Phase transition chime (C5 ≈ 523 Hz)
    func transitionChime() {
        if let buf = makeTone(frequency: 523.25, duration: 0.3, volume: 0.16, fadeOut: 0.15) {
            play(buf)
        }
    }

    /// Deep impact for Hajime (E2 ≈ 82 Hz)
    func hajimeImpact() {
        if let buf = makeTone(frequency: 82.41, duration: 0.7, volume: 0.3, fadeOut: 0.3) {
            play(buf)
        }
    }

    /// C–E–G arpeggio for completion
    func successChime() {
        Task {
            if let buf = makeTone(frequency: 523.25, duration: 0.18, volume: 0.18) { play(buf) }
            try? await Task.sleep(for: .milliseconds(170))
            if let buf = makeTone(frequency: 659.25, duration: 0.18, volume: 0.18) { play(buf) }
            try? await Task.sleep(for: .milliseconds(170))
            if let buf = makeTone(frequency: 783.99, duration: 0.35, volume: 0.20, fadeOut: 0.2) { play(buf) }
        }
    }

    /// Stop all playing audio
    func stop() {
        for player in players { player.stop() }
    }
}
