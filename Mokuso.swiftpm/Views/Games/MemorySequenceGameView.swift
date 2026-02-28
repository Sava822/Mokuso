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
            RoundedRectangle(cornerRadius: isIPad ? 16 : 12, style: .continuous)
                .fill(tileGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: isIPad ? 16 : 12, style: .continuous)
                        .stroke(tileBorder, lineWidth: isHighlighted ? (isIPad ? 2.5 : 2) : 1)
                )
                .shadow(color: tileShadow, radius: isHighlighted ? 12 : 0)
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(isHighlighted ? 1.08 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHighlighted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tile \(index + 1)")
        .accessibilityHint(isHighlighted ? "Highlighted" : "Tap to select")
    }

    private var tileGradient: some ShapeStyle {
        if isWrong {
            return AnyShapeStyle(
                LinearGradient(colors: [Color.crimsonPulse.opacity(0.5), Color.crimsonPulse.opacity(0.3)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
        if isHighlighted {
            return AnyShapeStyle(
                LinearGradient(colors: [Color.focusIndigo.opacity(0.8), Color.focusIndigo.opacity(0.5)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
        if isPlayerTap {
            return AnyShapeStyle(
                LinearGradient(colors: [Color.focusIndigo.opacity(0.35), Color.focusIndigo.opacity(0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
        return AnyShapeStyle(
            LinearGradient(colors: [Color.dojoElevated, Color.dojoSurface],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var tileBorder: Color {
        if isWrong { return Color.crimsonPulse.opacity(0.8) }
        if isHighlighted { return Color.focusIndigo.opacity(0.9) }
        if isPlayerTap { return Color.focusIndigo.opacity(0.4) }
        return Color.white.opacity(0.06)
    }

    private var tileShadow: Color {
        if isWrong { return Color.crimsonPulse.opacity(0.5) }
        if isHighlighted { return Color.focusIndigo.opacity(0.6) }
        return .clear
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
            HStack(alignment: .center) {
                HStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
                    Text("LVL")
                        .font(.system(size: isIPad ? 11 : 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.focusIndigo.opacity(0.6))
                        .tracking(1)
                    Text("\(level)")
                        .font(.system(size: isIPad ? 24 : 18, weight: .black, design: .rounded))
                        .foregroundStyle(Color.focusIndigo)
                        .contentTransition(.numericText())
                }

                Spacer()

                Text(stateText)
                    .font(.system(size: isIPad ? 15 : 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(stateColor)
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
        case .showing: return "Watch..."
        case .playing: return "Your turn"
        case .success: return "Correct!"
        case .failed: return "Try again"
        }
    }

    private var stateColor: Color {
        switch state {
        case .showing: return .dojoTextTertiary
        case .playing: return .dojoTextSecondary
        case .success: return .softGreen
        case .failed: return .crimsonPulse
        }
    }

    private var progressDots: some View {
        HStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
            ForEach(0..<sequence.count, id: \.self) { i in
                Circle()
                    .fill(i < playerSequence.count ? Color.focusIndigo : Color.dojoMuted.opacity(0.4))
                    .frame(width: isIPad ? 10 : 7, height: isIPad ? 10 : 7)
                    .shadow(color: i < playerSequence.count ? Color.focusIndigo.opacity(0.4) : .clear, radius: 4)
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
            AudioManager.shared.softTap()
            playerSequence.append(index)

            if playerSequence.count == sequence.count {
                state = .success
                HapticManager.success()
                AudioManager.shared.correctTap()
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
            AudioManager.shared.wrongBuzz()
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
                    AudioManager.shared.softTap()
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }
    @State private var sequence: [Int] = []
    @State private var playerSequence: [Int] = []
    @State private var level = 1
    @State private var bestLevel: Int? = nil
    @State private var state: PatternState = .showing
    @State private var highlightedTile: Int? = nil
    @State private var wrongTile: Int? = nil
    @State private var showTask: Task<Void, Never>?

    private var tileSize: CGFloat { isIPad ? 100 : 80 }
    private var gridSpacing: CGFloat { isIPad ? 14 : 10 }
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(tileSize), spacing: gridSpacing), count: 3)
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
                                Text("LEVEL")
                                    .font(.system(size: isIPad ? 12 : 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.focusIndigo.opacity(0.6))
                                    .tracking(2)
                                Text("\(level)")
                                    .font(.system(size: isIPad ? 28 : 22, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.focusIndigo)
                                    .contentTransition(.numericText())
                            }
                            Text(stateText)
                                .font(.system(size: isIPad ? 14 : 12, weight: .medium, design: .rounded))
                                .foregroundStyle(standaloneStateColor)
                        }
                        Spacer()

                        if let best = bestLevel {
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: isIPad ? 12 : 10))
                                        .foregroundStyle(Color.emberGold)
                                    Text("BEST")
                                        .font(.system(size: isIPad ? 10 : 8, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.emberGold.opacity(0.6))
                                        .tracking(1)
                                }
                                Text("\(best)")
                                    .font(.system(size: isIPad ? 22 : 18, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.emberGold)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Best level: \(best)")
                        }
                    }
                    .padding(.horizontal, isIPad ? AppSpacing.xl : AppSpacing.lg)

                    Spacer()

                    // Grid
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

                    // Progress dots
                    standaloneProgressDots
                        .opacity(state == .playing ? 1 : 0.3)

                    Spacer()
                }
                .padding(.vertical, isIPad ? AppSpacing.xl : AppSpacing.lg)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PATTERN RECALL")
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

    private var standaloneStateColor: Color {
        switch state {
        case .showing: return .dojoTextTertiary
        case .playing: return .dojoTextSecondary
        case .success: return .softGreen
        case .failed: return .crimsonPulse
        }
    }

    private var standaloneProgressDots: some View {
        HStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
            ForEach(0..<sequence.count, id: \.self) { i in
                Circle()
                    .fill(i < playerSequence.count ? Color.focusIndigo : Color.dojoMuted.opacity(0.3))
                    .frame(width: isIPad ? 10 : 8, height: isIPad ? 10 : 8)
                    .shadow(color: i < playerSequence.count ? Color.focusIndigo.opacity(0.5) : .clear, radius: 4)
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
            AudioManager.shared.softTap()
            playerSequence.append(index)

            if playerSequence.count == sequence.count {
                state = .success
                HapticManager.success()
                AudioManager.shared.correctTap()

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
            AudioManager.shared.wrongBuzz()
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
                    AudioManager.shared.softTap()
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
