import SwiftUI

// MARK: - Pattern Game State

enum PatternState {
    case showing
    case playing
    case success
    case failed
}

// MARK: - Memory Tile Component

struct MemoryTile: View {
    let index: Int
    let isHighlighted: Bool
    let isPlayerTap: Bool
    let isWrong: Bool
    let action: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                .fill(tileColor)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                        .stroke(tileBorder, lineWidth: isHighlighted ? (isIPad ? 3 : 2) : 1)
                )
                .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tile \(index + 1)")
        .accessibilityHint(isHighlighted ? "Highlighted" : "Tap to select")
    }

    private var tileColor: Color {
        if isWrong { return Color.crimsonPulse.opacity(0.4) }
        if isHighlighted { return Color.focusIndigo.opacity(0.7) }
        if isPlayerTap { return Color.focusIndigo.opacity(0.4) }
        return Color.dojoElevated
    }

    private var tileBorder: Color {
        if isWrong { return Color.crimsonPulse }
        if isHighlighted { return Color.focusIndigo }
        return Color.white.opacity(0.06)
    }
}

// MARK: - Inline Pattern Recall Game (for PreFight Flow)

struct InlinePatternRecallGame: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }
    @State private var sequence: [Int] = []
    @State private var playerSequence: [Int] = []
    @State private var level = 1
    @State private var state: PatternState = .showing
    @State private var highlightedTile: Int? = nil
    @State private var wrongTile: Int? = nil
    @State private var showTask: Task<Void, Never>?

    private var tileSize: CGFloat { isIPad ? 110 : 72 }
    private var gridSpacing: CGFloat { isIPad ? 12 : 8 }
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(tileSize), spacing: gridSpacing), count: 3)
    }

    var body: some View {
        VStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            HStack {
                Text("Level \(level)")
                    .font(.dojoCaption(isIPad ? 18 : 13))
                    .foregroundStyle(Color.focusIndigo)
                    .contentTransition(.numericText())

                Spacer()

                Text(stateText)
                    .font(.dojoCaption(isIPad ? 18 : 13))
                    .foregroundStyle(Color.dojoTextSecondary)
            }

            LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
                ForEach(0..<9, id: \.self) { index in
                    MemoryTile(
                        index: index,
                        isHighlighted: highlightedTile == index,
                        isPlayerTap: playerSequence.contains(index) && state == .playing,
                        isWrong: wrongTile == index
                    ) {
                        handleTap(index)
                    }
                    .frame(width: tileSize, height: tileSize)
                    .disabled(state != .playing)
                }
            }
            .fixedSize()

            progressDots
                .opacity(state == .playing ? 1 : 0)
        }
        .task {
            startNewRound()
        }
        .onDisappear {
            showTask?.cancel()
        }
    }

    private var stateText: String {
        switch state {
        case .showing: return "Watch carefully..."
        case .playing: return "Your turn!"
        case .success: return "Correct!"
        case .failed: return "Try again"
        }
    }

    private var progressDots: some View {
        HStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
            ForEach(0..<sequence.count, id: \.self) { i in
                Circle()
                    .fill(i < playerSequence.count ? Color.focusIndigo : Color.dojoMuted)
                    .frame(width: isIPad ? 11 : 8, height: isIPad ? 11 : 8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(playerSequence.count) of \(sequence.count) entered")
    }

    private func handleTap(_ index: Int) {
        guard state == .playing else { return }

        let expectedIndex = playerSequence.count
        if index == sequence[expectedIndex] {
            HapticManager.light()
            playerSequence.append(index)

            if playerSequence.count == sequence.count {
                state = .success
                HapticManager.success()
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    await MainActor.run {
                        level += 1
                        startNewRound()
                    }
                }
            }
        } else {
            HapticManager.error()
            wrongTile = index
            state = .failed
            Task {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    wrongTile = nil
                    level = 1
                    startNewRound()
                }
            }
        }
    }

    private func startNewRound() {
        let sequenceLength = level + 2
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<9) }
        playerSequence = []
        state = .showing
        highlightedTile = nil

        showTask?.cancel()
        showTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            for tile in sequence {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        highlightedTile = tile
                    }
                    HapticManager.light()
                }
                try? await Task.sleep(for: .milliseconds(600))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        highlightedTile = nil
                    }
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                state = .playing
            }
        }
    }
}

