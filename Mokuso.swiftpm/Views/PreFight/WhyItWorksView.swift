import SwiftUI

struct WhyItWorksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    private var iPadColumns: [GridItem] {
        [GridItem(.flexible(), spacing: AppSpacing.lg),
         GridItem(.flexible(), spacing: AppSpacing.lg)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dojoBlack.ignoresSafeArea()
                DojoGrainOverlay()

                ScrollView {
                    VStack(spacing: isIPad ? AppSpacing.xxl : AppSpacing.xl) {
                        // Header
                        headerSection

                        if isIPad {
                            // iPad: 2-column grid for phase cards
                            LazyVGrid(columns: iPadColumns, spacing: AppSpacing.lg) {
                                ForEach(OfflineContent.phaseExplanations, id: \.phase) { explanation in
                                    phaseCard(explanation)
                                }
                            }
                        } else {
                            // iPhone: vertical stack
                            ForEach(OfflineContent.phaseExplanations, id: \.phase) { explanation in
                                phaseCard(explanation)
                            }
                        }

                        // Summary card
                        summaryCard

                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, isIPad ? AppSpacing.xxl : AppSpacing.lg)
                    .padding(.vertical, isIPad ? AppSpacing.xl : AppSpacing.lg)
                }
            }
            .navigationTitle("Why This Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.emberGold)
                        .accessibilityLabel("Close")
                }
            }
            .toolbarBackground(Color.dojoBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            Image(systemName: "brain")
                .font(.system(size: isIPad ? 64 : 44, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.emberGold, .calmTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            Text("Why This Works")
                .font(.dojoTitle(isIPad ? 40 : 28))
                .foregroundStyle(Color.dojoTextPrimary)

            Text("The science behind your 3-minute ritual")
                .font(.dojoBody(isIPad ? 20 : 15))
                .foregroundStyle(Color.dojoTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, isIPad ? AppSpacing.lg : AppSpacing.md)
        .padding(.bottom, isIPad ? AppSpacing.sm : 0)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Why this works. The science behind your 3-minute ritual.")
    }

    // MARK: - Phase Card

    private func phaseCard(_ explanation: OfflineContent.PhaseExplanation) -> some View {
        let accentColor = colorForName(explanation.accentColorName)

        return VStack(alignment: .leading, spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            // Phase header
            HStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: isIPad ? 52 : 40, height: isIPad ? 52 : 40)

                    Text("\(explanation.phase)")
                        .font(.dojoHeading(isIPad ? 22 : 18))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(explanation.title)
                        .font(.dojoHeading(isIPad ? 22 : 18))
                        .foregroundStyle(Color.dojoTextPrimary)

                    Text(explanation.duration)
                        .font(.dojoCaption(isIPad ? 14 : 12))
                        .foregroundStyle(Color.dojoTextTertiary)
                }

                Spacer()

                Image(systemName: explanation.icon)
                    .font(isIPad ? .title2 : .title3)
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)
            }

            // Why section
            VStack(alignment: .leading, spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                Text("Why")
                    .font(.dojoCaption(isIPad ? 15 : 13))
                    .foregroundStyle(accentColor)
                    .tracking(1)

                Text(explanation.why)
                    .font(.dojoBody(isIPad ? 17 : 14))
                    .foregroundStyle(Color.dojoTextSecondary)
                    .lineSpacing(isIPad ? 6 : 4)
            }

            // Science reference
            HStack(alignment: .top, spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                Image(systemName: "book.closed")
                    .font(isIPad ? .footnote : .caption)
                    .foregroundStyle(Color.dojoTextTertiary)
                    .accessibilityHidden(true)

                Text(explanation.scienceRef)
                    .font(.dojoCaption(isIPad ? 13 : 11))
                    .foregroundStyle(Color.dojoTextTertiary)
                    .italic()
            }

            // Athlete tip
            HStack(alignment: .top, spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                Image(systemName: "lightbulb")
                    .font(isIPad ? .footnote : .caption)
                    .foregroundStyle(Color.emberGold)
                    .accessibilityHidden(true)

                Text(explanation.athleteTip)
                    .font(.dojoCaption(isIPad ? 15 : 13))
                    .foregroundStyle(Color.dojoTextSecondary)
            }
            .padding(isIPad ? AppSpacing.md : AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                    .fill(Color.emberGold.opacity(0.06))
            )
        }
        .dojoCard(padding: isIPad ? AppSpacing.xl : AppSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Phase \(explanation.phase): \(explanation.title). \(explanation.why). Tip: \(explanation.athleteTip)")
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: isIPad ? AppSpacing.xl : AppSpacing.md) {
            HStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(isIPad ? .title2 : .body)
                    .foregroundStyle(Color.emberGold)
                    .accessibilityHidden(true)

                Text("The 3-Minute Formula")
                    .font(.dojoHeading(isIPad ? 26 : 18))
                    .foregroundStyle(Color.dojoTextPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Visual formula
            HStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.sm) {
                formulaStep("Calm\nbody", color: .calmTeal)
                Image(systemName: "chevron.right")
                    .font(isIPad ? .body : .caption)
                    .foregroundStyle(Color.dojoMuted)
                formulaStep("Clear\nmind", color: .focusIndigo)
                Image(systemName: "chevron.right")
                    .font(isIPad ? .body : .caption)
                    .foregroundStyle(Color.dojoMuted)
                formulaStep("Prime\nactions", color: .crimsonPulse)
            }
            .frame(maxWidth: isIPad ? 500 : .infinity)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isIPad ? AppSpacing.md : 0)

            Text(OfflineContent.formulaSummary)
                .font(.dojoBody(isIPad ? 18 : 14))
                .foregroundStyle(Color.dojoTextSecondary)
                .lineSpacing(isIPad ? 7 : 4)
        }
        .dojoCard(padding: isIPad ? AppSpacing.xl : AppSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The 3-minute formula. \(OfflineContent.formulaSummary)")
    }

    private func formulaStep(_ text: String, color: Color) -> some View {
        VStack(spacing: isIPad ? AppSpacing.md : AppSpacing.xs) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: isIPad ? 56 : 36, height: isIPad ? 56 : 36)
                .overlay(
                    Circle()
                        .fill(color)
                        .frame(width: isIPad ? 18 : 12, height: isIPad ? 18 : 12)
                )

            Text(text)
                .font(.dojoCaption(isIPad ? 15 : 11))
                .foregroundStyle(Color.dojoTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Color Helper

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "calmTeal": return .calmTeal
        case "focusIndigo": return .focusIndigo
        case "crimsonPulse": return .crimsonPulse
        default: return .emberGold
        }
    }
}
