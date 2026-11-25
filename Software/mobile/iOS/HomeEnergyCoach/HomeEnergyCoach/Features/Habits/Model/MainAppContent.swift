import Foundation

// Sample content for the main-app screens, mirroring the Figma `v4 · 2 · Main app` frames.
// TODO: Replace each `.sample` with data from the backend (R models, SMARD, check-ins).

// MARK: - 02 Plan

struct PlanRecommendation: Equatable, Sendable {
    let code: String
    let categoryLine: String
    let title: String
    let reasons: [String]
    let impact: String
    let impactLevel: Int
    let effort: String
    let timing: String
}

struct HabitSuggestion: Equatable, Sendable {
    let code: String
    let title: String
    let detail: String
    let fit: Int
}

struct PlanTabContent: Equatable, Sendable {
    let next: PlanRecommendation
    let alternatives: [HabitSuggestion]

    static let sample = PlanTabContent(
        next: PlanRecommendation(
            code: "H07",
            categoryLine: String(localized: "Reduction · heating", comment: "Habit category line"),
            title: String(localized: "Stoßlüften instead of a tilted window", comment: "Habit H07 long title"),
            reasons: [
                String(localized: "Your WG is heating-heavy", comment: "Recommendation reason"),
                String(localized: "4 of 5 similar users kept it", comment: "Recommendation reason"),
                String(localized: "Pairs with H05 · thermostat −1°C", comment: "Recommendation reason"),
            ],
            impact: String(localized: "High", comment: "Impact level"),
            impactLevel: 3,
            effort: String(localized: "Low", comment: "Effort level"),
            timing: String(localized: "Airing times", comment: "When to do the habit")
        ),
        alternatives: [
            HabitSuggestion(code: "H09", title: String(localized: "Shorter showers", comment: "Habit H09"),
                            detail: String(localized: "Reduction · hot water", comment: "Habit category line"), fit: 2),
            HabitSuggestion(code: "H12", title: String(localized: "Wash at 30°C, full loads", comment: "Habit H12"),
                            detail: String(localized: "Pairs with H01", comment: "Habit pairing"), fit: 1),
            HabitSuggestion(code: "H14", title: String(localized: "Power strips off at night", comment: "Habit H14"),
                            detail: String(localized: "Reduction · electronics", comment: "Habit category line"), fit: 1),
        ]
    )
}

// MARK: - 03 Habit

enum CheckInState: Equatable, Sendable {
    case none
    /// Done in a green hour.
    case done
    /// Done, but outside a green hour.
    case partial
}

struct ReminderStage: Equatable, Sendable {
    let frequency: String
    let period: String
    let level: Int
    let isCurrent: Bool
}

struct HabitDetail: Equatable, Sendable {
    let code: String
    let categoryLine: String
    let title: String
    let automaticity: Double
    let day: Int
    let typicalDays: Int
    /// Four weeks × seven days (Monday first); the last row is the current week.
    var checkIns: [[CheckInState]]
    let reminderStages: [ReminderStage]
    let before: Double
    let after: Double
    let metric: String

    static let sample = HabitDetail(
        code: "H01",
        categoryLine: String(localized: "Timing · laundry", comment: "Habit category line"),
        title: String(localized: "Run laundry in green hours", comment: "Habit H01"),
        automaticity: 0.35,
        day: 23,
        typicalDays: 66,
        checkIns: [
            [.none, .none, .none, .none, .none, .done, .none],
            [.none, .none, .none, .none, .none, .done, .none],
            [.none, .partial, .none, .none, .none, .done, .none],
            [.none, .none, .none, .none, .none, .done, .none],
        ],
        reminderStages: [
            ReminderStage(frequency: String(localized: "3 / week", comment: "Reminder frequency"),
                          period: String(localized: "Weeks 1–2", comment: "Reminder period"), level: 3, isCurrent: false),
            ReminderStage(frequency: String(localized: "1 / week", comment: "Reminder frequency"),
                          period: String(localized: "Now", comment: "Reminder period"), level: 1, isCurrent: true),
            ReminderStage(frequency: String(localized: "none", comment: "Reminder frequency"),
                          period: String(localized: "Soon", comment: "Reminder period"), level: 0, isCurrent: false),
        ],
        before: 0.20,
        after: 0.75,
        metric: String(localized: "loads in green hours", comment: "Habit effectiveness metric")
    )
}

