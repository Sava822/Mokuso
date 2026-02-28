import SwiftUI
import SwiftData

// MARK: - Flow Phase State Machine

enum FlowPhase: Equatable {
    case intro
    case countdown
    case breathing
    case transition
    case focus
    case activate
    case done
}

// MARK: - Breath Phase

enum BreathPhase: String {
    case inhale = "Inhale"
    case holdIn = "Hold"
    case exhale = "Exhale"
    case holdOut = "Hold "

    var displayText: String {
        switch self {
        case .inhale: return "Inhale"
        case .holdIn: return "Hold"
        case .exhale: return "Exhale"
        case .holdOut: return "Hold"
        }
    }

    var sideIndex: Int {
        switch self {
        case .inhale: return 0
        case .holdIn: return 1
        case .exhale: return 2
        case .holdOut: return 3
        }
    }
}

// MARK: - PreFight Flow View

struct PreFightFlowView: View {
    @Query private var settings: [UserSettings]
    @Query private var streakData: [StreakData]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("selectedPreFightGame") private var selectedGameRaw: String = PreFightGame.reactionTap.rawValue

    private var isIPad: Bool { horizontalSizeClass == .regular }

    // Phase state
    @State private var phase: FlowPhase = .intro
    @State private var phaseTask: Task<Void, Never>?

    // Dynamic phase order
    @State private var currentRitualIndex = 0
    @State private var pendingTransitionPhase: RitualPhase?

    // Intro animation
    @State private var introCircleScale: CGFloat = 1.0
    @State private var introCardScale: CGFloat = 0.0
    @State private var introCardRotation: Double = 45
    @State private var introTextOpacity: Double = 1.0
    @State private var introCircleOpacity: Double = 1.0
    @State private var introRingScale: CGFloat = 1.0
    @State private var introRingOpacity: Double = 0
    @State private var introDiamondRotation: Double = 0
    @State private var introDiamondScale: CGFloat = 0.3
    @State private var introDiamondOpacity: Double = 0
    @State private var introCountdownOpacity: Double = 0

    // Countdown
    @State private var countdownNumber = 3

    // Breathing
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathCycle = 1
    @State private var boxSideProgress: CGFloat = 0
    @State private var breathSecondsLeft: Int = 4
    @State private var boxCompletedSides: Int = 0
    @State private var circleScale: CGFloat = 0.6
    @State private var traceEraseProgress: CGFloat = 0

    // Transition animation
    @State private var transIconScale: CGFloat = 0.3
    @State private var transIconOpacity: Double = 0
    @State private var transRingScale: CGFloat = 0.8
    @State private var transRingOpacity: Double = 0
    @State private var transTitleOpacity: Double = 0
    @State private var transTitleOffset: CGFloat = 20
    @State private var transSubtitleOpacity: Double = 0

    // Focus timer
    @State private var focusTimeRemaining = 40

    // Breathing coaching
    @State private var breathCoachingText: String = ""

    // Intensity Ramp (interactive press-and-hold)
    @State private var rampStep = 0
    @State private var rampTextOpacity: Double = 1
    @State private var rampProgress: CGFloat = 0
    @State private var rampIntensity: Double = 0
    @State private var rampColor: Color = .calmTeal
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var showHajime = false
    @State private var hajimeTriggered = false

    // Hajime explosion animation
    @State private var hajimeCircleScale: CGFloat = 0.3
    @State private var hajimeRingScale: CGFloat = 1.0
    @State private var hajimeRingOpacity: Double = 0
    @State private var hajimeDiamondRotation: Double = 0
    @State private var hajimeDiamondScale: CGFloat = 0.3
    @State private var hajimeDiamondOpacity: Double = 0
    @State private var hajimeCardScale: CGFloat = 0.0
    @State private var hajimeCardRotation: Double = 45
    @State private var hajimeTextOpacity: Double = 0
    @State private var hajimeButtonOpacity: Double = 0

    // Done
    @State private var doneScale: CGFloat = 0.5