// MARK: - Standalone Memory Sequence Game View

struct MemorySequenceGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sequence: [Int] = []
    @State private var playerSequence: [Int] = []
    @State private var level = 1
    @State private var bestLevel: Int? = nil
    @State private var state: PatternState = .showing
    @State private var highlightedTile: Int? = nil
    @State private var wrongTile: Int? = nil
    @State private var showTask: Task<Void, Never>?

    private let tileSize: CGFloat = 80
    private let gridSpacing: CGFloat = 10
    private let gridColumns: [GridItem] = Array(
        repeating: GridItem(.fixed(80), spacing: 10),
        count: 3
    )

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground(accentColor: .focusIndigo)

                VStack(spacing: AppSpacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("Level \(level)")
                                .font(.dojoHeading())
                                .foregroundStyle(Color.focusIndigo)
                                .contentTransition(.numericText())
                            Text(stateText)
                                .font(.dojoCaption())
                                .foregroundStyle(Color.dojoTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.md)

                    LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
                        ForEach(0..<9, id: \.self) { index in
                            MemoryTile(
                                index: index,
                                isHighlighted: highlightedTile == index,
                                isPlayerTap: playerSequence.contains(index) && state == .playing,
                                isWrong: wrongTile == index
                            ) {
                                handleTap(index)
                            }
                            .frame(width: tileSize, height: tileSize)
                            .disabled(state != .playing)
                        }
                    }
                    .fixedSize()

                    progressDots
                        .opacity(state == .playing ? 1 : 0)

                    Spacer()

                    if let best = bestLevel {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(Color.emberGold)
                            Text("Best: Level \(best)")
                                .font(.dojoCaption())
                                .foregroundStyle(Color.dojoTextSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Best level: \(best)")
                    }
                }
                .padding(.vertical, AppSpacing.lg)
            }
            .navigationTitle("Pattern Recall")
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
            bestLevel = loadBestLevel()
            startNewRound()
        }
        .onDisappear {
            showTask?.cancel()
        }
    }

    private var stateText: String {
        switch state {
        case .showing: return "Watch carefully..."
        case .playing: return "Your turn!"
        case .success: return "Correct!"
        case .failed: return "Try again"
        }
    }

    private var progressDots: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<sequence.count, id: \.self) { i in
                Circle()
                    .fill(i < playerSequence.count ? Color.focusIndigo : Color.dojoMuted)
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(playerSequence.count) of \(sequence.count) entered")
    }

    private func handleTap(_ index: Int) {
        guard state == .playing else { return }

        let expectedIndex = playerSequence.count
        if index == sequence[expectedIndex] {
            HapticManager.light()
            playerSequence.append(index)

            if playerSequence.count == sequence.count {
                state = .success
                HapticManager.success()

                if let best = bestLevel {
                    if level > best {
                        bestLevel = level
                        saveBestLevel(level)
                    }
                } else {
                    bestLevel = level
                    saveBestLevel(level)
                }

                Task {
                    try? await Task.sleep(for: .seconds(1))
                    await MainActor.run {
                        level += 1
                        startNewRound()
                    }
                }
            }
        } else {
            HapticManager.error()
            wrongTile = index
            state = .failed
            Task {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    wrongTile = nil
                    level = 1
                    startNewRound()
                }
            }
        }
    }

    private func startNewRound() {
        let sequenceLength = level + 2
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<9) }
        playerSequence = []
        state = .showing
        highlightedTile = nil

        showTask?.cancel()
        showTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            for tile in sequence {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        highlightedTile = tile
                    }
                    HapticManager.light()
                }
                try? await Task.sleep(for: .milliseconds(600))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        highlightedTile = nil
                    }
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                state = .playing
            }
        }
    }

    private func saveBestLevel(_ level: Int) {
        UserDefaults.standard.set(level, forKey: "MemoryGameBestLevel")
    }

    private func loadBestLevel() -> Int? {
        let val = UserDefaults.standard.integer(forKey: "MemoryGameBestLevel")
        return val > 0 ? val : nil
    }
}
