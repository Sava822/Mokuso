import Foundation

enum OfflineContent {

    // MARK: - Intensity Ramp Stages (Unified Activation)

    struct IntensityRampStage {
        let text: String
        let intensity: Double // 0.0 (calm) → 1.0 (peak)
        let duration: Double
        let colorName: String // maps to theme color
    }

    static let intensityRampStages: [IntensityRampStage] = [
        IntensityRampStage(
            text: "Read every word in your mind.\nSee it. Feel it.\nLet the picture build inside you.",
            intensity: 0.10,
            duration: 6.0,
            colorName: "calmTeal"
        ),
        IntensityRampStage(
            text: "You are walking toward the tatami.\nThe mat is firm under your feet.\nThe crowd fades. Only you remain.",
            intensity: 0.20,
            duration: 6.0,
            colorName: "calmTeal"
        ),
        IntensityRampStage(
            text: "You step onto the mat.\nYou bow.\nHajime.\nEverything goes silent.",
            intensity: 0.40,
            duration: 6.0,
            colorName: "focusIndigo"
        ),
        IntensityRampStage(
            text: "Kumikata.\nYou grip the lapel. You grip the sleeve.\nYour hands lock in.\nYou start moving your opponent\nwhere you want him.",
            intensity: 0.55,
            duration: 7.0,
            colorName: "focusIndigo"
        ),
        IntensityRampStage(
            text: "You feel the moment.\nYou set your throw — the one you drilled\na thousand times.\nEntry. Pull. Rotation.\nYour body knows every step.",
            intensity: 0.75,
            duration: 7.0,
            colorName: "emberGold"
        ),
        IntensityRampStage(
            text: "The throw lands.\nYou follow straight to the ground.\nTransition. Control. No hesitation.",
            intensity: 0.88,
            duration: 6.0,
            colorName: "emberGold"
        ),
        IntensityRampStage(
            text: "Fight hard, but with respect.\nDon't let your win slip away.\nFight until the very end.\nNever give up.",
            intensity: 0.95,
            duration: 6.0,
            colorName: "crimsonPulse"
        )
    ]

    // MARK: - Breathing Coaching Texts (one per cycle)

    static let breathingCoachingTexts: [String] = [
        "Let the outside world fade away",
        "Each breath brings more control",
        "You are calm. You are present."
    ]

    // MARK: - Phase Footer Messages

    static let breathingFooter = "Slow breathing tells your body: I'm in control"
    static let focusFooter = "Full attention here means no room for overthinking"
    static let activationFooter = "Calm focus builds to controlled aggression — your optimal fight state"

    // MARK: - Why It Works Content

    struct PhaseExplanation {
        let phase: Int
        let title: String
        let duration: String
        let accentColorName: String
        let icon: String
        let why: String
        let scienceRef: String
        let athleteTip: String
    }

    static let phaseExplanations: [PhaseExplanation] = [
        PhaseExplanation(
            phase: 1,
            title: "Breathe & Settle",
            duration: "~60 sec",
            accentColorName: "calmTeal",
            icon: "wind",
            why: "Box breathing (4-4-4-4) lowers your heart rate, releases muscle tension, and puts your nervous system back under your control. Used by Navy SEALs before high-stress operations.",
            scienceRef: "Parasympathetic nervous system activation",
            athleteTip: "Your heart should pound before a fight. Breathing puts YOU in control of it."
        ),
        PhaseExplanation(
            phase: 2,
            title: "Sharpen & Focus",
            duration: "~60 sec",
            accentColorName: "focusIndigo",
            icon: "brain.head.profile",
            why: "A busy brain can't spiral into fear. A cognitive game forces a mental reset — breaking overthinking and redirecting your focus to the present moment.",
            scienceRef: "Attentional Focus Theory — sport psychology",
            athleteTip: "Don't fight with a scattered mind. Warm it up like you warm up your body."
        ),
        PhaseExplanation(
            phase: 3,
            title: "Activate",
            duration: "~60 sec",
            accentColorName: "crimsonPulse",
            icon: "flame",
            why: "When you vividly picture a throw, the same neural pathways fire as when you actually do it. Mental rehearsal can improve performance by 13–35%.",
            scienceRef: "Motor cortex priming — mental practice research",
            athleteTip: "The more detail you feel — the gi, the mat, the grip — the stronger the effect."
        )
    ]

    static let formulaSummary = "Calm body → Clear mind → Prime actions.\n\nThe order matters. Each phase enables the next, building total readiness in 3 minutes."
}
