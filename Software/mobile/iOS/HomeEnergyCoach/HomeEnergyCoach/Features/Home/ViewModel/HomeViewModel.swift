import Foundation

/// Formats `HomeDashboard` for display.
@MainActor
final class HomeViewModel {
    let dashboard: HomeDashboard
    private let now: Date
    private let calendar: Calendar
    private let locale: Locale

    init(dashboard: HomeDashboard, now: Date = .now, calendar: Calendar = .current, locale: Locale = .current) {
        self.dashboard = dashboard
        self.now = now
        self.calendar = calendar
        self.locale = locale
    }

    /// e.g. "Monday, 23 November" (locale-dependent order).
    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: now)
    }

    var greeting: String { String(localized: "Hi \(dashboard.userName)", comment: "Home greeting") }

    var avatarInitial: String { dashboard.userName.first.map { String($0).uppercased() } ?? "" }

    var weekTitle: String {
        String(localized: "This week · WG \(dashboard.wgName)", comment: "Weekly card title")
    }

    /// e.g. "−4.1" with a typographic minus.
    var weeklyChangeText: String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.minusSign = "−"
        return formatter.string(from: NSNumber(value: dashboard.weeklyChangeKg)) ?? ""
    }

    /// e.g. "+18% vs last week".
    var trendText: String {
        let percent = Int((dashboard.improvementVsLastWeek * 100).rounded())
        let sign = percent >= 0 ? "+" : "−"
        return String(localized: "\(sign)\(abs(percent))% vs last week", comment: "Weekly trend tag")
    }

    /// Short weekday names, Monday first.
    var dayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        let symbols = formatter.shortWeekdaySymbols ?? []
        guard symbols.count == 7 else { return [] }
        return Array(symbols[1...] + symbols[..<1]) // Sunday-first → Monday-first
    }

    /// Bar heights relative to the busiest day (0…1).
    var barFractions: [Double] {
        let peak = dashboard.dailyKg.max() ?? 0
        guard peak > 0 else { return dashboard.dailyKg.map { _ in 0 } }
        return dashboard.dailyKg.map { $0 / peak }
    }

    /// Monday = 0 … Sunday = 6.
    var todayIndex: Int {
        (calendar.component(.weekday, from: now) + 5) % 7
    }

    var greenWindowTitle: String? {
        dashboard.greenWindow.map { String(localized: "Green window until \($0.endsAt)", comment: "Green window card title") }
    }

    var greenWindowSubtitle: String? {
        dashboard.greenWindow.map {
            String(localized: "Good time for \($0.habitCode) · \($0.habitShortName)", comment: "Green window card subtitle")
        }
    }

    var habitStatusText: String? {
        dashboard.habitInProgress.map {
            let percent = Int(($0.automaticity * 100).rounded())
            return String(localized: "Day \($0.day) · \(percent)% automatic", comment: "Habit progress status")
        }
    }

    var habitTypicalText: String? {
        dashboard.habitInProgress.map { String(localized: "~\($0.typicalDays) days typical", comment: "Habit typical duration") }
    }

    var nextHabitTitle: String? {
        dashboard.nextHabit.map { "\($0.code) · \($0.shortName)" }
    }
}
