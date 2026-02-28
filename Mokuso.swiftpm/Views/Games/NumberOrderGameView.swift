import SwiftUI

// MARK: - Number Tile Component

struct NumberTile: View {
    let number: Int
    let isTapped: Bool
    let isWrong: Bool
    let action: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(size: isIPad ? 24 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(isTapped ? Color.dojoMuted.opacity(0.3) : Color.dojoTextPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: isIPad ? 12 : 10, style: .continuous)
                        .fill(tileGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isIPad ? 12 : 10, style: .continuous)
                        .stroke(tileBorder, lineWidth: isWrong ? 1.5 : 1)
                )
                .shadow(color: tileShadow, radius: isWrong ? 8 : 0)
        }
        .buttonStyle(.plain)
        .scaleEffect(isTapped ? 0.92 : 1.0)
        .opacity(isTapped ? 0.4 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isTapped)
        .accessibilityLabel("Number \(number)")
        .accessibilityHint(isTapped ? "Already tapped" : "Tap to select")
        .disabled(isTapped)
    }

    private var tileGradient: some ShapeStyle {
        if isWrong {
            return AnyShapeStyle(
                LinearGradient(colors: [Color.crimsonPulse.opacity(0.4), Color.crimsonPulse.opacity(0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
        if isTapped {
            return AnyShapeStyle(Color.dojoBlack.opacity(0.3))
        }
        return AnyShapeStyle(
            LinearGradient(colors: [Color.dojoElevated, Color.dojoSurface],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var tileBorder: Color {
        if isWrong { return Color.crimsonPulse.opacity(0.7) }
        if isTapped { return Color.clear }
        return Color.white.opacity(0.06)
    }

    private var tileShadow: Color {
        if isWrong { return Color.crimsonPulse.opacity(0.4) }
        return .clear
    }
}

// MARK: - Inline Number Order Game (for PreFight Flow)

struct InlineNumberOrderGame: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }
    @State private var numbers: [Int] = []
    @State private var nextNumber = 1
    @State private var wrongTap: Int? = nil
    @State private var tappedNumbers: Set<Int> = []
    @State private var completions = 0

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: isIPad ? 10 : 6), count: 5)
    }

    var body: some View {
        VStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
            HStack(alignment: .center) {
                HStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
                    Text("NEXT")
                        .font(.system(size: isIPad ? 11 : 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.focusIndigo.opacity(0.6))
                        .tracking(1)
                    Text("\(nextNumber)")
                        .font(.system(size: isIPad ? 24 : 18, weight: .black, design: .rounded))
                        .foregroundStyle(Color.focusIndigo)
                        .contentTransition(.numericText())
                }

                Spacer()

                if completions > 0 {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: isIPad ? 14 : 11))
                            .foregroundStyle(Color.softGreen)
                        Text("\(completions)×")
                            .font(.system(size: isIPad ? 16 : 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.softGreen)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Completed \(completions) times")
                }
            }

            LazyVGrid(columns: gridColumns, spacing: isIPad ? 10 : 6) {
                ForEach(numbers, id: \.self) { number in
                    NumberTile(
                        number: number,
                        isTapped: tappedNumbers.contains(number),
                        isWrong: wrongTap == number
                    ) {
                        handleTap(number)
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .task {
            shuffleNumbers()
        }
    }

    private func handleTap(_ number: Int) {
        if number == nextNumber {
            HapticManager.light()
            AudioManager.shared.softTap()
            withAnimation(.spring(duration: 0.2)) {
                tappedNumbers.insert(number)
                nextNumber += 1
            }
            if nextNumber > 25 {
                AudioManager.shared.correctTap()
                completions += 1
                resetGame()
            }
        } else {
            HapticManager.error()
            AudioManager.shared.wrongBuzz()
            wrongTap = number
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { wrongTap = nil }
            }
        }
    }

    private func resetGame() {
        tappedNumbers.removeAll()
        nextNumber = 1
        shuffleNumbers()
    }

    private func shuffleNumbers() {
        numbers = Array(1...25).shuffled()
    }
}

// MARK: - Standalone Number Order Game View

struct NumberOrderGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }
    @State private var numbers: [Int] = []
    @State private var nextNumber = 1
    @State private var wrongTap: Int? = nil
    @State private var tappedNumbers: Set<Int> = []
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var bestTime: TimeInterval? = nil
    @State private var gameComplete = false
    @State private var timer: Timer?

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: isIPad ? 10 : 8), count: 5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dojoBlack.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.focusIndigo.opacity(0.08), Color.clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: isIPad ? 400 : 250
                )
                .ignoresSafeArea()

                DojoGrainOverlay()

                VStack(spacing: isIPad ? AppSpacing.xl : AppSpacing.lg) {
                    // Header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            HStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
                                Text("NEXT")
                                    .font(.system(size: isIPad ? 12 : 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.focusIndigo.opacity(0.6))
                                    .tracking(2)
                                Text("\(nextNumber)")
                                    .font(.system(size: isIPad ? 28 : 22, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.focusIndigo)
                                    .contentTransition(.numericText())
                            }

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(Color.dojoSurface)
                                        .frame(height: isIPad ? 4 : 3)
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(
                                            LinearGradient(colors: [Color.focusIndigo, Color.calmTeal],
                                                           startPoint: .leading, endPoint: .trailing)
                                        )
                                        .frame(width: geo.size.width * CGFloat(tappedNumbers.count) / 25.0, height: isIPad ? 4 : 3)
                                        .animation(.spring(response: 0.3), value: tappedNumbers.count)
                                }
                            }
                            .frame(height: isIPad ? 4 : 3)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(timeString(elapsedTime))
                                .font(.system(size: isIPad ? 22 : 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.dojoTextSecondary)
                                .monospacedDigit()
                            if let best = bestTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: isIPad ? 10 : 8))
                                        .foregroundStyle(Color.emberGold)
                                    Text(timeString(best))
                                        .font(.system(size: isIPad ? 12 : 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Color.emberGold.opacity(0.7))
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Best time: \(timeString(best))")
                            }
                        }
                    }
                    .padding(.horizontal, isIPad ? AppSpacing.xl : AppSpacing.lg)

                    // Grid
                    LazyVGrid(columns: gridColumns, spacing: isIPad ? 10 : 8) {
                        ForEach(numbers, id: \.self) { number in
                            NumberTile(
                                number: number,
                                isTapped: tappedNumbers.contains(number),
                                isWrong: wrongTap == number
                            ) {
                                handleTap(number)
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding(.horizontal, isIPad ? AppSpacing.xl : AppSpacing.lg)

                    Spacer()
                }
                .padding(.vertical, isIPad ? AppSpacing.xl : AppSpacing.lg)

                if gameComplete {
                    completionOverlay
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NUMBER ORDER")
                        .font(.system(size: isIPad ? 14 : 12, weight: .bold, design: .serif))
                        .foregroundStyle(Color.dojoTextSecondary)
                        .tracking(isIPad ? 4 : 2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                        .foregroundStyle(Color.emberGold)
                        .accessibilityLabel("Close game")
                }
            }
            .toolbarBackground(Color.dojoBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task {
            bestTime = loadBestTime()
            shuffleNumbers()
        }
    }

    private var completionOverlay: some View {
        VStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: isIPad ? 64 : 52, weight: .bold))
                .foregroundStyle(Color.softGreen)
                .shadow(color: Color.softGreen.opacity(0.4), radius: 20)

            Text(timeString(elapsedTime))
                .font(.system(size: isIPad ? 48 : 40, weight: .black, design: .monospaced))
                .foregroundStyle(Color.dojoTextPrimary)

            if let best = bestTime, elapsedTime <= best {
                Text("NEW BEST")
                    .font(.system(size: isIPad ? 14 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.emberGold)
                    .tracking(3)
            }

            Button {
                gameComplete = false
                resetGame()
            } label: {
                Text("PLAY AGAIN")
                    .font(.system(size: isIPad ? 16 : 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dojoBlack)
                    .tracking(2)
                    .padding(.horizontal, isIPad ? AppSpacing.xxl : AppSpacing.xl)
                    .padding(.vertical, isIPad ? AppSpacing.md : AppSpacing.sm)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(colors: [Color.focusIndigo, Color.calmTeal],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                    )
            }
            .accessibilityLabel("Play again")
        }
        .padding(isIPad ? AppSpacing.xxl : AppSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .fill(Color.dojoSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
        .transition(.scale.combined(with: .opacity))
    }

    private func handleTap(_ number: Int) {
        if !isRunning {
            isRunning = true
            startTimer()
        }

        if number == nextNumber {
            HapticManager.light()
            AudioManager.shared.softTap()
            withAnimation(.spring(duration: 0.2)) {
                tappedNumbers.insert(number)
                nextNumber += 1
            }
            if nextNumber > 25 {
                finishGame()
            }
        } else {
            HapticManager.error()
            AudioManager.shared.wrongBuzz()
            wrongTap = number
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { wrongTap = nil }
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            Task { @MainActor in
                elapsedTime += 0.01
            }
        }
    }

    private func finishGame() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        HapticManager.success()
        AudioManager.shared.successChime()

        if let best = bestTime {
            if elapsedTime < best {
                bestTime = elapsedTime
                saveBestTime(elapsedTime)
            }
        } else {
            bestTime = elapsedTime
            saveBestTime(elapsedTime)
        }

        withAnimation(.spring(duration: 0.4)) {
            gameComplete = true
        }
    }

    private func resetGame() {
        tappedNumbers.removeAll()
        nextNumber = 1
        elapsedTime = 0
        isRunning = false
        shuffleNumbers()
    }

    private func shuffleNumbers() {
        numbers = Array(1...25).shuffled()
    }

    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let hundredths = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, hundredths)
    }

    private func saveBestTime(_ time: TimeInterval) {
        UserDefaults.standard.set(time, forKey: "NumberGameBestTime")
    }

    private func loadBestTime() -> TimeInterval? {
        let val = UserDefaults.standard.double(forKey: "NumberGameBestTime")
        return val > 0 ? val : nil
    }
}
