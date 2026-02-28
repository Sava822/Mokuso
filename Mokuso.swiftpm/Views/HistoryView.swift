import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ActivityLog.date, order: .reverse) private var logs: [ActivityLog]
    @Query private var streakData: [StreakData]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    @State private var selectedMonth: Date = Date()

    private var calendar: Calendar { Calendar.current }

    // MARK: - Computed Stats

    private var totalSessions: Int { logs.count }

    private var totalMinutes: Int { logs.reduce(0) { $0 + $1.durationMinutes } }

    private var thisMonthSessions: Int {
        let comps = calendar.dateComponents([.year, .month], from: Date())
        let start = calendar.date(from: comps)!
        return logs.filter { $0.date >= start }.count
    }

    private var activeDaysCount: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Set(logs.map { formatter.string(from: $0.date) }).count
    }

    private var activeDaysSet: Set<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Set(logs.map { formatter.string(from: $0.date) })
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dojoBlack.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.emberGold.opacity(0.08), Color.clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: isIPad ? 500 : 300
                )
                .ignoresSafeArea()

                DojoGrainOverlay()

                FloatingEmbers(
                    color: .emberGold,
                    count: isIPad ? 20 : 10,
                    speed: 0.4
                )

                ScrollView {
                    VStack(spacing: isIPad ? AppSpacing.xl : AppSpacing.lg) {
                        heroHeader
                        statsRow
                        calendarSection
                        recentActivity
                    }
                    .padding(.horizontal, isIPad ? AppSpacing.xxl : AppSpacing.lg)
                    .padding(.top, isIPad ? AppSpacing.xl : AppSpacing.lg)
                    .padding(.bottom, isIPad ? AppSpacing.xxl : AppSpacing.xl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROGRESS")
                        .font(.system(size: isIPad ? 16 : 13, weight: .bold, design: .serif))
                        .foregroundStyle(Color.dojoTextSecondary)
                        .tracking(isIPad ? 6 : 3)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                        .foregroundStyle(Color.emberGold)
                }
            }
            .toolbarBackground(Color.dojoBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.emberGold.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: isIPad ? 80 : 55
                        )
                    )
                    .frame(width: isIPad ? 160 : 110, height: isIPad ? 160 : 110)

                Circle()
                    .stroke(Color.emberGold.opacity(0.25), lineWidth: isIPad ? 2 : 1.5)
                    .frame(width: isIPad ? 120 : 85, height: isIPad ? 120 : 85)

                VStack(spacing: 2) {
                    Text("\(totalSessions)")
                        .font(.system(size: isIPad ? 48 : 36, weight: .black, design: .serif))
                        .foregroundStyle(Color.dojoTextPrimary)

                    Text(totalSessions == 1 ? "RITUAL" : "RITUALS")
                        .font(.system(size: isIPad ? 11 : 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.emberGold.opacity(0.7))
                        .tracking(isIPad ? 3 : 2)
                }
            }
            .shadow(color: Color.emberGold.opacity(0.2), radius: 20)

            Text("\(totalMinutes) minutes of mental preparation")
                .font(.system(size: isIPad ? 15 : 12, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.dojoTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isIPad ? AppSpacing.lg : AppSpacing.md)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            miniStat(
                value: "\(thisMonthSessions)",
                label: "This Month",
                color: .calmTeal
            )
            miniStat(
                value: "\(activeDaysCount)",
                label: "Active Days",
                color: .focusIndigo
            )
            miniStat(
                value: "\(totalMinutes)m",
                label: "Total Time",
                color: .emberGold
            )
        }
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
            Text(value)
                .font(.system(size: isIPad ? 28 : 22, weight: .bold, design: .serif))
                .foregroundStyle(Color.dojoTextPrimary)

            Text(label.uppercased())
                .font(.system(size: isIPad ? 10 : 8, weight: .semibold, design: .rounded))
                .foregroundStyle(color.opacity(0.8))
                .tracking(isIPad ? 1.5 : 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isIPad ? AppSpacing.lg : AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                .fill(Color.dojoSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            HStack {
                Text("COMPETITION LOG")
                    .font(.system(size: isIPad ? 12 : 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.calmTeal.opacity(0.7))
                    .tracking(isIPad ? 3 : 2)

                Spacer()

                HStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: isIPad ? 14 : 12, weight: .bold))
                            .foregroundStyle(Color.dojoTextTertiary)
                    }
                    .accessibilityLabel("Previous month")

                    Text(monthYearString(selectedMonth))
                        .font(.system(size: isIPad ? 15 : 13, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.dojoTextPrimary)
                        .frame(minWidth: isIPad ? 150 : 110)

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 14 : 12, weight: .bold))
                            .foregroundStyle(Color.dojoTextTertiary)
                    }
                    .accessibilityLabel("Next month")
                }
            }

            calendarGrid
        }
        .padding(isIPad ? AppSpacing.xl : AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .fill(Color.dojoSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
    }

    private var calendarGrid: some View {
        let daysInMonth = daysForMonth(selectedMonth)
        let firstWeekday = firstWeekdayOfMonth(selectedMonth)
        let totalCells = firstWeekday + daysInMonth
        let rows = (totalCells + 6) / 7
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        return VStack(spacing: isIPad ? AppSpacing.sm : AppSpacing.xs) {
            // Weekday header
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdayLabels[i])
                        .font(.system(size: isIPad ? 11 : 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.dojoMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, isIPad ? AppSpacing.xs : 4)
                }
            }

            // Day rows
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        let day = index - firstWeekday + 1

                        if day >= 1 && day <= daysInMonth {
                            let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
                            let date = calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: day))!
                            let dateStr = formatter.string(from: date)
                            let isActive = activeDaysSet.contains(dateStr)
                            let isToday = calendar.isDateInToday(date)

                            ZStack {
                                if isActive {
                                    Circle()
                                        .fill(Color.emberGold.opacity(0.2))
                                        .shadow(color: Color.emberGold.opacity(0.2), radius: 6)
                                        .padding(isIPad ? 4 : 3)
                                } else if isToday {
                                    Circle()
                                        .stroke(Color.emberGold.opacity(0.5), lineWidth: isIPad ? 1.5 : 1)
                                        .padding(isIPad ? 4 : 3)
                                }

                                Text("\(day)")
                                    .font(.system(size: isIPad ? 15 : 14, weight: isActive ? .bold : .regular, design: .rounded))
                                    .foregroundStyle(isActive ? Color.emberLight : (isToday ? Color.emberGold : Color.dojoTextSecondary))
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            Text("RECENT SESSIONS")
                .font(.system(size: isIPad ? 12 : 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.focusIndigo.opacity(0.7))
                .tracking(isIPad ? 3 : 2)

            if logs.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "figure.martial.arts")
                        .font(.system(size: isIPad ? 36 : 28))
                        .foregroundStyle(Color.dojoMuted.opacity(0.5))
                        .accessibilityHidden(true)
                    Text("No sessions yet")
                        .font(.system(size: isIPad ? 15 : 13, weight: .medium, design: .serif))
                        .foregroundStyle(Color.dojoTextTertiary)
                    Text("Complete your first ritual to start tracking")
                        .font(.system(size: isIPad ? 12 : 10, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.dojoMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIPad ? AppSpacing.xxl : AppSpacing.xl)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(logs.prefix(10).enumerated()), id: \.element.id) { index, log in
                        logRow(log)
                        if index < min(logs.count, 10) - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.03))
                                .frame(height: 1)
                                .padding(.leading, isIPad ? 56 : 44)
                        }
                    }
                }
            }
        }
        .padding(isIPad ? AppSpacing.xl : AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .fill(Color.dojoSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
    }

    private func logRow(_ log: ActivityLog) -> some View {
        HStack(spacing: isIPad ? AppSpacing.lg : AppSpacing.md) {
            RoundedRectangle(cornerRadius: isIPad ? 10 : 8, style: .continuous)
                .fill(Color.emberGold.opacity(0.1))
                .frame(width: isIPad ? 40 : 32, height: isIPad ? 40 : 32)
                .overlay(
                    Image(systemName: "figure.martial.arts")
                        .font(.system(size: isIPad ? 16 : 13, weight: .medium))
                        .foregroundStyle(Color.emberGold.opacity(0.8))
                        .accessibilityHidden(true)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(log.routineType.rawValue)
                    .font(.system(size: isIPad ? 15 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.dojoTextPrimary)
                if !log.notes.isEmpty && log.notes != "Pre-Fight Flow" {
                    Text(log.notes)
                        .font(.system(size: isIPad ? 12 : 10, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(Color.calmTeal.opacity(0.8))
                        .lineLimit(1)
                }
                Text(relativeDateString(log.date))
                    .font(.system(size: isIPad ? 11 : 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.dojoMuted)
            }

            Spacer()

            Text("\(log.durationMinutes)m")
                .font(.system(size: isIPad ? 14 : 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.dojoTextTertiary)
        }
        .padding(.vertical, isIPad ? AppSpacing.md : AppSpacing.sm)
    }

    // MARK: - Helpers

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func daysForMonth(_ date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)!.count
    }

    private func firstWeekdayOfMonth(_ date: Date) -> Int {
        let comps = calendar.dateComponents([.year, .month], from: date)
        let first = calendar.date(from: comps)!
        let weekday = calendar.component(.weekday, from: first)
        // Convert to Monday=0 based
        return (weekday + 5) % 7
    }

    private func relativeDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
