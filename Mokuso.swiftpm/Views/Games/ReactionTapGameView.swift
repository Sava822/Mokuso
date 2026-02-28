import SwiftUI

// MARK: - F1 Reaction Round State

enum ReactionRoundState: Equatable {
    case ready
    case lightsSequence
    case holding
    case go
    case tapped(ms: Int)
    case jumpStart
}

// MARK: - F1 Lights Panel

struct F1LightsPanel: View {
    let litCount: Int
    let isGo: Bool
    let isJumpStart: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        HStack(spacing: isIPad ? 20 : 10) {
            ForEach(0..<5, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: isIPad ? 16 : 8, style: .continuous)
                        .fill(Color(white: 0.1))
                        .frame(width: isIPad ? 100 : 48, height: isIPad ? 120 : 58)
                    Circle()
                        .fill(lightColor(for: index))
                        .frame(width: isIPad ? 70 : 34, height: isIPad ? 70 : 34)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                }
                .shadow(
                    color: lightGlow(for: index),
                    radius: isLit(index) ? 12 : 0
                )
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                .fill(Color(white: 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .accessibilityHidden(true)
    }

    private func isLit(_ index: Int) -> Bool {
        !isGo && !isJumpStart && index < litCount
    }

    private func lightColor(for index: Int) -> Color {
        if isGo { return Color(white: 0.18) }
        if isJumpStart { return Color.emberGold.opacity(0.25) }
        return index < litCount ? Color.crimsonPulse : Color(white: 0.18)
    }

    private func lightGlow(for index: Int) -> Color {
        if isGo || isJumpStart { return .clear }
        return index < litCount ? Color.crimsonPulse.opacity(0.7) : .clear
    }
}

// MARK: - Reaction Helpers

private func reactionColor(_ ms: Int) -> Color {
    if ms < 200 { return .softGreen }
    if ms < 300 { return .calmTeal }
    if ms < 500 { return .emberGold }
    return .crimsonPulse
}

private func reactionLabel(_ ms: Int) -> String {
    if ms < 150 { return "Incredible!" }
    if ms < 200 { return "Lightning Fast" }
    if ms < 250 { return "Great Reflexes" }
    if ms < 350 { return "Good Reaction" }
    if ms < 500 { return "Average" }
    return "Keep Practicing"
}

// MARK: - Inline F1 Reaction Game (for PreFight Flow)

struct InlineReactionTapGame: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }
    @State private var roundState: ReactionRoundState = .ready
    @State private var litCount = 0
    @State private var goTime: Date?
    @State private var bestReaction: Int?
    @State private var roundCount = 0
    @State private var roundTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            F1LightsPanel(
                litCount: litCount,
                isGo: roundState == .go,
                isJumpStart: roundState == .jumpStart
            )

            Button { handleTap() } label: {
                inlineTapZone
            }
            .buttonStyle(.plain)
            .accessibilityLabel(inlineTapLabel)
            .accessibilityHint("Tap when all lights go out")

            HStack {
                if let best = bestReaction {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: isIPad ? 15 : 11))
                            .foregroundStyle(Color.emberGold)
                        Text("\(best) ms")
                            .font(.dojoMono(isIPad ? 16 : 13))
                            .foregroundStyle(Color.dojoTextSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Best: \(best) milliseconds")
                }
                Spacer()
                if roundCount > 0 {
                    Text("Round \(roundCount)")
                        .font(.dojoCaption(isIPad ? 15 : 12))
                        .foregroundStyle(Color.dojoMuted)
                }
            }
            .padding(.horizontal, AppSpacing.xs)
        }
        .task { bestReaction = loadInlineBest() }
        .onDisappear { roundTask?.cancel() }
    }

    // MARK: - Tap Zone

    private var inlineTapZone: some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
            .fill(inlineTapColor)
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 320 : 200)
            .overlay(inlineTapContent)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var inlineTapContent: some View {
        switch roundState {
        case .ready:
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: isIPad ? 48 : 32))
                    .foregroundStyle(Color.focusIndigo)
                Text("Tap to Start")
                    .font(.dojoBody(isIPad ? 22 : 16))
                    .foregroundStyle(Color.dojoTextSecondary)
            }
        case .lightsSequence, .holding:
            VStack(spacing: AppSpacing.sm) {
                Text("Wait...")
                    .font(.dojoHeading(isIPad ? 34 : 24))
                    .foregroundStyle(Color.crimsonPulse)
                Text("React when lights go out")
                    .font(.dojoCaption(isIPad ? 17 : 13))
                    .foregroundStyle(Color.dojoTextTertiary)
            }
        case .go:
            VStack(spacing: AppSpacing.sm) {
                Text("GO!")
                    .font(.system(size: isIPad ? 80 : 56, weight: .black, design: .rounded))
                    .foregroundStyle(Color.softGreen)
                Text("TAP NOW!")
                    .font(.dojoHeading(isIPad ? 24 : 18))
                    .foregroundStyle(Color.softGreen.opacity(0.8))
            }
        case .tapped(let ms):
            VStack(spacing: AppSpacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(ms)")
                        .font(.system(size: isIPad ? 80 : 56, weight: .black, design: .rounded))
                        .foregroundStyle(reactionColor(ms))
                    Text("ms")
                        .font(.dojoHeading(isIPad ? 30 : 22))
                        .foregroundStyle(reactionColor(ms).opacity(0.7))
                }
                Text(reactionLabel(ms))
                    .font(.dojoCaption(isIPad ? 18 : 14))
                    .foregroundStyle(Color.dojoTextSecondary)
                Text("Tap for next round")
                    .font(.dojoCaption(isIPad ? 15 : 12))
                    .foregroundStyle(Color.dojoMuted)
                    .padding(.top, AppSpacing.xxs)
            }
        case .jumpStart:
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: isIPad ? 48 : 32))
                    .foregroundStyle(Color.emberGold)
                Text("Jump Start!")
                    .font(.dojoHeading(isIPad ? 30 : 22))
                    .foregroundStyle(Color.emberGold)
                Text("Tapped too early — try again")
                    .font(.dojoCaption(isIPad ? 17 : 13))
                    .foregroundStyle(Color.dojoTextTertiary)
            }
        }
    }

    private var inlineTapColor: Color {
        switch roundState {
        case .go: return Color.softGreen.opacity(0.08)
        case .jumpStart: return Color.emberGold.opacity(0.06)
        case .tapped: return Color.focusIndigo.opacity(0.06)
        default: return Color.dojoSurface
        }
    }

    // MARK: - Logic

    private func handleTap() {
        switch roundState {
        case .ready, .tapped, .jumpStart:
            startInlineRound()
        case .lightsSequence, .holding:
            HapticManager.heavy()
            AudioManager.shared.wrongBuzz()
            roundTask?.cancel()
            withAnimation(.spring(response: 0.3)) {
                litCount = 0
                roundState = .jumpStart
            }
        case .go:
            guard let start = goTime else { return }
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            HapticManager.success()
            AudioManager.shared.correctTap()
            roundCount += 1
            if bestReaction == nil || ms < (bestReaction ?? Int.max) {
                bestReaction = ms
                saveInlineBest(ms)
            }
            withAnimation(.spring(response: 0.3)) {
                roundState = .tapped(ms: ms)
            }
        }
    }

    private func startInlineRound() {
        roundTask?.cancel()
        litCount = 0
        goTime = nil
        withAnimation(.spring(response: 0.3)) {
            roundState = .lightsSequence
        }
        roundTask = Task {
            for i in 1...5 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(Int.random(in: 600...1100)))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    HapticManager.light()
                    AudioManager.shared.softTap()
                    withAnimation(.easeIn(duration: 0.12)) { litCount = i }
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation { roundState = .holding } }

            try? await Task.sleep(for: .milliseconds(Int.random(in: 1000...4000)))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                HapticManager.medium()
                goTime = Date()
                withAnimation(.easeOut(duration: 0.05)) {
                    litCount = 0
                    roundState = .go
                }
            }

            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if case .go = roundState {
                    roundCount += 1
                    withAnimation { roundState = .tapped(ms: 3000) }
                }
            }
        }
    }

    private var inlineTapLabel: String {
        switch roundState {
        case .ready: return "Tap to start reaction test"
        case .lightsSequence, .holding: return "Wait for lights out"
        case .go: return "Lights out! Tap now!"
        case .tapped(let ms): return "\(ms) milliseconds. Tap for next round"
        case .jumpStart: return "Jump start. Tap to retry"
        }
    }

    private func saveInlineBest(_ ms: Int) {
        UserDefaults.standard.set(ms, forKey: "ReactionTapBestScore")
    }

    private func loadInlineBest() -> Int? {
        let val = UserDefaults.standard.integer(forKey: "ReactionTapBestScore")
        return val > 0 ? val : nil
    }
}

