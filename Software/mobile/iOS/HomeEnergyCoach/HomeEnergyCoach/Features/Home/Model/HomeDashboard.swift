import Foundation

/// Everything the Home screen shows (Figma `v4 01 Home`).
struct HomeDashboard: Equatable, Sendable {
    struct GreenWindow: Equatable, Sendable {
        /// Local time the window ends, e.g. "15:00".
        let endsAt: String
        let habitCode: String
        let habitShortName: String
    }

    struct HabitProgress: Equatable, Sendable {
        let code: String
        let title: String
        let day: Int
        /// Habit automaticity, 0…1.
        let automaticity: Double
        let typicalDays: Int
    }

    struct NextHabit: Equatable, Sendable {
        let code: String
        let shortName: String
        let reason: String
    }

    let userName: String
    let wgName: String
    /// CO₂ change this week in kg (negative = saved).
    let weeklyChangeKg: Double
    /// Change vs. last week, e.g. 0.18 for +18%.
    let improvementVsLastWeek: Double
    /// Daily footprint, Monday first (7 values).
    let dailyKg: [Double]
    let greenWindow: GreenWindow?
    let habitInProgress: HabitProgress?
    let nextHabit: NextHabit?
}

protocol HomeDashboardProviding: Sendable {
    func dashboard(userName: String?) -> HomeDashboard
}

/// Placeholder data matching the Figma sample.
///
/// TODO: Replace with the dashboard API (SMARD green windows, habit tracking).
struct StubHomeDashboardProvider: HomeDashboardProviding {
    func dashboard(userName: String?) -> HomeDashboard {
        HomeDashboard(
            userName: userName?.trimmingCharacters(in: .whitespaces).nonEmpty ?? "Lena",
            wgName: "Sonnenhof",
            weeklyChangeKg: -4.1,
            improvementVsLastWeek: 0.18,
            dailyKg: [1.8, 3.1, 2.2, 4.0, 2.6, 4.4, 1.3],
            greenWindow: .init(endsAt: "15:00", habitCode: "H01", habitShortName: String(localized: "laundry", comment: "Habit H01 short name")),
            habitInProgress: .init(
                code: "H01",
                title: String(localized: "Run laundry in green hours", comment: "Habit H01"),
                day: 23,
                automaticity: 0.35,
                typicalDays: 66
            ),
            nextHabit: .init(
                code: "H07",
                shortName: String(localized: "Stoßlüften", comment: "Habit H07 short name"),
                reason: String(localized: "4 of 5 similar users kept it", comment: "Habit H07 reason")
            )
        )
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
