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
            text: "Close your eyes.\nYou're walking toward the tatami.\nThe mat is firm under your feet.",
            intensity: 0.15,
            duration: 6.0,
            colorName: "calmTeal"
        ),
        IntensityRampStage(
            text: "You step onto the mat.\nYou bow.\nEverything goes silent.",
            intensity: 0.35,
            duration: 6.0,
            colorName: "calmTeal"
        ),
        IntensityRampStage(
            text: "You face your opponent.\nKumikita begins.\nLeft lapel. Right sleeve.\nYour grip locks in.",
            intensity: 0.55,
            duration: 7.0,
            colorName: "focusIndigo"
        ),
        IntensityRampStage(
            text: "See your throw.\nFeel the entry, the pull, the rotation.\nYour body knows every step.",
            intensity: 0.8,
            duration: 7.0,
            colorName: "emberGold"
        ),
        IntensityRampStage(
            text: "You are ready to explode.",
            intensity: 0.95,
            duration: 4.0,
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
            duration: "~60 seconds",
            accentColorName: "calmTeal",
            icon: "wind",
            why: "Box breathing (4-4-4-4) activates your parasympathetic nervous system — the body's built-in calm-down mechanism. It directly counteracts cortisol, lowers your heart rate, and releases muscle tension. Navy SEALs use this exact technique before high-stress operations.",
            scienceRef: "Zaccaro et al. (2018) — \"How Breath-Control Can Change Your Life\" — Frontiers in Human Neuroscience",
            athleteTip: "Your heart is supposed to pound before a fight. Breathing doesn't stop it — it puts YOU in control of it."
        ),
        PhaseExplanation(
            phase: 2,
            title: "Sharpen & Focus",
            duration: "~60 seconds",
            accentColorName: "focusIndigo",
            icon: "brain.head.profile",
            why: "When your brain is fully occupied solving a puzzle, it physically cannot spiral into fear or self-doubt. This is called an \"attention reset\" — sport psychologists use cognitive tasks to break rumination cycles and redirect mental energy toward the present moment.",
            scienceRef: "Nideffer (1976) — Attentional Focus Theory — widely applied in sport psychology",
            athleteTip: "Think of it like a mental warm-up. You wouldn't fight with cold muscles — don't fight with a scattered mind either."
        ),
        PhaseExplanation(
            phase: 3,
            title: "Activate",
            duration: "~60 seconds",
            accentColorName: "crimsonPulse",
            icon: "flame",
            why: "Visualization primes your motor cortex — the same neural pathways fire whether you throw a technique or vividly imagine throwing one. Research shows mental rehearsal can improve performance by 13–35%. Motivational priming builds optimal arousal — the sweet spot between too calm and too anxious.",
            scienceRef: "Feltz & Landers (1983) — Meta-analysis of mental practice effects on motor skill performance",
            athleteTip: "The more sensory detail you add — the feel of the gi, the sound of the mat — the stronger the neural rehearsal."
        )
    ]

    static let formulaSummary = "Calm body → Clear mind → Prime actions.\n\nThe order matters. You can't focus if your body is in fight-or-flight mode. You can't visualize if your mind is scattered. Each phase enables the next, building you toward a state of total readiness in just 3 minutes."
}
