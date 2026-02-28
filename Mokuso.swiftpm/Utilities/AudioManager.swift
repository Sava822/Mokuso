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
        UserDefaults.standard.register(defaults: ["soundEnabled": false])

        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        // Pool of 6 player nodes for rich overlapping tones
        for _ in 0..<6 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }

        engine.mainMixerNode.outputVolume = 0.28

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            for player in players { player.play() }
        } catch {}
    }

    // MARK: - Tone Generation (Pure Sine)

    private func makeTone(
        frequency: Double,
        duration: Double,
        volume: Float,
        fadeIn: Double = 0.01,
        fadeOut: Double = 0.05
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let fadeInFrames = max(1, Int(sampleRate * fadeIn))
        let fadeOutFrames = max(1, Int(sampleRate * min(fadeOut, duration * 0.5)))
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

    // MARK: - Rich Tone Generation (With Harmonics)

    private func makeRichTone(
        frequency: Double,
        duration: Double,
        volume: Float,
        harmonics: [(partial: Double, amplitude: Float)] = [(2, 0.3), (3, 0.15), (5, 0.05)],
        fadeIn: Double = 0.015,
        fadeOut: Double = 0.1
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let fadeInFrames = max(1, Int(sampleRate * fadeIn))
        let fadeOutFrames = max(1, Int(sampleRate * min(fadeOut, duration * 0.5)))
        let total = Int(frameCount)

        for i in 0..<total {
            // Fundamental
            var s = Float(sin(2.0 * .pi * frequency * Double(i) / sampleRate))
            // Add harmonics for warmth
            for h in harmonics {
                s += h.amplitude * Float(sin(2.0 * .pi * frequency * h.partial * Double(i) / sampleRate))
            }
            // Envelope
            if i < fadeInFrames {
                s *= Float(i) / Float(fadeInFrames)
            } else if i > total - fadeOutFrames {
                let t = Float(total - i) / Float(fadeOutFrames)
                s *= t * t // Exponential fade for natural decay
            }
            data[i] = s * volume
        }
        return buffer
    }

    // MARK: - Chord Tone (Multiple Frequencies)

    private func makeChord(
        frequencies: [Double],
        duration: Double,
        volume: Float,
        fadeIn: Double = 0.02,
        fadeOut: Double = 0.15
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let fadeInFrames = max(1, Int(sampleRate * fadeIn))
        let fadeOutFrames = max(1, Int(sampleRate * min(fadeOut, duration * 0.5)))
        let total = Int(frameCount)
        let perNote = 1.0 / Float(frequencies.count)

        for i in 0..<total {
            var s: Float = 0
            for freq in frequencies {
                s += perNote * Float(sin(2.0 * .pi * freq * Double(i) / sampleRate))
            }
            if i < fadeInFrames {
                s *= Float(i) / Float(fadeInFrames)
            } else if i > total - fadeOutFrames {
                let t = Float(total - i) / Float(fadeOutFrames)
                s *= t * t
            }
            data[i] = s * volume
        }
        return buffer
    }

    private func play(_ buffer: AVAudioPCMBuffer) {
        guard isEnabled else { return }
        if !engine.isRunning {
            try? engine.start()
        }
        let player = players[playerIndex % players.count]
        playerIndex += 1
        if !player.isPlaying {
            player.play()
        }
        player.scheduleBuffer(buffer)
    }

    // MARK: - Breathing Sounds

    /// Warm ascending tone for inhale (G4 ≈ 396 Hz with harmonics)
    func breatheIn() {
        if let buf = makeRichTone(
            frequency: 396, duration: 0.6, volume: 0.07,
            harmonics: [(2, 0.25), (3, 0.08)],
            fadeIn: 0.08, fadeOut: 0.3
        ) { play(buf) }
    }

    /// Warm descending tone for exhale (C4 ≈ 264 Hz with harmonics)
    func breatheOut() {
        if let buf = makeRichTone(
            frequency: 264, duration: 0.6, volume: 0.06,
            harmonics: [(2, 0.2), (3, 0.06)],
            fadeIn: 0.05, fadeOut: 0.35
        ) { play(buf) }
    }

    // MARK: - Countdown & Transitions

    /// Crisp metallic tick for countdown (A5 = 880 Hz)
    func countdownTick() {
        if let buf = makeRichTone(
            frequency: 880, duration: 0.08, volume: 0.10,
            harmonics: [(2, 0.2), (4, 0.08)],
            fadeIn: 0.002, fadeOut: 0.04
        ) { play(buf) }
    }

    /// Resonant bell when a new phase begins (C4 with long decay)
    func phaseBell() {
        if let buf = makeRichTone(
            frequency: 261.63, duration: 1.2, volume: 0.09,
            harmonics: [(2, 0.35), (3, 0.15), (4, 0.06), (5, 0.03)],
            fadeIn: 0.01, fadeOut: 0.8
        ) { play(buf) }
    }

    // MARK: - Activate Phase

    /// Deep resonant impact for Hajime (E2 ≈ 82 Hz layered with octave)
    func hajimeImpact() {
        Task {
            // Deep hit
            if let buf = makeRichTone(
                frequency: 82.41, duration: 0.9, volume: 0.20,
                harmonics: [(2, 0.4), (3, 0.15), (4, 0.08)],
                fadeIn: 0.005, fadeOut: 0.5
            ) { play(buf) }
            // Octave shimmer layered on top
            try? await Task.sleep(for: .milliseconds(50))
            if let buf = makeRichTone(
                frequency: 164.81, duration: 0.5, volume: 0.08,
                harmonics: [(2, 0.2)],
                fadeIn: 0.01, fadeOut: 0.3
            ) { play(buf) }
        }
    }

    /// Subtle ascending tone when an activate stage advances
    func stageAdvance() {
        if let buf = makeRichTone(
            frequency: 440, duration: 0.15, volume: 0.06,
            harmonics: [(2, 0.2)],
            fadeIn: 0.005, fadeOut: 0.08
        ) { play(buf) }
    }

    // MARK: - Game Sounds

    /// Light tap for UI interactions and game tile presses
    func softTap() {
        if let buf = makeRichTone(
            frequency: 1200, duration: 0.04, volume: 0.06,
            harmonics: [(2, 0.15)],
            fadeIn: 0.001, fadeOut: 0.02
        ) { play(buf) }
    }

    /// Positive confirmation for correct answers (ascending fifth: C5 → G5)
    func correctTap() {
        Task {
            if let buf = makeRichTone(
                frequency: 523.25, duration: 0.1, volume: 0.09,
                harmonics: [(2, 0.2)],
                fadeIn: 0.003, fadeOut: 0.05
            ) { play(buf) }
            try? await Task.sleep(for: .milliseconds(80))
            if let buf = makeRichTone(
                frequency: 783.99, duration: 0.15, volume: 0.09,
                harmonics: [(2, 0.2)],
                fadeIn: 0.003, fadeOut: 0.08
            ) { play(buf) }
        }
    }

    /// Low gentle buzz for wrong answers
    func wrongBuzz() {
        if let buf = makeChord(
            frequencies: [185, 196],
            duration: 0.18, volume: 0.08,
            fadeIn: 0.005, fadeOut: 0.1
        ) { play(buf) }
    }

    // MARK: - Ritual Start & Completion

    /// Premium ascending triad when user taps START (C4 → E4 → G4 fast arpeggio)
    func startRitual() {
        Task {
            if let buf = makeRichTone(
                frequency: 261.63, duration: 0.12, volume: 0.09,
                harmonics: [(2, 0.25), (3, 0.1)],
                fadeIn: 0.005, fadeOut: 0.06
            ) { play(buf) }
            try? await Task.sleep(for: .milliseconds(90))
            if let buf = makeRichTone(
                frequency: 329.63, duration: 0.12, volume: 0.09,
                harmonics: [(2, 0.25), (3, 0.1)],
                fadeIn: 0.005, fadeOut: 0.06
            ) { play(buf) }
            try? await Task.sleep(for: .milliseconds(90))
            if let buf = makeRichTone(
                frequency: 392.00, duration: 0.25, volume: 0.10,
                harmonics: [(2, 0.25), (3, 0.1)],
                fadeIn: 0.005, fadeOut: 0.15
            ) { play(buf) }
        }
    }

    /// Rich C5–E5–G5 arpeggio for ritual completion
    func successChime() {
        Task {
            if let buf = makeRichTone(
                frequency: 523.25, duration: 0.2, volume: 0.10,
                harmonics: [(2, 0.25), (3, 0.08)],
                fadeIn: 0.005, fadeOut: 0.1
            ) { play(buf) }
            try? await Task.sleep(for: .milliseconds(150))
            if let buf = makeRichTone(
                frequency: 659.25, duration: 0.2, volume: 0.10,
                harmonics: [(2, 0.25), (3, 0.08)],
                fadeIn: 0.005, fadeOut: 0.1
            ) { play(buf) }
            try? await Task.sleep(for: .milliseconds(150))
            if let buf = makeRichTone(
                frequency: 783.99, duration: 0.45, volume: 0.12,
                harmonics: [(2, 0.25), (3, 0.08), (4, 0.04)],
                fadeIn: 0.005, fadeOut: 0.3
            ) { play(buf) }
        }
    }

    /// Stop all playing audio
    func stop() {
        for player in players { player.stop() }
    }
}