    private var currentSettings: UserSettings {
        if let first = settings.first { return first }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    private var ritualPhaseOrder: [RitualPhase] {
        currentSettings.phaseOrder
    }

    var body: some View {
        ZStack {
            // Background
            Color.dojoBlack.ignoresSafeArea()

            if phase != .intro {
                RadialGradient(
                    colors: [phaseAccentColor.opacity(0.08), Color.clear],
                    center: .center,
                    startRadius: isIPad ? 20 : 10,
                    endRadius: isIPad ? 550 : 350
                )
                .ignoresSafeArea()
            }

            if phase != .intro {
                DojoGrainOverlay()

                // Ambient embers — color matches current phase
                FloatingEmbers(
                    color: phaseAccentColor,
                    count: isIPad ? 20 : 12,
                    speed: phase == .activate ? 1.3 : 0.6
                )
                .id(phase) // reset embers when phase changes
            }

            if phase == .intro {
                introView
            } else {
                VStack(spacing: 0) {
                    if phase != .countdown && phase != .done && !hajimeTriggered {
                        topBar
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.sm)
                    }

                    Spacer()

                    phaseContent
                        .padding(.horizontal, AppSpacing.lg)

                    Spacer()

                    if let footer = phaseFooter, !showHajime, !hajimeTriggered {
                        Text(footer)
                            .font(.dojoCaption(isIPad ? 16 : 13))
                            .foregroundStyle(Color.dojoTextTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, isIPad ? 60 : AppSpacing.xl)
                            .padding(.bottom, AppSpacing.lg)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    // Skip button — upper right corner
                    if (phase == .breathing || phase == .focus || phase == .activate) && !showHajime && !hajimeTriggered {
                        skipButton
                            .padding(.trailing, AppSpacing.lg)
                            .padding(.top, 60)
                            .transition(.opacity)
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .task {
            startPhase(.intro)
        }
        .onDisappear {
            phaseTask?.cancel()
            AudioManager.shared.stop()
        }
    }

    // MARK: - Phase Accent Color

    private var phaseAccentColor: Color {
        switch phase {
        case .intro: return .emberGold
        case .countdown: return .emberGold
        case .breathing: return .calmTeal
        case .transition:
            if let pending = pendingTransitionPhase {
                return pending.color
            }
            return ritualPhaseOrder.indices.contains(currentRitualIndex)
                ? ritualPhaseOrder[currentRitualIndex].color : .focusIndigo
        case .focus: return .focusIndigo
        case .activate: return .crimsonPulse
        case .done: return .softGreen
        }
    }

    // MARK: - Phase Footer

    private var phaseFooter: String? {
        switch phase {
        case .breathing: return OfflineContent.breathingFooter
        case .focus: return OfflineContent.focusFooter
        case .activate:
            return OfflineContent.activationFooter
        default: return nil
        }
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button {
            HapticManager.light()
            skipCurrentPhase()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text("Skip")
                Image(systemName: "forward.fill")
            }
            .font(.dojoCaption(isIPad ? 16 : 13))
            .foregroundStyle(Color.dojoTextTertiary)
            .padding(.horizontal, isIPad ? AppSpacing.lg : AppSpacing.md)
            .padding(.vertical, isIPad ? AppSpacing.md : AppSpacing.sm)
            .background(Color.white.opacity(0.05), in: Capsule())
        }
        .accessibilityLabel("Skip this phase")
        .accessibilityHint("Advances to the next phase of the routine")
    }

    private func skipCurrentPhase() {
        phaseTask?.cancel()
        advanceFromCurrentRitual()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                HapticManager.light()
                phaseTask?.cancel()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(isIPad ? .title : .title2)
                    .foregroundStyle(Color.dojoTextTertiary)
                    .frame(width: isIPad ? 52 : 44, height: isIPad ? 52 : 44)
            }
            .accessibilityLabel("Close")
            .accessibilityHint("Ends the pre-fight routine")

            Spacer()

            phaseIndicators

            Spacer()

            Color.clear.frame(width: isIPad ? 52 : 44, height: isIPad ? 52 : 44)
        }
    }

    // MARK: - Phase Indicators

    private var phaseIndicators: some View {
        HStack(spacing: AppSpacing.sm) {
            let order = ritualPhaseOrder
            ForEach(Array(order.enumerated()), id: \.element.id) { index, ritualPhase in
                if index > 0 { dash }
                phaseIndicator(
                    ritualPhase.shortName,
                    icon: ritualPhase.icon,
                    active: currentRitualIndex == index && phase != .countdown && phase != .done,
                    completed: phase == .done || index < currentRitualIndex
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(phaseAccessibilityLabel)
    }

    private var dash: some View {
        Rectangle()
            .fill(Color.dojoMuted.opacity(0.3))
            .frame(width: isIPad ? 24 : 12, height: isIPad ? 2 : 1)
    }

    private func phaseIndicator(_ text: String, icon: String, active: Bool, completed: Bool) -> some View {
        HStack(spacing: isIPad ? AppSpacing.xs : AppSpacing.xxs) {
            Circle()
                .fill(active ? phaseAccentColor : (completed ? Color.softGreen : Color.dojoMuted.opacity(0.4)))
                .frame(width: isIPad ? 11 : 8, height: isIPad ? 11 : 8)
            Text(text)
                .font(.dojoCaption(isIPad ? 15 : 11))
                .foregroundStyle(active ? phaseAccentColor : (completed ? Color.softGreen : Color.dojoMuted))
        }
    }

    private var phaseAccessibilityLabel: String {
        let order = ritualPhaseOrder
        if phase == .done { return "Routine complete" }
        if phase == .countdown { return "Pre-fight routine" }
        guard currentRitualIndex < order.count else { return "Pre-fight routine" }
        return "Phase \(currentRitualIndex + 1) of \(order.count): \(order[currentRitualIndex].shortName)"
    }

    // MARK: - Phase Content Router

    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .intro:
            EmptyView()
        case .countdown:
            countdownView
        case .breathing:
            breathingView
        case .transition:
            if let pending = pendingTransitionPhase {
                transitionView(
                    icon: transitionIcon(for: pending),
                    title: transitionTitle(for: pending),
                    subtitle: transitionSubtitle(for: pending),
                    color: pending.color
                )
            }
        case .focus:
            focusView
        case .activate:
            activateView
        case .done:
            doneView
        }
    }

    private func transitionIcon(for ritualPhase: RitualPhase) -> String {
        switch ritualPhase {
        case .breathe: return "wind"
        case .focus: return "brain.head.profile"
        case .activate: return "flame.fill"
        }
    }

    private func transitionTitle(for ritualPhase: RitualPhase) -> String {
        switch ritualPhase {
        case .breathe: return "BREATHE"
        case .focus: return "FOCUS"
        case .activate: return "ACTIVATE"
        }
    }

    private func transitionSubtitle(for ritualPhase: RitualPhase) -> String {
        switch ritualPhase {
        case .breathe: return "Calm your mind"
        case .focus: return "Sharpen your mind"
        case .activate: return "Build your fire"
        }
    }

    // MARK: - Intro Animation View

    private var introView: some View {
        ZStack {
            // Expanding outer ring (bursts outward) — octagon to match start button
            OctagonShape()
                .stroke(
                    LinearGradient(
                        colors: [Color.emberGold.opacity(0.4), Color.emberLight.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isIPad ? 4 : 3
                )
                .frame(width: isIPad ? 420 : 280, height: isIPad ? 420 : 280)
                .scaleEffect(introRingScale)
                .opacity(introRingOpacity)

            // Spinning diamond accents (4 diamonds orbiting outward)
            ForEach(0..<4, id: \.self) { i in
                let angle = Double(i) * 90.0 + introDiamondRotation
                let radians = angle * .pi / 180
                let radius: CGFloat = (isIPad ? 130 : 85) * introDiamondScale
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.emberLight.opacity(0.6))
                    .frame(width: isIPad ? 18 : 14, height: isIPad ? 18 : 14)
                    .rotationEffect(.degrees(angle))
                    .offset(
                        x: cos(radians) * radius,
                        y: sin(radians) * radius
                    )
                    .opacity(introDiamondOpacity)
            }

            // Expanding gold octagon (main) — matches start button
            OctagonShape()
                .fill(
                    LinearGradient(
                        colors: [Color.emberGold, Color.emberGold.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isIPad ? 378 : 244, height: isIPad ? 378 : 244)
                .scaleEffect(introCircleScale)
                .opacity(introCircleOpacity)

            // Dark card that rotates in and expands — octagon shape
            OctagonShape()
                .fill(Color.dojoBlack)
                .frame(width: isIPad ? 500 : 340, height: isIPad ? 500 : 340)
                .scaleEffect(introCardScale)
                .rotationEffect(.degrees(introCardRotation))

            // Text content on the octagon (fades out as it expands) — matches start button
            VStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: isIPad ? 72 : 44, weight: .bold))
                    .foregroundStyle(Color.dojoBlack)

                Text("START")
                    .font(.system(size: isIPad ? 40 : 26, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dojoBlack)
                    .tracking(isIPad ? 10 : 5)

                Text("3 min")
                    .font(.dojoCaption(isIPad ? 20 : 14))
                    .foregroundStyle(Color.dojoBlack.opacity(0.7))
            }
            .opacity(introTextOpacity)

            // Countdown overlay (appears on dark card for seamless transition)
            VStack(spacing: AppSpacing.lg) {
                Text("\(countdownNumber)")
                    .font(.system(size: isIPad ? 160 : 120, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dojoTextPrimary)
                    .contentTransition(.numericText())

                countdownSubtitleView
            }
            .opacity(introCountdownOpacity)
        }
    }

    // MARK: - Countdown View

    private var countdownView: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("\(countdownNumber)")
                .font(.system(size: isIPad ? 160 : 120, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dojoTextPrimary)
                .contentTransition(.numericText())
                .accessibilityLabel("Countdown: \(countdownNumber)")

            countdownSubtitleView
        }
    }

    private var countdownSubtitleView: some View {
        let firstPhase = ritualPhaseOrder.first
        return VStack(spacing: AppSpacing.sm) {
            if let phase = firstPhase {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: phase.icon)
                        .font(.system(size: isIPad ? 22 : 16, weight: .semibold))
                        .foregroundStyle(phase.color)
                    Text("Prepare for \(phase.shortName)")
                        .font(.dojoBody(isIPad ? 22 : 18))
                        .foregroundStyle(Color.dojoTextSecondary)
                }
            } else {
                Text("Get ready")
                    .font(.dojoBody(isIPad ? 22 : 18))
                    .foregroundStyle(Color.dojoTextSecondary)
            }
        }
    }

    // MARK: - Breathing Views

    private var breathingView: some View {
        buddyBreathingView
    }

    private var buddyBoxSize: CGFloat { isIPad ? 380 : 220 }
    private var buddyBoxRadius: CGFloat { isIPad ? 48 : 32 }

    private let totalBreathCycles = 3

    private var buddyBreathingView: some View {
        VStack(spacing: 24) {
            // Cycle indicator
            HStack(spacing: isIPad ? 10 : 8) {
                ForEach(1...totalBreathCycles, id: \.self) { cycle in
                    Capsule()
                        .fill(cycle <= breathCycle ? Color.calmTeal : Color.calmTeal.opacity(0.15))
                        .frame(width: cycle == breathCycle ? (isIPad ? 32 : 24) : (isIPad ? 12 : 8), height: isIPad ? 6 : 4)
                        .animation(.spring(duration: 0.4), value: breathCycle)
                }

                Text("\(breathCycle) / \(totalBreathCycles)")
                    .font(.dojoMono(isIPad ? 15 : 12))
                    .foregroundStyle(Color.calmTeal.opacity(0.7))
                    .padding(.leading, isIPad ? 6 : 4)
            }
            .padding(.bottom, isIPad ? 4 : 2)

            // Box with character
            VStack(spacing: 20) {
                ZStack {
                    // Box background
                    RoundedRectangle(cornerRadius: buddyBoxRadius, style: .continuous)
                        .fill(Color.dojoBlack)
                        .frame(width: buddyBoxSize, height: buddyBoxSize)

                    // Box border
                    RoundedRectangle(cornerRadius: buddyBoxRadius, style: .continuous)
                        .stroke(Color.calmTeal.opacity(0.25), lineWidth: 3)
                        .frame(width: buddyBoxSize, height: buddyBoxSize)

                    // Completed cycle layers — each stays at the same color it was drawn in
                    if breathCycle > 1 {
                        BuddyBoxTracePath(cornerRadius: buddyBoxRadius)
                            .stroke(
                                Color.calmTeal.opacity(0.4),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: buddyBoxSize, height: buddyBoxSize)
                    }
                    if breathCycle > 2 {
                        BuddyBoxTracePath(cornerRadius: buddyBoxRadius)
                            .stroke(
                                Color.calmTeal.opacity(0.65),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: buddyBoxSize, height: buddyBoxSize)
                    }

                    // Current cycle progress trace
                    buddyProgressTrace
                        .frame(width: buddyBoxSize, height: buddyBoxSize)

                    // Character
                    buddyCharacter
                }

                // Ground shadow — scales dramatically with breath
                Ellipse()
                    .fill(Color.calmTeal.opacity(0.1 + circleScale * 0.15))
                    .frame(
                        width: (isIPad ? 70 : 40) + circleScale * (isIPad ? 260 : 150),
                        height: (isIPad ? 14 : 8) + circleScale * (isIPad ? 38 : 22)
                    )
                    .animation(.easeInOut(duration: 4), value: circleScale)
            }

            // Phase text — premium fade + scale transition
            Text(buddyPhaseText)
                .font(.system(size: isIPad ? 40 : 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dojoTextPrimary)
                .id(buddyPhaseText)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .offset(y: 12)),
                    removal: .opacity.combined(with: .scale(scale: 1.1)).combined(with: .offset(y: -8))
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: buddyPhaseText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(breathPhase.displayText), \(breathSecondsLeft) seconds. Cycle \(breathCycle) of 3")
    }

    private var buddyPhaseText: String {
        switch breathPhase {
        case .inhale: return "Breathe in"
        case .holdIn: return "Hold"
        case .exhale: return "Breathe out"
        case .holdOut: return "Hold"
        }
    }

    // Custom shape that traces a rounded rect starting from the top-left corner
    struct BuddyBoxTracePath: Shape {
        let cornerRadius: CGFloat
        func path(in rect: CGRect) -> Path {
            let r = cornerRadius
            let w = rect.width
            let h = rect.height
            var p = Path()
            p.move(to: CGPoint(x: r, y: 0))
            // Top edge →
            p.addLine(to: CGPoint(x: w - r, y: 0))
            // Top-right arc
            p.addArc(center: CGPoint(x: w - r, y: r), radius: r,
                      startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            // Right edge ↓
            p.addLine(to: CGPoint(x: w, y: h - r))
            // Bottom-right arc
            p.addArc(center: CGPoint(x: w - r, y: h - r), radius: r,
                      startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            // Bottom edge ←
            p.addLine(to: CGPoint(x: r, y: h))
            // Bottom-left arc
            p.addArc(center: CGPoint(x: r, y: h - r), radius: r,
                      startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            // Left edge ↑
            p.addLine(to: CGPoint(x: 0, y: r))
            // Top-left arc
            p.addArc(center: CGPoint(x: r, y: r), radius: r,
                      startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            return p
        }
    }

    private var buddyProgressTrace: some View {
        let totalProgress = buddyTraceProgress
        let cycleColor: Color = switch breathCycle {
        case 1: Color.calmTeal.opacity(0.4)
        case 2: Color.calmTeal.opacity(0.65)
        default: Color.white.opacity(0.9)
        }
        return BuddyBoxTracePath(cornerRadius: buddyBoxRadius)
            .trim(from: 0, to: totalProgress)
            .stroke(
                cycleColor,
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
    }

    private var buddyTraceProgress: CGFloat {
        let completedPortion = CGFloat(boxCompletedSides) * 0.25
        let currentPortion = boxSideProgress * 0.25
        return completedPortion + currentPortion
    }

    private var buddyCharacter: some View {
        // circleScale: 0.6 (exhale) → 1.0 (inhale)
        // Dramatic range: 0.7 (small) → 1.4 (nearly fills box)
        let scale = circleScale * 1.75 - 0.35
        let charSize: CGFloat = isIPad ? 240 : 140
        let faceColor = Color.dojoBlack
        // Face shifts significantly up when inhaled (eyes near top of ball)
        let faceYShift: CGFloat = -(circleScale - 0.6) * (isIPad ? 240 : 140)
        let eyeW: CGFloat = isIPad ? 28 : 18
        let eyeH: CGFloat = isIPad ? 16 : 10
        let eyeOffX: CGFloat = isIPad ? 28 : 18
        let eyeOffY: CGFloat = isIPad ? -18 : -12

        return ZStack {
            // Body (ember gold — matches start button)
            Circle()
                .fill(Color.emberGold)
                .frame(width: charSize, height: charSize)
                .scaleEffect(scale)

            // Face group — shifts up when inflated
            Group {
                // Left eye (closed arc)
                BuddyEyePath()
                    .stroke(faceColor, style: StrokeStyle(lineWidth: isIPad ? 5 : 3, lineCap: .round))
                    .frame(width: eyeW, height: eyeH)
                    .offset(x: -eyeOffX, y: eyeOffY)

                // Right eye (closed arc)
                BuddyEyePath()
                    .stroke(faceColor, style: StrokeStyle(lineWidth: isIPad ? 5 : 3, lineCap: .round))
                    .frame(width: eyeW, height: eyeH)
                    .offset(x: eyeOffX, y: eyeOffY)

                // Smile
                BuddySmilePath()
                    .stroke(faceColor, style: StrokeStyle(lineWidth: isIPad ? 4 : 2.5, lineCap: .round))
                    .frame(width: isIPad ? 36 : 22, height: isIPad ? 16 : 10)
                    .offset(y: isIPad ? 14 : 8)
            }
            .scaleEffect(scale * 0.7)
            .offset(y: faceYShift)
        }
        .animation(.easeInOut(duration: 4), value: circleScale)
    }

    // MARK: - Buddy Face Shapes

    struct BuddyEyePath: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: 0, y: rect.maxY))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: rect.midX, y: 0)
            )
            return p
        }
    }

    struct BuddySmilePath: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: 0, y: 0))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: 0),
                control: CGPoint(x: rect.midX, y: rect.maxY)
            )
            return p
        }
    }

    // MARK: - Transition View

    private func transitionView(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: isIPad ? AppSpacing.xl : AppSpacing.lg) {
            ZStack {
                // Expanding ring pulse
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: isIPad ? 3 : 2)
                    .frame(width: isIPad ? 170 : 120, height: isIPad ? 170 : 120)
                    .scaleEffect(transRingScale)
                    .opacity(transRingOpacity)

                // Icon background
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: isIPad ? 140 : 100, height: isIPad ? 140 : 100)
                    .scaleEffect(transIconScale)
                    .opacity(transIconOpacity)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 56 : 40, weight: .semibold))
                    .foregroundStyle(color)
                    .scaleEffect(transIconScale)
                    .opacity(transIconOpacity)
            }
            .appGlow(color, radius: isIPad ? 22 : 15)

            Text(title)
                .font(.dojoTitle(isIPad ? 40 : 28))
                .foregroundStyle(Color.dojoTextPrimary)
                .tracking(isIPad ? 6 : 4)
                .opacity(transTitleOpacity)
                .offset(y: transTitleOffset)

            Text(subtitle)
                .font(.dojoBody(isIPad ? 20 : 16))
                .foregroundStyle(Color.dojoTextSecondary)
                .opacity(transSubtitleOpacity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    // MARK: - Focus View

    private var focusView: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Spacer()
                Text("\(focusTimeRemaining)s")
                    .font(.dojoMono(isIPad ? 20 : 16))
                    .foregroundStyle(focusTimeRemaining <= 10 ? Color.crimsonPulse : Color.dojoTextSecondary)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(focusTimeRemaining) seconds remaining")
            }

            switch PreFightGame(rawValue: selectedGameRaw) ?? .reactionTap {
            case .reactionTap:
                InlineReactionTapGame()
            case .numberOrder:
                InlineNumberOrderGame()
            case .patternRecall:
                InlinePatternRecallGame()
            }
        }
        .frame(maxWidth: isIPad ? 600 : .infinity)
    }

    // MARK: - Activate View (Interactive Press-and-Hold)

    private var waveCircleSize: CGFloat { isIPad ? 320 : 220 }

    private var activateView: some View {
        let stages = OfflineContent.intensityRampStages
        let currentStage = rampStep < stages.count ? stages[rampStep] : stages.last!
        let intensity = rampIntensity
        let stageColor = rampColor

        return ZStack {
            // Hajime explosion overlay — mirrors intro animation in crimson
            if hajimeTriggered {
                // Expanding outer ring (bursts outward)
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: isIPad ? 4 : 3)
                    .frame(width: isIPad ? 260 : 180, height: isIPad ? 260 : 180)
                    .scaleEffect(hajimeRingScale)
                    .opacity(hajimeRingOpacity)

                // Spinning diamond accents
                ForEach(0..<4, id: \.self) { i in
                    let angle = Double(i) * 90.0 + hajimeDiamondRotation
                    let radians = angle * .pi / 180
                    let radius: CGFloat = (isIPad ? 90 : 60) * hajimeDiamondScale
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: isIPad ? 18 : 14, height: isIPad ? 18 : 14)
                        .rotationEffect(.degrees(angle))
                        .offset(
                            x: cos(radians) * radius,
                            y: sin(radians) * radius
                        )
                        .opacity(hajimeDiamondOpacity)
                }

                // Expanding crimson circle (fills screen)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, .crimsonPulse],
                            center: .center,
                            startRadius: isIPad ? 15 : 10,
                            endRadius: isIPad ? 180 : 120
                        )
                    )
                    .frame(width: isIPad ? 240 : 160, height: isIPad ? 240 : 160)
                    .scaleEffect(hajimeCircleScale)

                // Crimson card rotates in (like intro dark card)
                RoundedRectangle(cornerRadius: isIPad ? 56 : 40, style: .continuous)
                    .fill(Color.crimsonPulse)
                    .frame(width: isIPad ? 400 : 280, height: isIPad ? 400 : 280)
                    .scaleEffect(hajimeCardScale)
                    .rotationEffect(.degrees(hajimeCardRotation))

                // "Are You Ready?" content — bold, centered, martial
                VStack(spacing: 0) {
                    // Decorative top accent
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: isIPad ? 64 : 48, height: 2)
                        .padding(.bottom, AppSpacing.xl)

                    Text("HAJIME")
                        .font(.system(size: isIPad ? 72 : 52, weight: .black, design: .serif))
                        .foregroundStyle(.white)
                        .tracking(isIPad ? 14 : 10)

                    // Thin separator
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: isIPad ? 140 : 100, height: 1)
                        .padding(.vertical, AppSpacing.md)

                    Text("Are You Ready?")
                        .font(.system(size: isIPad ? 28 : 22, weight: .medium, design: .serif))
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(isIPad ? 5 : 3)

                    // "I'm Ready" dismiss button — appears after 3 seconds
                    Button {
                        HapticManager.heavy()
                        recordCompletion()
                        dismiss()
                    } label: {
                        Text("I'm Ready")
                            .font(.system(size: isIPad ? 22 : 18, weight: .bold, design: .serif))
                            .foregroundStyle(Color.crimsonPulse)
                            .tracking(isIPad ? 3 : 2)
                            .padding(.horizontal, isIPad ? 48 : AppSpacing.xxl)
                            .padding(.vertical, isIPad ? AppSpacing.lg : AppSpacing.md)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                    .opacity(hajimeButtonOpacity)
                    .padding(.top, isIPad ? 80 : AppSpacing.xxl)
                    .accessibilityLabel("I'm Ready")
                    .accessibilityHint("Closes the pre-fight routine")
                }
                .opacity(hajimeTextOpacity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Hajime. Are You Ready?")
            }

            if !hajimeTriggered {
                VStack(alignment: .center, spacing: 0) {
                    // Step indicators
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(0..<stages.count, id: \.self) { i in
                            Capsule()
                                .fill(i < rampStep ? rampStageColor(stages[i]) : (i == rampStep ? stageColor : Color.dojoMuted.opacity(0.3)))
                                .frame(width: i == rampStep ? (isIPad ? 36 : 24) : (isIPad ? 18 : 12), height: isIPad ? 6 : 4)
                                .animation(.spring(duration: 0.3), value: rampStep)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Stage \(rampStep + 1) of \(stages.count)")
                    .padding(.bottom, AppSpacing.md)

                    if showHajime {
                        Spacer()

                        // Hajime trigger — the circle is now fully filled
                        Button {
                            triggerHajime()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.crimsonPulse, .crimsonPulse.opacity(0.8)],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: waveCircleSize / 2
                                        )
                                    )
                                    .frame(width: waveCircleSize, height: waveCircleSize)
                                    .appGlow(.crimsonPulse, radius: 30)
                                    .scaleEffect(isHolding ? 1.0 : 1.05)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isHolding)

                                Text("HAJIME")
                                    .font(.system(size: isIPad ? 32 : 24, weight: .black, design: .serif))
                                    .foregroundStyle(.white)
                                    .tracking(isIPad ? 6 : 4)
                            }
                        }
                        .accessibilityLabel("Trigger Hajime")
                        .accessibilityHint("Press to activate your fight-ready state")
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                        .onAppear { isHolding.toggle() }

                        Spacer()
                    } else {
                        Spacer()

                        // Visualization text — fixed height so circle never shifts
                        Text(currentStage.text)
                            .font(.dojoBody((isIPad ? 26 : 22) + intensity * (isIPad ? 8 : 6)))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(isIPad ? 12 : 9)
                            .shadow(color: stageColor.opacity(intensity * 0.5), radius: intensity * 10)
                            .opacity(rampTextOpacity)
                            .padding(.horizontal, isIPad ? AppSpacing.xxl : AppSpacing.lg)
                            .frame(height: isIPad ? 200 : 150, alignment: .center)
                            .accessibilityLabel(currentStage.text)

                        Spacer().frame(height: isIPad ? 48 : 32)

                        // Progress circle with flame
                        ZStack {
                            // Background ring
                            Circle()
                                .stroke(stageColor.opacity(0.15), lineWidth: 6)
                                .frame(width: waveCircleSize, height: waveCircleSize)

                            // Progress ring
                            Circle()
                                .trim(from: 0, to: rampProgress)
                                .stroke(
                                    stageColor.opacity(0.5 + intensity * 0.5),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: waveCircleSize, height: waveCircleSize)
                                .rotationEffect(.degrees(-90))

                            // Inner glow fill
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            stageColor.opacity(0.15 * intensity),
                                            stageColor.opacity(0.02)
                                        ],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: waveCircleSize / 2
                                    )
                                )
                                .frame(width: waveCircleSize - 12, height: waveCircleSize - 12)

                            // Flame icon
                            Image(systemName: "flame.fill")
                                .font(.system(size: (isIPad ? 44 : 30) + intensity * (isIPad ? 44 : 30), weight: .semibold))
                                .foregroundStyle(stageColor)
                                .shadow(color: stageColor.opacity(intensity * 0.6), radius: intensity * 20)
                        }
                        .animation(.easeInOut(duration: 0.8), value: intensity)
                        .appGlow(stageColor, radius: intensity * 15)

                        // Hold instruction
                        Text(isHolding ? "Keep holding..." : "PRESS & HOLD")
                            .font(.dojoCaption(isIPad ? 17 : 13))
                            .foregroundStyle(isHolding ? stageColor : Color.dojoTextTertiary)
                            .tracking(2)
                            .animation(.easeInOut(duration: 0.2), value: isHolding)
                            .padding(.top, AppSpacing.sm)
                            .padding(.bottom, AppSpacing.sm)

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity)
            }

            // Full-screen touch target for hold gesture
            if !showHajime && !hajimeTriggered {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isHolding { isHolding = true }
                            }
                            .onEnded { _ in
                                isHolding = false
                            }
                    )
                    .ignoresSafeArea()
            }
        }
        .animation(.spring(duration: 0.5), value: showHajime)
    }

    private func triggerHajime() {
        // Triple-burst heavy haptic + deep audio impact
        HapticManager.heavy()
        AudioManager.shared.hajimeImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { HapticManager.rigid() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { HapticManager.heavy() }

        // Reset explosion state
        hajimeCircleScale = 0.3
        hajimeRingScale = 1.0
        hajimeRingOpacity = 0
        hajimeDiamondRotation = 0
        hajimeDiamondScale = 0.3
        hajimeDiamondOpacity = 0
        hajimeCardScale = 0.0
        hajimeCardRotation = 45
        hajimeTextOpacity = 0

        hajimeTriggered = true

        phaseTask?.cancel()
        phaseTask = Task {
            // Phase 1: Ring bursts out + diamonds appear + circle expands
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.5)) {
                    hajimeRingScale = 3.5
                    hajimeRingOpacity = 0.6
                }
                withAnimation(.easeInOut(duration: 0.35)) {
                    hajimeDiamondOpacity = 0.8
                    hajimeDiamondScale = 2.0
                    hajimeDiamondRotation = 120
                }
                withAnimation(.easeInOut(duration: 0.6)) {
                    hajimeCircleScale = 6.0
                }
            }

            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }

            // Phase 2: Ring + diamonds fade as circle fills screen
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    hajimeRingOpacity = 0
                    hajimeDiamondOpacity = 0
                }
            }

            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            // Phase 3: Crimson card rotates in (mirrors intro dark card)
            HapticManager.medium()
            await MainActor.run {
                hajimeCardScale = 0.05
                hajimeCardRotation = 45
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    hajimeCardScale = 4.0
                    hajimeCardRotation = 0
                }
            }

            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            // Phase 4: Text fades in on crimson background
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    hajimeTextOpacity = 1.0
                }
            }

            // Show "I'm Ready" button after 3 seconds
            try? await Task.sleep(for: .seconds(3.0))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    hajimeButtonOpacity = 1.0
                }
            }
        }
    }

    private func rampStageColor(_ stage: OfflineContent.IntensityRampStage) -> Color {
        switch stage.colorName {
        case "calmTeal": return .calmTeal
        case "focusIndigo": return .focusIndigo
        case "emberGold": return .emberGold
        case "crimsonPulse": return .crimsonPulse
        default: return .crimsonPulse
        }
    }


    // MARK: - Done View

    private var doneView: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                // Triple rings
                Circle()
                    .stroke(
                        LinearGradient(colors: [.softGreen, .calmTeal], startPoint: .top, endPoint: .bottom),
                        lineWidth: isIPad ? 3 : 2
                    )
                    .frame(width: isIPad ? 260 : 180, height: isIPad ? 260 : 180)

                Circle()
                    .stroke(Color.softGreen.opacity(0.3), lineWidth: isIPad ? 2 : 1.5)
                    .frame(width: isIPad ? 220 : 150, height: isIPad ? 220 : 150)

                Circle()
                    .stroke(Color.softGreen.opacity(0.15), lineWidth: isIPad ? 1.5 : 1)
                    .frame(width: isIPad ? 200 : 140, height: isIPad ? 200 : 140)

                Image(systemName: "checkmark")
                    .font(.system(size: isIPad ? 90 : 64, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.softGreen, .calmTeal], startPoint: .top, endPoint: .bottom)
                    )
            }
            .appGlow(.softGreen, radius: isIPad ? 45 : 30)
            .scaleEffect(doneScale)

            Text("You're Ready")
                .font(.dojoTitle(isIPad ? 44 : 32))
                .foregroundStyle(Color.dojoTextPrimary)

            Text("Mind clear. Body sharp. Go fight.")
                .font(.dojoBody(isIPad ? 20 : 16))
                .foregroundStyle(Color.dojoTextSecondary)

            Button {
                HapticManager.medium()
                recordCompletion()
                dismiss()
            } label: {
                Text("Let's Go")
                    .font(.dojoHeading(isIPad ? 22 : 18))
                    .foregroundStyle(Color.dojoBlack)
                    .frame(maxWidth: isIPad ? 400 : .infinity)
                    .padding(.vertical, isIPad ? AppSpacing.lg : AppSpacing.md)
                    .background(
                        LinearGradient(
                            colors: [.softGreen, .calmTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                    )
            }
            .padding(.horizontal, AppSpacing.xl)
            .accessibilityLabel("Let's go")
            .accessibilityHint("Closes the pre-fight routine")
        }
    }

    // MARK: - Phase Engine

    private func startPhase(_ newPhase: FlowPhase) {
        phaseTask?.cancel()

        let isEnteringTransition = (newPhase == .transition)
        let isLeavingTransition = (phase == .transition)
        let duration: Double = isEnteringTransition ? 0.15 : isLeavingTransition ? 0.5 : 0.4
        let animation: Animation = isLeavingTransition
            ? .spring(response: 0.5, dampingFraction: 0.85)
            : .easeInOut(duration: duration)
        withAnimation(animation) {
            phase = newPhase
        }

        phaseTask = Task {
            switch newPhase {
            case .intro:
                await runIntro()
            case .countdown:
                await runCountdown()
            case .breathing:
                await runBreathing()
            case .transition:
                await runTransition()
            case .focus:
                await runFocus()
            case .activate:
                await runActivate()
            case .done:
                await runDone()
            }
        }
    }

    // MARK: - Dynamic Phase Navigation

    private func startRitualPhase(_ ritualPhase: RitualPhase) {
        switch ritualPhase {
        case .breathe:
            startPhase(.breathing)
        case .focus:
            startPhase(.focus)
        case .activate:
            startPhase(.activate)
        }
    }

    private func advanceFromCurrentRitual() {
        let order = ritualPhaseOrder
        let nextIndex = currentRitualIndex + 1

        if nextIndex >= order.count {
            startPhase(.done)
        } else {
            currentRitualIndex = nextIndex
            let nextRitualPhase = order[nextIndex]
            pendingTransitionPhase = nextRitualPhase
            startPhase(.transition)
        }
    }

    // MARK: - Intro Animation

    private func runIntro() async {
        // Brief pause before animation starts
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }
        HapticManager.heavy()

        // Phase 1: Ring bursts out + diamonds appear + text fades + circle expands
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.25)) {
                introTextOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.5)) {
                introRingScale = 3.5
                introRingOpacity = 0.6
            }
            withAnimation(.easeInOut(duration: 0.35)) {
                introDiamondOpacity = 0.8
                introDiamondScale = 2.0
                introDiamondRotation = 120
            }
            withAnimation(.easeInOut(duration: 0.6)) {
                introCircleScale = 6.0
            }
        }

        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }

        // Phase 2: Ring + diamonds fade as circle fills screen
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.3)) {
                introRingOpacity = 0
                introDiamondOpacity = 0
            }
        }

        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }

        // Phase 3: Dark card rotates in
        HapticManager.medium()
        await MainActor.run {
            introCardScale = 0.05
            introCardRotation = 45
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                introCardScale = 4.0
                introCardRotation = 0
            }
        }

        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }

        // Phase 4: Fade gold out + fade countdown in (seamless)
        await MainActor.run {
            withAnimation(.easeIn(duration: 0.25)) {
                introCircleOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.3)) {
                introCountdownOpacity = 1.0
            }
        }

        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // Switch phase instantly — countdown is already visible on intro overlay
        phase = .countdown
        // Start countdown ticks
        phaseTask?.cancel()
        phaseTask = Task { await runCountdown() }
    }

    // MARK: - Countdown

    private func runCountdown() async {
        HapticManager.medium()
        for i in stride(from: 3, through: 1, by: -1) {
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.3)) {
                countdownNumber = i
            }
            HapticManager.light()
            AudioManager.shared.countdownTick()
            // "3" is already visible from intro transition, so show it shorter
            let delay: Double = (i == 3) ? 0.45 : 1.0
            try? await Task.sleep(for: .seconds(delay))
        }
        guard !Task.isCancelled else { return }
        currentRitualIndex = 0
        let firstPhase = ritualPhaseOrder[0]
        startRitualPhase(firstPhase)
    }

    // MARK: - Breathing (3 cycles × 4 phases × 4 seconds = 48s)

    private func runBreathing() async {
        let phases: [BreathPhase] = [.inhale, .holdIn, .exhale, .holdOut]
        let phaseDuration = 4
        let totalCycles = 3
        let tickInterval: Double = 0.05 // smooth 20fps animation
        let ticksPerSecond = Int(1.0 / tickInterval)
        let ticksPerPhase = phaseDuration * ticksPerSecond
        let coachingTexts = OfflineContent.breathingCoachingTexts

        for cycle in 1...totalCycles {
            guard !Task.isCancelled else { return }

            // Clean state for new cycle + rotate coaching text
            if cycle > 1 { HapticManager.rigid() }
            await MainActor.run {
                // Snap everything atomically — breathCycle must change in the same
                // frame as the trace reset so the completed layer appears instantly
                let noAnim = Transaction(animation: nil)
                withTransaction(noAnim) {
                    boxCompletedSides = 0
                    boxSideProgress = 0
                    breathCycle = cycle
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    breathCoachingText = coachingTexts[(cycle - 1) % coachingTexts.count]
                }
            }

            for (sideIndex, bp) in phases.enumerated() {
                guard !Task.isCancelled else { return }

                // Set breath phase and countdown + buddy scale
                let targetScale: CGFloat = (bp == .inhale || bp == .holdIn) ? 1.0 : 0.6
                await MainActor.run {
                    breathPhase = bp
                    breathSecondsLeft = phaseDuration
                    boxSideProgress = 0
                    HapticManager.light()
                    // Audio cue for inhale/exhale
                    if bp == .inhale { AudioManager.shared.breatheIn() }
                    else if bp == .exhale { AudioManager.shared.breatheOut() }
                    withAnimation(.easeInOut(duration: Double(phaseDuration))) {
                        circleScale = targetScale
                    }
                }

                // Animate orb along this side, tick by tick (ease-in-out F-curve)
                for tick in 1...ticksPerPhase {
                    guard !Task.isCancelled else { return }
                    try? await Task.sleep(for: .seconds(tickInterval))

                    let t = CGFloat(tick) / CGFloat(ticksPerPhase)
                    // Cubic ease-in-out: smooth ramp up then ramp down
                    let progress = t < 0.5
                        ? 4 * t * t * t
                        : 1 - pow(-2 * t + 2, 3) / 2
                    let newSeconds = phaseDuration - (tick / ticksPerSecond)

                    await MainActor.run {
                        withAnimation(.linear(duration: tickInterval)) {
                            boxSideProgress = progress
                        }
                        let displaySeconds = max(newSeconds, 0)
                        if displaySeconds != breathSecondsLeft {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                breathSecondsLeft = displaySeconds
                            }
                        }

                    }
                }

                // Mark side complete
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        boxCompletedSides = sideIndex + 1
                        boxSideProgress = 0
                    }
                }
            }
        }

        guard !Task.isCancelled else { return }
        advanceFromCurrentRitual()
    }

    // MARK: - Transition

    private func runTransition() async {
        // Reset transition animation state
        transIconScale = 0.3
        transIconOpacity = 0
        transRingScale = 0.8
        transRingOpacity = 0
        transTitleOpacity = 0
        transTitleOffset = 20
        transSubtitleOpacity = 0

        try? await Task.sleep(for: .milliseconds(100))
        guard !Task.isCancelled else { return }

        // Step 1: Icon scales in with spring + ring pulses outward
        HapticManager.medium()
        AudioManager.shared.transitionChime()
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                transIconScale = 1.0
                transIconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6)) {
                transRingScale = 1.8
                transRingOpacity = 0.5
            }
        }

        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }

        // Step 2: Ring fades + title slides up
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.4)) {
                transRingOpacity = 0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                transTitleOpacity = 1.0
                transTitleOffset = 0
            }
        }

        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }

        // Step 3: Subtitle fades in
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.3)) {
                transSubtitleOpacity = 1.0
            }
        }

        // Hold for a moment
        try? await Task.sleep(for: .seconds(1.2))
        guard !Task.isCancelled else { return }

        // Step 4: Fade everything out before switching
        await MainActor.run {
            withAnimation(.easeIn(duration: 0.35)) {
                transIconScale = 0.85
                transIconOpacity = 0
                transTitleOpacity = 0
                transTitleOffset = -12
                transSubtitleOpacity = 0
            }
        }

        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        guard let pending = pendingTransitionPhase else { return }
        startRitualPhase(pending)
    }

    // MARK: - Focus (55s, F1 Reaction Tap only)

    private func runFocus() async {
        focusTimeRemaining = 40

        while focusTimeRemaining > 0 {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    focusTimeRemaining -= 1
                }
            }
        }
        guard !Task.isCancelled else { return }
        advanceFromCurrentRitual()
    }

    // MARK: - Activate (Interactive Press-and-Hold)

    private func runActivate() async {
        let stages = OfflineContent.intensityRampStages
        let tickInterval: Double = 0.05
        var overallElapsed: Double = 0
        let totalHoldTime = stages.reduce(0.0) { $0 + $1.duration }

        // Reset activate state
        await MainActor.run {
            isHolding = false
            holdProgress = 0
            showHajime = false
            hajimeTriggered = false
            rampStep = 0
            rampProgress = 0
            rampIntensity = 0
            rampTextOpacity = 1
            rampColor = rampStageColor(stages[0])
        }

        for (index, stage) in stages.enumerated() {
            guard !Task.isCancelled else { return }

            // Setup stage
            await MainActor.run {
                rampStep = index
                holdProgress = 0
                HapticManager.forIntensity(stage.intensity)
                withAnimation(.easeIn(duration: 0.5)) {
                    rampTextOpacity = 1
                }
                withAnimation(.easeInOut(duration: 1.5)) {
                    rampIntensity = stage.intensity
                    rampColor = rampStageColor(stage)
                }
            }

            // Wait for user to hold through this stage
            let totalTicks = Int(stage.duration / tickInterval)
            var currentTick = 0

            // Haptic rhythm: faster as intensity increases
            let hapticInterval = max(5, Int(18.0 * (1.0 - stage.intensity)))

            while currentTick < totalTicks {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(tickInterval))

                if isHolding {
                    currentTick += 1
                    overallElapsed += tickInterval
                    let stageProgress = CGFloat(currentTick) / CGFloat(totalTicks)

                    await MainActor.run {
                        holdProgress = stageProgress
                        rampProgress = CGFloat(overallElapsed / totalHoldTime)
                    }

                    // Escalating haptic pulse
                    if stage.intensity > 0.7 {
                        // Heartbeat double-tap at high intensity
                        if currentTick % hapticInterval == 0 {
                            HapticManager.holdPulse(stage.intensity)
                        } else if currentTick % hapticInterval == 2 {
                            HapticManager.holdPulse(stage.intensity * 0.6)
                        }
                    } else {
                        // Single pulse at lower intensity
                        if currentTick % hapticInterval == 0 {
                            HapticManager.holdPulse(stage.intensity)
                        }
                    }
                }
            }

            // Stage complete — satisfying burst
            HapticManager.rigid()

            // Fade out text before next stage (except last)
            if index < stages.count - 1 {
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.3)) {
                        rampTextOpacity = 0
                    }
                }
                try? await Task.sleep(for: .milliseconds(300))
            }
        }

        guard !Task.isCancelled else { return }

        // All stages complete — show Hajime button
        await MainActor.run {
            withAnimation(.spring(duration: 0.5)) {
                showHajime = true
            }
        }
        // Wait here — triggerHajime() handles the rest via button tap
    }

    // MARK: - Done

    private func runDone() async {
        HapticManager.success()
        AudioManager.shared.successChime()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            doneScale = 1.0
        }
    }

    // MARK: - Record Completion

    private func recordCompletion() {
        let log = ActivityLog(
            routineType: .preFight,
            durationMinutes: 3,
            notes: "Pre-Fight Flow",
            date: Date()
        )
        modelContext.insert(log)

        if let streak = streakData.first {
            streak.recordActivity(minutes: 3)
        } else {
            let newStreak = StreakData()
            newStreak.recordActivity(minutes: 3)
            modelContext.insert(newStreak)
        }
    }
}
