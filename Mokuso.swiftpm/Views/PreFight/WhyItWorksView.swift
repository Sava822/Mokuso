import SwiftUI

struct WhyItWorksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dojoBlack.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.emberGold.opacity(0.06), Color.clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: isIPad ? 500 : 300
                )
                .ignoresSafeArea()

                DojoGrainOverlay()

                ScrollView {
                    VStack(spacing: isIPad ? AppSpacing.xxl : AppSpacing.xl) {
                        headerSection

                        ForEach(OfflineContent.phaseExplanations, id: \.phase) { explanation in
                            phaseRow(explanation)
                        }

                        formulaCard

                        Spacer(minLength: AppSpacing.lg)
                    }
                    .padding(.horizontal, isIPad ? AppSpacing.xxl : AppSpacing.lg)
                    .padding(.vertical, isIPad ? AppSpacing.xl : AppSpacing.lg)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("HOW IT WORKS")
                        .font(.system(size: isIPad ? 14 : 12, weight: .bold, design: .serif))
                        .foregroundStyle(Color.dojoTextSecondary)
                        .tracking(isIPad ? 4 : 2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
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
        VStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
            Text("3 minutes.\n3 phases.\nReady to fight.")
                .font(.system(size: isIPad ? 32 : 24, weight: .bold, design: .serif))
                .foregroundStyle(Color.dojoTextPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(isIPad ? 6 : 4)

            Text("Each phase builds on the last.")
                .font(.system(size: isIPad ? 16 : 13, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.dojoTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isIPad ? AppSpacing.lg : AppSpacing.md)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Phase Row

    private func phaseRow(_ explanation: OfflineContent.PhaseExplanation) -> some View {
        let color = colorForName(explanation.accentColorName)

        return VStack(alignment: .leading, spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
            // Phase header line
            HStack(spacing: isIPad ? AppSpacing.md : AppSpacing.sm) {
                // Number badge
                Text("\(explanation.phase)")
                    .font(.system(size: isIPad ? 16 : 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dojoBlack)
                    .frame(width: isIPad ? 32 : 26, height: isIPad ? 32 : 26)
                    .background(Circle().fill(color))

                Text(explanation.title)
                    .font(.system(size: isIPad ? 20 : 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.dojoTextPrimary)

                Spacer()

                Text(explanation.duration)
                    .font(.system(size: isIPad ? 12 : 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.dojoMuted)
            }

            // Why — one concise paragraph
            Text(explanation.why)
                .font(.system(size: isIPad ? 15 : 13, weight: .regular))
                .foregroundStyle(Color.dojoTextSecondary)
                .lineSpacing(isIPad ? 5 : 3)
                .padding(.leading, isIPad ? 44 : 38)

            // Athlete tip — highlighted
            HStack(alignment: .top, spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
                Image(systemName: "quote.opening")
                    .font(.system(size: isIPad ? 10 : 8))
                    .foregroundStyle(color.opacity(0.5))
                    .padding(.top, 2)

                Text(explanation.athleteTip)
                    .font(.system(size: isIPad ? 13 : 11, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(color.opacity(0.9))
            }
            .padding(.leading, isIPad ? 44 : 38)
        }
        .padding(isIPad ? AppSpacing.xl : AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 16 : 14, style: .continuous)
                .fill(Color.dojoSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 16 : 14, style: .continuous)
                .stroke(color.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Phase \(explanation.phase): \(explanation.title). \(explanation.why). \(explanation.athleteTip)")
    }

    // MARK: - Formula Card

    private var formulaCard: some View {
        VStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            // Visual flow
            HStack(spacing: 0) {
                formulaStep("Calm\nbody", color: .calmTeal, icon: "wind")
                arrow
                formulaStep("Clear\nmind", color: .focusIndigo, icon: "brain.head.profile")
                arrow
                formulaStep("Fight\nready", color: .crimsonPulse, icon: "flame.fill")
            }

            // One-liner
            Text("The order matters. Each phase enables the next.")
                .font(.system(size: isIPad ? 14 : 12, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.dojoTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(isIPad ? AppSpacing.xl : AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 16 : 14, style: .continuous)
                .fill(Color.dojoSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 16 : 14, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The order matters. Calm body, clear mind, fight ready. Each phase enables the next.")
    }

    private func formulaStep(_ text: String, color: Color, icon: String) -> some View {
        VStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: isIPad ? 52 : 40, height: isIPad ? 52 : 40)

                Image(systemName: icon)
                    .font(.system(size: isIPad ? 20 : 15, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.system(size: isIPad ? 12 : 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.dojoTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var arrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: isIPad ? 12 : 10, weight: .bold))
            .foregroundStyle(Color.dojoMuted.opacity(0.4))
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
