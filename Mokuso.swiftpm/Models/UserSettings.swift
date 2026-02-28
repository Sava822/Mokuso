import SwiftUI
import SwiftData

// MARK: - Enums

enum CompetitionLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case elite = "Elite"
}

enum PreFightGame: String, Codable, CaseIterable, Identifiable {
    case numberOrder = "Number Order"
    case reactionTap = "Reaction Tap"
    case patternRecall = "Pattern Recall"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .numberOrder: return "number.square"
        case .reactionTap: return "bolt.circle"
        case .patternRecall: return "square.grid.3x3"
        }
    }

    var description: String {
        switch self {
        case .numberOrder: return "Tap numbers 1–25 in order"
        case .reactionTap: return "F1-style lights out reaction test"
        case .patternRecall: return "Memorize and repeat patterns"
        }
    }

    var shortName: String {
        switch self {
        case .numberOrder: return "Numbers"
        case .reactionTap: return "Reaction"
        case .patternRecall: return "Pattern"
        }
    }

    var previewDescription: String {
        switch self {
        case .numberOrder: return "A 5×5 grid of numbers appears randomly. Tap them in ascending order from 1 to 25 as fast as you can. Keeps your mind locked in."
        case .reactionTap: return "Watch for circles to light up on screen. Tap them the instant they appear to sharpen your reaction speed."
        case .patternRecall: return "Watch a pattern flash on a 3×3 grid, then repeat it from memory. Pattern length increases each round."
        }
    }
}


enum RoutineType: String, Codable {
    case preFight = "Pre-Fight Flow"
    case breathing = "Breathing"
    case focusGame = "Focus Game"
}

enum RitualPhase: String, Codable, CaseIterable, Identifiable {
    case breathe
    case focus
    case activate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breathe: return "Breathe & Settle"
        case .focus: return "Sharpen & Focus"
        case .activate: return "Activate"
        }
    }

    var subtitle: String {
        switch self {
        case .breathe: return "Box breathing to calm your nervous system"
        case .focus: return "A cognitive game to break overthinking"
        case .activate: return "Build from calm focus to fight-ready intensity"
        }
    }

    var icon: String {
        switch self {
        case .breathe: return "wind"
        case .focus: return "brain.head.profile"
        case .activate: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .breathe: return .calmTeal
        case .focus: return .focusIndigo
        case .activate: return .crimsonPulse
        }
    }

    var duration: String {
        switch self {
        case .breathe: return "~48s"
        case .focus: return "~55s"
        case .activate: return "~55s"
        }
    }

    var shortName: String {
        switch self {
        case .breathe: return "Breathe"
        case .focus: return "Focus"
        case .activate: return "Activate"
        }
    }
}

// MARK: - UserSettings Model

@Model
final class UserSettings {
    var id: UUID
    var hasCompletedOnboarding: Bool
    var sport: String
    var competitionLevelRaw: String
    var preferredPreFightGameRaw: String?
    var phaseOrderRaw: String

    var competitionLevel: CompetitionLevel {
        get { CompetitionLevel(rawValue: competitionLevelRaw) ?? .beginner }
        set { competitionLevelRaw = newValue.rawValue }
    }

    var preferredPreFightGame: PreFightGame? {
        get {
            guard let raw = preferredPreFightGameRaw else { return nil }
            return PreFightGame(rawValue: raw)
        }
        set { preferredPreFightGameRaw = newValue?.rawValue }
    }

    var phaseOrder: [RitualPhase] {
        get {
            let raw = phaseOrderRaw.split(separator: ",").compactMap { RitualPhase(rawValue: String($0)) }
            return raw.count == 3 ? raw : [.breathe, .focus, .activate]
        }
        set {
            phaseOrderRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        sport: String = "Judo",
        competitionLevel: CompetitionLevel = .beginner,
        preferredPreFightGame: PreFightGame? = .reactionTap,
        phaseOrderRaw: String = "breathe,focus,activate"
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.sport = sport
        self.competitionLevelRaw = competitionLevel.rawValue
        self.preferredPreFightGameRaw = preferredPreFightGame?.rawValue
        self.phaseOrderRaw = phaseOrderRaw
    }
}

// MARK: - StreakData Model

@Model
final class StreakData {
    var currentStreak: Int
    var longestStreak: Int
    var totalSessions: Int
    var totalMinutes: Int
    var lastActiveDate: Date?

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalSessions: Int = 0,
        totalMinutes: Int = 0,
        lastActiveDate: Date? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalSessions = totalSessions
        self.totalMinutes = totalMinutes
        self.lastActiveDate = lastActiveDate
    }

    func recordActivity(minutes: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        totalSessions += 1
        totalMinutes += minutes

        if let last = lastActiveDate {
            let lastDay = calendar.startOfDay(for: last)
            let dayDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if dayDiff == 1 {
                currentStreak += 1
            } else if dayDiff > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastActiveDate = today
    }
}

// MARK: - ActivityLog Model

@Model
final class ActivityLog {
    var id: UUID
    var routineTypeRaw: String
    var durationMinutes: Int
    var notes: String
    var date: Date

    var routineType: RoutineType {
        get { RoutineType(rawValue: routineTypeRaw) ?? .preFight }
        set { routineTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        routineType: RoutineType = .preFight,
        durationMinutes: Int = 3,
        notes: String = "",
        date: Date = Date()
    ) {
        self.id = id
        self.routineTypeRaw = routineType.rawValue
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.date = date
    }
}