// MARK: - 04 Green Hours

struct TimingSuggestion: Equatable, Sendable {
    let code: String
    let title: String
    let detail: String
    let time: String
}

struct GreenHoursForecast: Equatable, Sendable {
    /// Grid intensity per hour (g CO₂/kWh), 00–23.
    let gramsPerKWh: [Int]
    /// Hours the user is usually home.
    let homeHours: Set<Int>
    let window: Range<Int>
    let dayLabel: String
    let suggestions: [TimingSuggestion]

    static let sample = GreenHoursForecast(
        gramsPerKWh: [379, 369, 359, 355, 352, 359, 379, 400, 359, 300, 252, 210, 190, 179, 190, 221, 269, 331, 300, 252, 241, 259, 321, 352],
        homeHours: Set(0...7).union(18...23),
        window: 12..<15,
        dayLabel: String(localized: "Tomorrow · Tue 24 Nov · SMARD forecast", comment: "Forecast day label"),
        suggestions: [
            TimingSuggestion(code: "H01", title: String(localized: "Laundry", comment: "Timing habit"),
                             detail: String(localized: "Saturday, you're home", comment: "Timing habit detail"), time: "12:00"),
            TimingSuggestion(code: "H02", title: String(localized: "Dishwasher", comment: "Timing habit"),
                             detail: String(localized: "Set the delay timer tonight", comment: "Timing habit detail"), time: "13:00"),
            TimingSuggestion(code: "H03", title: String(localized: "Charge laptop & e-bike", comment: "Timing habit"),
                             detail: String(localized: "Plug in during the window", comment: "Timing habit detail"), time: "12–15"),
            TimingSuggestion(code: "H04", title: String(localized: "Batch cooking", comment: "Timing habit"),
                             detail: String(localized: "Sunday lunch", comment: "Timing habit detail"), time: "13:00"),
        ]
    )
}

// MARK: - 06 Quick wins

struct QuickWin: Equatable, Sendable {
    let code: String
    let title: String
    /// Short rationale; `nil` when the design gives none.
    let detail: String?
    var isDone: Bool
    var doneDetail: String?
    var badge: String?
    /// Opens the WG tab instead of toggling (H22 agreement).
    var opensWG = false

    static let sample: [QuickWin] = [
        QuickWin(code: "H21", title: String(localized: "Choose a green electricity tariff", comment: "Habit H21"),
                 detail: String(localized: "One decision, big impact", comment: "Quick win detail"), isDone: false,
                 badge: String(localized: "Biggest impact", comment: "Quick win badge")),
        QuickWin(code: "H22", title: String(localized: "Agree on a WG energy agreement", comment: "Habit H22"),
                 detail: String(localized: "Makes habits shared", comment: "Quick win detail"), isDone: false, opensWG: true),
        QuickWin(code: "H18", title: String(localized: "Smart power strip or timer plug", comment: "Habit H18"),
                 detail: String(localized: "Automates the standby habit", comment: "Quick win detail"), isDone: false),
        QuickWin(code: "H19", title: String(localized: "Check the fridge seals", comment: "Habit H19"),
                 detail: String(localized: "Leaky seals waste cooling", comment: "Quick win detail"), isDone: false),
        QuickWin(code: "H17", title: String(localized: "Swap remaining bulbs for LEDs", comment: "Habit H17"),
                 detail: nil, isDone: true,
                 doneDetail: String(localized: "Done in week 1", comment: "Quick win done detail")),
        QuickWin(code: "H20", title: String(localized: "Bleed the radiators", comment: "Habit H20"),
                 detail: nil, isDone: true,
                 doneDetail: String(localized: "Done in week 2", comment: "Quick win done detail")),
    ]
}

// MARK: - 07 WG

enum MemberColor: Sendable { case greenSoft, lime, card }

struct Flatmate: Equatable, Sendable {
    let name: String
    let avatarColor: MemberColor
    var initial: String { name.first.map(String.init) ?? "" }
}

struct WGOverview: Equatable, Sendable {
    let name: String
    let members: [Flatmate]
    let challengeMonth: String
    let daysLeft: Int
    let challengeTitle: String
    let goal: Int
    /// Loads per member, in `members` order.
    let contributions: [Int]
    let agreementCode: String
    let rules: [(text: String, code: String)]
    let signedBy: Set<String>

