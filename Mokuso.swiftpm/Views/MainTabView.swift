import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var settings: [UserSettings]
    @Query private var streakData: [StreakData]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    @State private var showPreFightFlow = false
    @State private var showSettings = false
    @State private var showWhyItWorks = false
    @State private var showHistory = false
    @State private var breathePulse = false
    @State private var glowPulse = false

    private var currentSettings: UserSettings {
        if let first = settings.first { return first }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    private var currentStreak: StreakData {
        if let first = streakData.first { return first }
        let newStreak = StreakData()
        modelContext.insert(newStreak)
        return newStreak
    }

    var body: some View {
        ZStack {
            // Background
            Color.dojoBlack.ignoresSafeArea()

            // Pulsing radial glow
            RadialGradient(
                colors: [
                    Color.emberGold.opacity(glowPulse ? 0.08 : 0.03),
                    Color.clear
                ],
                center: .center,
                startRadius: isIPad ? 40 : 20,
                endRadius: isIPad ? 500 : 300
            )
            .ignoresSafeArea()

            DojoGrainOverlay()

            // Floating embers
            FloatingEmbers(
                color: .emberGold,
                count: isIPad ? 50 : 30,
                speed: 0.7
            )

            // Content
            VStack(spacing: 0) {
                // Top bar
                topBar
                    .staggeredFadeIn(delay: 0.1)
                    .padding(.horizontal, AppSpacing.lg)

                // Title block
                titleBlock
                    .staggeredFadeIn(delay: 0.1)
                    .padding(.top, AppSpacing.md)

                // Decorative accent line under title
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.emberGold.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: isIPad ? 200 : 120, height: 1)
                    .padding(.top, isIPad ? AppSpacing.lg : AppSpacing.md)
                    .staggeredFadeIn(delay: 0.12)

                Spacer()

                // Personal statement — equidistant between title and button
                Text("\"Before every judo match, my hands shake.\nThis is how I learned to turn fear into focus.\"")
                    .font(.system(size: isIPad ? 24 : 17, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(Color.emberLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(isIPad ? 8 : 6)
                    .shadow(color: Color.emberGold.opacity(0.35), radius: 12)
                    .frame(maxWidth: isIPad ? 520 : .infinity)
                    .padding(.horizontal, isIPad ? AppSpacing.xxl : AppSpacing.xl)
                    .staggeredFadeIn(delay: 0.15)

                Spacer()

                // Start button — hero element, centered
                startButton
                    .staggeredFadeIn(delay: 0.2)

                Spacer()

                // Static flow order indicator
                flowIndicator
                    .staggeredFadeIn(delay: 0.3)
                    .padding(.bottom, isIPad ? AppSpacing.xxl : AppSpacing.xl)
            }
        }
        .task {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathePulse = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .fullScreenCover(isPresented: $showPreFightFlow) {
            PreFightFlowView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            PreFightSettingsSheet()
        }
        .fullScreenCover(isPresented: $showWhyItWorks) {
            WhyItWorksView()
        }
        .fullScreenCover(isPresented: $showHistory) {
            HistoryView()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            Button {
                HapticManager.light()
                showHistory = true
            } label: {
                Image(systemName: "chart.bar.fill")
                    .font(isIPad ? .title : .title2)
                    .foregroundStyle(Color.dojoTextTertiary)
                    .frame(width: isIPad ? 52 : 44, height: isIPad ? 52 : 44)
            }
            .accessibilityLabel("Progress")
            .accessibilityHint("View your training history and stats")

            Button {
                HapticManager.light()
                showWhyItWorks = true
            } label: {
                Image(systemName: "info.circle")
                    .font(isIPad ? .title : .title2)
                    .foregroundStyle(Color.dojoTextTertiary)
                    .frame(width: isIPad ? 52 : 44, height: isIPad ? 52 : 44)
            }
            .accessibilityLabel("Why it works")
            .accessibilityHint("Opens science explanations")

            Button {
                HapticManager.light()
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(isIPad ? .title : .title2)
                    .foregroundStyle(Color.dojoTextTertiary)
                    .frame(width: isIPad ? 52 : 44, height: isIPad ? 52 : 44)
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Customize your pre-fight routine")
        }
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
            Text("MOKUSO")
                .font(.system(size: isIPad ? 60 : 38, weight: .black, design: .serif))
                .foregroundStyle(Color.dojoTextPrimary)
                .tracking(isIPad ? 12 : 6)
                .shimmer(.emberGold)

            Text("PRE-FIGHT MENTAL RITUAL")
                .font(.system(size: isIPad ? 16 : 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.emberGold.opacity(0.8))
                .tracking(isIPad ? 8 : 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mokuso. Pre-fight mental ritual.")
    }

    // MARK: - Stats Ribbon

    private var statsRibbon: some View {
        HStack(spacing: isIPad ? AppSpacing.xl : AppSpacing.lg) {
            statItem(
                icon: "flame.fill",
                value: "\(currentStreak.currentStreak)",
                label: "Streak",
                color: currentStreak.currentStreak > 0 ? .emberGold : .dojoMuted
            )

            statItem(
                icon: "checkmark.circle.fill",
                value: "\(currentStreak.totalSessions)",
                label: "Sessions",
                color: .dojoTextSecondary
            )

            statItem(
                icon: "clock.fill",
                value: "\(currentStreak.totalMinutes)m",
                label: "Total",
                color: .dojoTextSecondary
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentStreak.currentStreak) day streak, \(currentStreak.totalSessions) sessions, \(currentStreak.totalMinutes) minutes total")
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 14 : 11))
                    .foregroundStyle(color)
                Text(value)
                    .font(.dojoMono(isIPad ? 16 : 13))
                    .foregroundStyle(Color.dojoTextPrimary)
            }
            Text(label)
                .font(.dojoCaption(isIPad ? 12 : 10))
                .foregroundStyle(Color.dojoTextTertiary)
        }
    }

    // MARK: - Flow Indicator (Static)

    private var flowIndicator: some View {
        HStack(spacing: 0) {
            ForEach(Array(RitualPhase.allCases.enumerated()), id: \.element.id) { index, phase in
                if index > 0 {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    RitualPhase.allCases[index - 1].color.opacity(0.3),
                                    phase.color.opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: isIPad ? 40 : 24, height: isIPad ? 1.5 : 1)
                        .padding(.horizontal, isIPad ? AppSpacing.sm : AppSpacing.xs)
                }

                HStack(spacing: isIPad ? 8 : 5) {
                    Circle()
                        .fill(phase.color)
                        .frame(width: isIPad ? 8 : 6, height: isIPad ? 8 : 6)
                        .shadow(color: phase.color.opacity(0.5), radius: 4)

                    Text(phase.shortName.uppercased())
                        .font(.system(size: isIPad ? 13 : 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.dojoTextTertiary)
                        .tracking(isIPad ? 2 : 1)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Flow order: Breathe, Focus, Activate")
    }

    // MARK: - Start Button

    private var startButton: some View {
        let outerSize: CGFloat = isIPad ? 380 : 240
        let innerSize: CGFloat = isIPad ? 356 : 222
        return Button {
            HapticManager.heavy()
            AudioManager.shared.startRitual()
            showPreFightFlow = true
        } label: {
            ZStack {
                // Ambient glow behind button
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.emberGold.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: outerSize * 0.8
                        )
                    )
                    .frame(width: outerSize * 1.6, height: outerSize * 1.6)
                    .scaleEffect(breathePulse ? 1.1 : 0.9)

                // Outer breathing octagon
                OctagonShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.emberLight, Color.emberGold.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: isIPad ? 3 : 2
                    )
                    .frame(width: outerSize, height: outerSize)
                    .scaleEffect(breathePulse ? 1.05 : 0.97)

                // Inner fill
                OctagonShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.emberLight, Color.emberGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: innerSize, height: innerSize)
                    .shadow(color: Color.emberGold.opacity(0.4), radius: 30)

                // Content
                VStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: isIPad ? 64 : 40, weight: .bold))
                        .foregroundStyle(Color.dojoBlack.opacity(0.85))

                    Text("START")
                        .font(.system(size: isIPad ? 36 : 24, weight: .black, design: .serif))
                        .foregroundStyle(Color.dojoBlack)
                        .tracking(isIPad ? 12 : 6)

                    Text("3 min ritual")
                        .font(.system(size: isIPad ? 16 : 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.dojoBlack.opacity(0.55))
                        .tracking(isIPad ? 2 : 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start pre-fight ritual")
        .accessibilityHint("Begins the 3-minute pre-fight mental routine")
    }

}


// MARK: - Settings Sheet

struct PreFightSettingsSheet: View {
    @Query private var settings: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    @AppStorage("selectedPreFightGame") private var selectedGameRaw: String = PreFightGame.reactionTap.rawValue
    @AppStorage("soundEnabled") private var soundEnabled: Bool = false

    private var selectedGame: PreFightGame {
        PreFightGame(rawValue: selectedGameRaw) ?? .reactionTap
    }

    private var currentSettings: UserSettings {
        if let first = settings.first { return first }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dojoBlack.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.focusIndigo.opacity(0.06), Color.clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: isIPad ? 500 : 300
                )
                .ignoresSafeArea()

                DojoGrainOverlay()

                ScrollView {
                    VStack(spacing: isIPad ? AppSpacing.xxl : AppSpacing.xl) {
                        // Focus Game Section
                        focusGameSection

                        // Sound Section
                        soundSection

                        // Reset Button
                        resetButton
                    }
                    .padding(.horizontal, isIPad ? AppSpacing.xxl : AppSpacing.lg)
                    .padding(.vertical, isIPad ? AppSpacing.xl : AppSpacing.lg)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(.system(size: isIPad ? 14 : 12, weight: .bold, design: .serif))
                        .foregroundStyle(Color.dojoTextSecondary)
                        .tracking(isIPad ? 4 : 2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                        .foregroundStyle(Color.emberGold)
                        .accessibilityLabel("Close settings")
                }
            }
            .toolbarBackground(Color.dojoBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func selectGame(_ game: PreFightGame) {
        HapticManager.light()
        withAnimation(.spring(duration: 0.3)) {
            selectedGameRaw = game.rawValue
        }
    }

    // MARK: - Focus Game Section

    private var focusGameSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                    Image(systemName: "gamecontroller")
                        .font(isIPad ? .title3 : .body)
                        .foregroundStyle(Color.focusIndigo)
                    Text("FOCUS GAME")
                        .font(.dojoCaption(isIPad ? 15 : 13))
                        .foregroundStyle(Color.focusIndigo)
                        .tracking(2)
                }

                if isIPad {
                    Text("Choose the cognitive challenge for your Focus phase")
                        .font(.dojoBody(15))
                        .foregroundStyle(Color.dojoTextTertiary)
                        .padding(.top, AppSpacing.xxs)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Focus game selection")

            if isIPad {
                // iPad: horizontal card grid
                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    ForEach(PreFightGame.allCases) { game in
                        gameCard(game)
                    }
                }
            } else {
                // iPhone: vertical list
                ForEach(PreFightGame.allCases) { game in
                    gameCard(game)
                }
            }
        }
    }

    private func gameCard(_ game: PreFightGame) -> some View {
        let isSelected = selectedGame == game

        return Group {
            if isIPad {
                // iPad: tall vertical card with rich description
                VStack(spacing: AppSpacing.lg) {
                    // Icon in colored circle
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.focusIndigo.opacity(0.15) : Color.dojoElevated)
                            .frame(width: 64, height: 64)

                        Image(systemName: game.icon)
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(isSelected ? Color.focusIndigo : Color.dojoTextSecondary)
                    }

                    VStack(spacing: AppSpacing.sm) {
                        Text(game.shortName)
                            .font(.dojoHeading(20))
                            .foregroundStyle(Color.dojoTextPrimary)

                        Text(game.previewDescription)
                            .font(.dojoBody(14))
                            .foregroundStyle(Color.dojoTextTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    // Selection indicator
                    if isSelected {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                            Text("Selected")
                                .font(.dojoCaption(13))
                        }
                        .foregroundStyle(Color.focusIndigo)
                    } else {
                        Text("Tap to select")
                            .font(.dojoCaption(13))
                            .foregroundStyle(Color.dojoMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
                .padding(.horizontal, AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                        .fill(isSelected ? Color.focusIndigo.opacity(0.06) : Color.dojoSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                        .stroke(isSelected ? Color.focusIndigo.opacity(0.4) : Color.white.opacity(0.04), lineWidth: isSelected ? 1.5 : 1)
                )
            } else {
                // iPhone: horizontal row layout
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: game.icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.focusIndigo : Color.dojoTextSecondary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(game.shortName)
                            .font(.dojoBody())
                            .foregroundStyle(Color.dojoTextPrimary)
                        Text(game.description)
                            .font(.dojoCaption(12))
                            .foregroundStyle(Color.dojoTextTertiary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.focusIndigo)
                    }
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                        .fill(isSelected ? Color.focusIndigo.opacity(0.08) : Color.dojoSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                        .stroke(isSelected ? Color.focusIndigo.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 1)
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { selectGame(game) }
        .accessibilityLabel("\(game.shortName). \(game.previewDescription)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            HStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                Image(systemName: "speaker.wave.2")
                    .font(isIPad ? .title3 : .body)
                    .foregroundStyle(Color.calmTeal)
                Text("SOUND")
                    .font(.dojoCaption(isIPad ? 15 : 13))
                    .foregroundStyle(Color.calmTeal)
                    .tracking(2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sound settings")

            Toggle(isOn: $soundEnabled) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title3)
                        .foregroundStyle(soundEnabled ? Color.calmTeal : Color.dojoTextSecondary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Audio Cues")
                            .font(.dojoBody())
                            .foregroundStyle(Color.dojoTextPrimary)
                        Text("Subtle tones during breathing and transitions")
                            .font(.dojoCaption(12))
                            .foregroundStyle(Color.dojoTextTertiary)
                    }
                }
            }
            .tint(Color.calmTeal)
            .onChange(of: soundEnabled) { _, newValue in
                if newValue {
                    AudioManager.shared.softTap()
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                    .fill(Color.dojoSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )
            .accessibilityLabel("Audio cues")
            .accessibilityHint(soundEnabled ? "Currently enabled. Double tap to disable" : "Currently disabled. Double tap to enable")
        }
    }

    // MARK: - Reset Button

    private var resetButton: some View {
        Button {
            HapticManager.medium()
            UserDefaults.standard.removeObject(forKey: "NumberGameBestTime")
            UserDefaults.standard.removeObject(forKey: "MemoryGameBestLevel")
            UserDefaults.standard.removeObject(forKey: "ReactionTapBestScore")
        } label: {
            HStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                Image(systemName: "arrow.counterclockwise")
                    .font(isIPad ? .body : .callout)
                Text("Reset Game Scores")
            }
            .font(.dojoBody(isIPad ? 18 : 16))
            .foregroundStyle(Color.crimsonPulse)
            .frame(maxWidth: .infinity)
            .padding(isIPad ? AppSpacing.lg : AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                    .fill(Color.crimsonPulse.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                    .stroke(Color.crimsonPulse.opacity(0.2), lineWidth: 1)
            )
        }
        .accessibilityLabel("Reset game scores")
        .accessibilityHint("Clears all saved best scores for games")
    }
}

// MARK: - Octagon Shape

struct OctagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let inset = w * 0.2929 // (1 - 1/√2) ≈ 0.2929 for regular octagon
        var path = Path()
        path.move(to: CGPoint(x: inset, y: 0))
        path.addLine(to: CGPoint(x: w - inset, y: 0))
        path.addLine(to: CGPoint(x: w, y: inset))
        path.addLine(to: CGPoint(x: w, y: h - inset))
        path.addLine(to: CGPoint(x: w - inset, y: h))
        path.addLine(to: CGPoint(x: inset, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - inset))
        path.addLine(to: CGPoint(x: 0, y: inset))
        path.closeSubpath()
        return path
    }
}
