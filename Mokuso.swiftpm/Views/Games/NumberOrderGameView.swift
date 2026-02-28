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
                .font(.system(size: isIPad ? 26 : 18, weight: .bold, design: .rounded))
                .foregroundStyle(isTapped ? Color.dojoTextTertiary : Color.dojoTextPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                        .fill(tileColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                        .stroke(tileBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Number \(number)")
        .accessibilityHint(isTapped ? "Already tapped" : "Tap to select")
        .disabled(isTapped)
    }

    private var tileColor: Color {
        if isWrong { return Color.crimsonPulse.opacity(0.3) }
        if isTapped { return Color.dojoBlack.opacity(0.5) }
        return Color.dojoElevated
    }

    private var tileBorder: Color {
        if isWrong { return Color.crimsonPulse.opacity(0.6) }
        if isTapped { return Color.clear }
        return Color.white.opacity(0.06)
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
            if completions > 0 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isIPad ? 18 : 14))
                        .foregroundStyle(Color.softGreen)
                    Text("Completed \(completions)×")
                        .font(.dojoCaption(isIPad ? 16 : 13))
                        .foregroundStyle(Color.dojoTextSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Completed \(completions) times")
            }

            Text("Next: \(nextNumber)")
                .font(.dojoCaption(isIPad ? 18 : 13))
                .foregroundStyle(Color.focusIndigo)
                .contentTransition(.numericText())

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
            withAnimation(.spring(duration: 0.2)) {
                tappedNumbers.insert(number)
                nextNumber += 1
            }
            if nextNumber > 25 {
                completions += 1
                resetGame()
            }
        } else {
            HapticManager.error()
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
    @State private var numbers: [Int] = []
    @State private var nextNumber = 1
    @State private var wrongTap: Int? = nil
    @State private var tappedNumbers: Set<Int> = []
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var bestTime: TimeInterval? = nil
    @State private var gameComplete = false
    @State private var timer: Timer?

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground(accentColor: .focusIndigo)

                VStack(spacing: AppSpacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("Next: \(nextNumber)")
                                .font(.dojoHeading())
                                .foregroundStyle(Color.focusIndigo)
                                .contentTransition(.numericText())
                        }
                        Spacer()
                        Text(timeString(elapsedTime))
                            .font(.dojoMono(20))
                            .foregroundStyle(Color.dojoTextSecondary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, AppSpacing.md)

                    LazyVGrid(columns: gridColumns, spacing: 8) {
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
                    .padding(.horizontal, AppSpacing.md)

                    Spacer()

                    if let best = bestTime {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(Color.emberGold)
                            Text("Best: \(timeString(best))")
                                .font(.dojoCaption())
                                .foregroundStyle(Color.dojoTextSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Best time: \(timeString(best))")
                    }
                }
                .padding(.vertical, AppSpacing.lg)

                if gameComplete {
                    completionOverlay
                }
            }
            .navigationTitle("Number Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.emberGold)
                        .accessibilityLabel("Close game")
                }
            }
        }
        .task {
            bestTime = loadBestTime()
            shuffleNumbers()
        }
    }

    private var completionOverlay: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(Color.softGreen)
                .appGlow(.softGreen, radius: 30)

            Text(timeString(elapsedTime))
                .font(.dojoTitle(40))
                .foregroundStyle(Color.dojoTextPrimary)

            if let best = bestTime, elapsedTime <= best {
                Text("New Best!")
                    .font(.dojoHeading())
                    .foregroundStyle(Color.emberGold)
            }

            Button {
                gameComplete = false
                resetGame()
            } label: {
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

    private func handleTap(_ number: Int) {
        if !isRunning {
            isRunning = true
            startTimer()
        }

        if number == nextNumber {
            HapticManager.light()
            withAnimation(.spring(duration: 0.2)) {
                tappedNumbers.insert(number)
                nextNumber += 1
            }
            if nextNumber > 25 {
                finishGame()
            }
        } else {
            HapticManager.error()
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