    var total: Int { contributions.reduce(0, +) }

    static func == (lhs: WGOverview, rhs: WGOverview) -> Bool {
        lhs.name == rhs.name && lhs.members == rhs.members && lhs.contributions == rhs.contributions && lhs.signedBy == rhs.signedBy
    }

    static let sample = WGOverview(
        name: "Sonnenhof",
        members: [
            Flatmate(name: "Jonas", avatarColor: .greenSoft),
            Flatmate(name: "Lena", avatarColor: .lime),
            Flatmate(name: "Mia", avatarColor: .card),
        ],
        challengeMonth: String(localized: "November", comment: "Challenge month"),
        daysLeft: 7,
        challengeTitle: String(localized: "30 laundry loads in green hours", comment: "WG challenge title"),
        goal: 30,
        contributions: [7, 6, 1],
        agreementCode: "H22",
        rules: [
            (String(localized: "Doors closed between heated and unheated rooms", comment: "WG rule"), "H08"),
            (String(localized: "20°C in shared rooms", comment: "WG rule"), "H05"),
            (String(localized: "Laundry only in green hours", comment: "WG rule"), "H01"),
        ],
        signedBy: ["Jonas", "Lena"]
    )
}

// MARK: - 08 Impact

struct ImpactComparison: Equatable, Sendable {
    let title: String
    let change: String
    /// Before/after shares for the comparison bars, if the metric is a share.
    var bars: (before: Double, after: Double)?

    static func == (lhs: ImpactComparison, rhs: ImpactComparison) -> Bool {
        lhs.title == rhs.title && lhs.change == rhs.change
    }
}

struct ImpactSummary: Equatable, Sendable {
    let weeks: Int
    let co2SavedKg: Int
    let automaticHabits: Int
    let habitsInProgress: Int
    let comparisons: [ImpactComparison]
    let userType: String
    let userTypeDetail: String

    static let sample = ImpactSummary(
        weeks: 6,
        co2SavedKg: 18,
        automaticHabits: 1,
        habitsInProgress: 3,
        comparisons: [
            ImpactComparison(title: String(localized: "Laundry in green hours", comment: "Impact metric"), change: "20% → 75%", bars: (0.20, 0.75)),
            ImpactComparison(title: String(localized: "Thermostat set point", comment: "Impact metric"), change: "21.5 → 20.5 °C"),
        ],
        userType: String(localized: "Heating-heavy", comment: "User type name"),
        userTypeDetail: String(localized: "Your WG's user type, 1 of 3 found by R k-means", comment: "User type explanation")
    )
}

// MARK: - 10 Green software

struct GreenSoftwareReport: Equatable, Sendable {
    struct Metric: Equatable, Sendable {
        enum Icon: Sendable { case cpu, cloud, zap }
        let icon: Icon
        let title: String
        let value: String
        let change: String
    }

    let sprints: [(name: String, wattHours: Double)]
    let metrics: [Metric]
    let changes: [String]

    var latestWattHours: Double { sprints.last?.wattHours ?? 0 }

    static func == (lhs: GreenSoftwareReport, rhs: GreenSoftwareReport) -> Bool {
        lhs.metrics == rhs.metrics && lhs.changes == rhs.changes && lhs.sprints.map(\.wattHours) == rhs.sprints.map(\.wattHours)
    }

    /// Figma placeholders "until we measure the first prototype".
    static let sample = GreenSoftwareReport(
        sprints: [("Sprint 3", 1.5), ("Sprint 4", 1.1), ("Sprint 5", 0.8)],
        metrics: [
            Metric(icon: .cpu, title: String(localized: "CPU per session", comment: "Software metric"), value: "1.2 s", change: "−38%"),
            Metric(icon: .cloud, title: String(localized: "Network per day", comment: "Software metric"), value: "48 KB", change: "−71%"),
            Metric(icon: .zap, title: String(localized: "Server work per user", comment: "Software metric"), value: "0.3 s", change: "−90%"),
        ],
        changes: [
            String(localized: "R models run in one nightly batch, not per request", comment: "Green software change"),
            String(localized: "SMARD data cached once a day", comment: "Green software change"),
            String(localized: "Small payloads, no autoplay media", comment: "Green software change"),
        ]
    )
}
