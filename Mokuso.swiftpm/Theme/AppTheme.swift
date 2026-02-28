import SwiftUI

// MARK: - Obsidian Dojo Color Palette

extension Color {
    static let dojoBlack = Color(red: 13/255, green: 13/255, blue: 15/255)
    static let dojoSurface = Color(red: 26/255, green: 26/255, blue: 31/255)
    static let dojoElevated = Color(red: 36/255, green: 36/255, blue: 41/255)
    static let dojoMuted = Color(white: 0.4)
    static let dojoTextPrimary = Color.white
    static let dojoTextSecondary = Color(white: 0.7)
    static let dojoTextTertiary = Color(white: 0.45)

    static let emberGold = Color(red: 232/255, green: 168/255, blue: 56/255)
    static let emberLight = Color(red: 245/255, green: 196/255, blue: 66/255)
    static let calmTeal = Color(red: 72/255, green: 202/255, blue: 189/255)
    static let crimsonPulse = Color(red: 220/255, green: 60/255, blue: 60/255)
    static let focusIndigo = Color(red: 108/255, green: 92/255, blue: 231/255)
    static let softGreen = Color(red: 72/255, green: 199/255, blue: 116/255)
}

// MARK: - Spacing System

enum AppSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius System

enum AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - App Gradient Background

struct AppGradientBackground: View {
    var accentColor: Color = .emberGold
    var opacity: Double = 0.06

    var body: some View {
        ZStack {
            Color.dojoBlack
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    accentColor.opacity(opacity),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()

            DojoGrainOverlay()
        }
    }
}

// MARK: - Grain Overlay

struct DojoGrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<800 {
                let x = Double.random(in: 0...size.width)
                let y = Double.random(in: 0...size.height)
                let dotSize = Double.random(in: 0.5...1.5)
                let opacity = Double.random(in: 0.02...0.06)

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                    with: .color(Color.white.opacity(opacity))
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - App Glow Modifier

struct AppGlowModifier: ViewModifier {
    let color: Color
    var radius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 0.6)
    }
}

extension View {
    func appGlow(_ color: Color, radius: CGFloat = 20) -> some View {
        modifier(AppGlowModifier(color: color, radius: radius))
    }
}

// MARK: - Dojo Card Style

struct DojoCardModifier: ViewModifier {
    var padding: CGFloat = AppSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.dojoSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )
    }
}

extension View {
    func dojoCard(padding: CGFloat = AppSpacing.lg) -> some View {
        modifier(DojoCardModifier(padding: padding))
    }
}

// MARK: - Phase Accent Colors

enum PhaseAccent {
    static func color(for phase: String) -> Color {
        switch phase {
        case "breathing": return .calmTeal
        case "focus": return .focusIndigo
        case "activate": return .crimsonPulse
        case "done": return .softGreen
        default: return .emberGold
        }
    }
}

// MARK: - Typography Helpers

extension Font {
    static func dojoTitle(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func dojoHeading(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func dojoBody(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func dojoCaption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func dojoMono(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Staggered Fade-In Modifier

struct StaggeredFadeIn: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .task {
                try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
                withAnimation(.easeOut(duration: 0.5)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredFadeIn(delay: Double) -> some View {
        modifier(StaggeredFadeIn(delay: delay))
    }
}

// MARK: - Floating Embers Particle Effect

struct FloatingEmbers: View {
    var color: Color = .emberGold
    var count: Int = 20
    var speed: CGFloat = 1.0

    @State private var seeds: [EmberSeed] = []

    private struct EmberSeed {
        let xBase: CGFloat
        let drift: CGFloat
        let driftSpeed: CGFloat
        let size: CGFloat
        let speedFactor: CGFloat
        let phase: CGFloat
        let maxOpacity: Double
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for seed in seeds {
                    let cycle = Double(size.height) / (Double(seed.speedFactor * speed) * 18.0)
                    let t = ((now + Double(seed.phase)) / cycle)
                        .truncatingRemainder(dividingBy: 1.0)
                    let y = size.height * (1.0 - CGFloat(t))
                    let x = seed.xBase * size.width
                        + sin(now * Double(seed.driftSpeed) + Double(seed.phase)) * seed.drift

                    let opacity: Double
                    if t < 0.15 {
                        opacity = (t / 0.15) * seed.maxOpacity
                    } else if t > 0.85 {
                        opacity = ((1.0 - t) / 0.15) * seed.maxOpacity
                    } else {
                        opacity = seed.maxOpacity
                    }

                    let rect = CGRect(
                        x: x - seed.size / 2,
                        y: y - seed.size / 2,
                        width: seed.size,
                        height: seed.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(opacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .task {
            seeds = (0..<count).map { _ in
                EmberSeed(
                    xBase: .random(in: 0.1...0.9),
                    drift: .random(in: 8...25),
                    driftSpeed: .random(in: 0.3...0.8),
                    size: .random(in: 2...5),
                    speedFactor: .random(in: 0.4...1.3),
                    phase: .random(in: 0...200),
                    maxOpacity: .random(in: 0.12...0.4)
                )
            }
        }
    }
}

// MARK: - Shimmer Text Modifier

struct ShimmerModifier: ViewModifier {
    let color: Color
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        let s1 = max(0, min(1, phase - 0.15))
        let s2 = max(s1, min(1, phase))
        let s3 = max(s2, min(1, phase + 0.15))

        content
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: s1),
                        .init(color: color.opacity(0.35), location: s2),
                        .init(color: .clear, location: s3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(content)
            )
            .task {
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    func shimmer(_ color: Color = .white) -> some View {
        modifier(ShimmerModifier(color: color))
    }
}
