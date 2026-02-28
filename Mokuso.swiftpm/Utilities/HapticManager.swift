import UIKit

@MainActor
enum HapticManager {

    // Haptics are unavailable on Mac — all methods gracefully no-op
    private static var hapticsAvailable: Bool {
        UIDevice.current.userInterfaceIdiom == .phone || UIDevice.current.userInterfaceIdiom == .pad
    }

    // MARK: - Impact Haptics

    static func light() {
        guard hapticsAvailable else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func medium() {
        guard hapticsAvailable else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    static func heavy() {
        guard hapticsAvailable else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Notification Haptics

    static func success() {
        guard hapticsAvailable else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func error() {
        guard hapticsAvailable else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    static func warning() {
        guard hapticsAvailable else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    // MARK: - Crisp / Soft Haptics

    static func rigid() {
        guard hapticsAvailable else { return }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }

    static func soft() {
        guard hapticsAvailable else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Intensity-Based

    static func forIntensity(_ intensity: Double) {
        if intensity <= 0.4 {
            light()
        } else if intensity <= 0.7 {
            medium()
        } else {
            heavy()
        }
    }

    // MARK: - Hold Pulse (escalating with intensity)

    static func holdPulse(_ intensity: Double) {
        if intensity <= 0.3 {
            soft()
        } else if intensity <= 0.6 {
            rigid()
        } else {
            guard hapticsAvailable else { return }
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.prepare()
            gen.impactOccurred(intensity: min(intensity, 1.0))
        }
    }
}