// MARK: - Standalone F1 Reaction Game View

struct ReactionTapGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var roundState: ReactionRoundState = .ready
    @State private var litCount = 0
    @State private var goTime: Date?
    @State private var bestReaction: Int?
    @State private var reactionTimes: [Int] = []
    @State private var roundCount = 0
    @State private var timeRemaining = 30
    @State private var isRunning = false
    @State private var gameOver = false
    @State private var roundTask: Task<Void, Never>?
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground(accentColor: .focusIndigo)

                VStack(spacing: AppSpacing.lg) {
                    HStack {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundStyle(Color.focusIndigo)
                            Text("Round \(roundCount)")
                                .font(.dojoHeading())
                                .foregroundStyle(Color.dojoTextPrimary)
                                .contentTransition(.numericText())
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Round \(roundCount)")

                        Spacer()

                        if isRunning {
                            Text("\(timeRemaining)s")
                                .font(.dojoMono(20))
                                .foregroundStyle(timeRemaining <= 5 ? Color.crimsonPulse : Color.dojoTextSecondary)
                                .contentTransition(.numericText())
                                .accessibilityLabel("\(timeRemaining) seconds remaining")
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)

                    F1LightsPanel(
                        litCount: litCount,
                        isGo: roundState == .go,
                        isJumpStart: roundState == .jumpStart
                    )
                    .padding(.horizontal, AppSpacing.md)

                    Button { standaloneTap() } label: {
                        RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                            .fill(standaloneTapColor)
                            .frame(maxWidth: .infinity)
                            .overlay(standaloneTapContent)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.md)

                    if let best = bestReaction {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(Color.emberGold)
                            Text("Best: \(best) ms")
                                .font(.dojoCaption())
                                .foregroundStyle(Color.dojoTextSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Best reaction time: \(best) milliseconds")
                    }
                }
                .padding(.vertical, AppSpacing.lg)

                if gameOver { standaloneGameOverOverlay }
            }
            .navigationTitle("F1 Reaction Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.emberGold)
                        .accessibilityLabel("Close game")
                }
            }
        }
        .task { bestReaction = loadStandaloneBest() }
        .onDisappear {
            roundTask?.cancel()
            timerTask?.cancel()
        }
    }

    // MARK: - Tap Content

    @ViewBuilder
    private var standaloneTapContent: some View {
        switch roundState {
        case .ready:
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.focusIndigo)
                Text(isRunning ? "Tap to Start Round" : "Tap to Begin")
                    .font(.dojoBody())
                    .foregroundStyle(Color.dojoTextSecondary)
            }
        case .lightsSequence, .holding:
            VStack(spacing: AppSpacing.sm) {
                Text("Wait...")
                    .font(.dojoHeading(28))
                    .foregroundStyle(Color.crimsonPulse)
                Text("React when lights go out")
                    .font(.dojoCaption(14))
                    .foregroundStyle(Color.dojoTextTertiary)
            }
        case .go:
            VStack(spacing: AppSpacing.sm) {
                Text("GO!")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(Color.softGreen)
                Text("TAP NOW!")
                    .font(.dojoHeading(20))
                    .foregroundStyle(Color.softGreen.opacity(0.8))
            }
        case .tapped(let ms):
            VStack(spacing: AppSpacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(ms)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(reactionColor(ms))
                    Text("ms")
                        .font(.dojoHeading(22))
                        .foregroundStyle(reactionColor(ms).opacity(0.7))
                }
                Text(reactionLabel(ms))
                    .font(.dojoBody())
                    .foregroundStyle(Color.dojoTextSecondary)
            }
        case .jumpStart:
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.emberGold)
                Text("Jump Start!")
                    .font(.dojoHeading(24))
                    .foregroundStyle(Color.emberGold)
            }
        }
    }

    private var standaloneTapColor: Color {
        switch roundState {
        case .go: return Color.softGreen.opacity(0.08)
        case .jumpStart: return Color.emberGold.opacity(0.06)
        case .tapped: return Color.focusIndigo.opacity(0.06)
        default: return Color.dojoSurface
        }
    }

    // MARK: - Game Over

    private var standaloneGameOverOverlay: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.focusIndigo)

            if let best = reactionTimes.min() {
                Text("\(best) ms")
                    .font(.dojoTitle(48))
                    .foregroundStyle(Color.dojoTextPrimary)
                Text("Best Reaction")
                    .font(.dojoBody())
                    .foregroundStyle(Color.dojoTextSecondary)
            }

            if !reactionTimes.isEmpty {
                let avg = reactionTimes.reduce(0, +) / reactionTimes.count
                HStack(spacing: AppSpacing.lg) {
                    VStack(spacing: AppSpacing.xxs) {
                        Text("\(avg) ms")
                            .font(.dojoMono(18))
                            .foregroundStyle(Color.calmTeal)
                        Text("Average")
                            .font(.dojoCaption(12))
                            .foregroundStyle(Color.dojoTextTertiary)
                    }
                    VStack(spacing: AppSpacing.xxs) {
                        Text("\(reactionTimes.count)")
                            .font(.dojoMono(18))
                            .foregroundStyle(Color.emberGold)
                        Text("Rounds")
                            .font(.dojoCaption(12))
                            .foregroundStyle(Color.dojoTextTertiary)
                    }
                }
            }

            if let sessionBest = reactionTimes.min(),
               let allTimeBest = bestReaction,
               sessionBest <= allTimeBest {
                Text("New Best!")
                    .font(.dojoHeading())
                    .foregroundStyle(Color.emberGold)
            }

            Button { resetGame() } label: {
                Text("Play Again")
                    .font(.dojoBody())
                    .foregroundStyle(Color.dojoBlack)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.focusIndigo, in: Capsule())
            }
            .accessibilityLabel("Play again")
        }
        .padding(AppSpacing.xxl)
        .dojoCard()
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Logic

    private func standaloneTap() {
        guard !gameOver else { return }

        switch roundState {
        case .ready:
            if !isRunning { startTimer() }
            startStandaloneRound()
        case .tapped, .jumpStart:
            startStandaloneRound()
        case .lightsSequence, .holding:
            HapticManager.heavy()
            AudioManager.shared.wrongBuzz()
            roundTask?.cancel()
            withAnimation(.spring(response: 0.3)) {
                litCount = 0
                roundState = .jumpStart
            }
            autoNextRound(delay: 1500)
        case .go:
            guard let start = goTime else { return }
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            HapticManager.success()
            AudioManager.shared.correctTap()
            roundCount += 1
            reactionTimes.append(ms)
            if bestReaction == nil || ms < (bestReaction ?? Int.max) {
                bestReaction = ms
                saveStandaloneBest(ms)
            }
            withAnimation(.spring(response: 0.3)) {
                roundState = .tapped(ms: ms)
            }
            autoNextRound(delay: 1500)
        }
    }

    private func startStandaloneRound() {
        roundTask?.cancel()
        litCount = 0
        goTime = nil
        withAnimation(.spring(response: 0.3)) {
            roundState = .lightsSequence
        }

        roundTask = Task {
            for i in 1...5 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(Int.random(in: 600...1100)))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    HapticManager.light()
                    AudioManager.shared.softTap()
                    withAnimation(.easeIn(duration: 0.12)) { litCount = i }
                }
            }

            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation { roundState = .holding } }

            try? await Task.sleep(for: .milliseconds(Int.random(in: 1000...4000)))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                HapticManager.medium()
                goTime = Date()
                withAnimation(.easeOut(duration: 0.05)) {
                    litCount = 0
                    roundState = .go
                }
            }

            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if case .go = roundState {
                    roundCount += 1
                    reactionTimes.append(3000)
                    withAnimation { roundState = .tapped(ms: 3000) }
                    autoNextRound(delay: 1500)
                }
            }
        }
    }

    private func autoNextRound(delay ms: Int) {
        Task {
            try? await Task.sleep(for: .milliseconds(ms))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if isRunning && !gameOver { startStandaloneRound() }
            }
        }
    }

    private func startTimer() {
        isRunning = true
        timeRemaining = 30
        timerTask = Task {
            while timeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation { timeRemaining -= 1 }
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { endGame() }
        }
    }

    private func endGame() {
        isRunning = false
        roundTask?.cancel()
        timerTask?.cancel()
        HapticManager.success()
        AudioManager.shared.successChime()
        withAnimation(.spring(duration: 0.4)) {
            gameOver = true
        }
    }

    private func resetGame() {
        gameOver = false
        isRunning = false
        roundCount = 0
        reactionTimes.removeAll()
        timeRemaining = 30
        litCount = 0
        roundState = .ready
    }

    private func saveStandaloneBest(_ ms: Int) {
        UserDefaults.standard.set(ms, forKey: "ReactionTapBestScore")
    }

    private func loadStandaloneBest() -> Int? {
        let val = UserDefaults.standard.integer(forKey: "ReactionTapBestScore")
        return val > 0 ? val : nil
    }
}
