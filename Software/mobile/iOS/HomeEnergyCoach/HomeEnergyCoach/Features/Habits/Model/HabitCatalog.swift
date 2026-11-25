import Foundation

/// The three habit families (Figma `v4 05 Habit catalogue`).
enum HabitCategory: CaseIterable, Sendable {
    case timing, reduction, oneTime

    var title: String {
        switch self {
        case .timing: String(localized: "Timing", comment: "Habit category")
        case .reduction: String(localized: "Reduction", comment: "Habit category")
        case .oneTime: String(localized: "One-time", comment: "Habit category")
        }
    }

    /// How the app supports this family.
    var mechanism: String {
        switch self {
        case .timing: String(localized: "Green Hours prompts", comment: "Habit category mechanism")
        case .reduction: String(localized: "Habit loop", comment: "Habit category mechanism")
        case .oneTime: String(localized: "Checklist", comment: "Habit category mechanism")
        }
    }
}

struct Habit: Equatable, Sendable, Identifiable {
    let code: String
    let title: String
    let category: HabitCategory
    /// Area it applies to, e.g. "laundry". `nil` for one-time actions.
    let topic: String?

    var id: String { code }

    /// e.g. "Timing · laundry".
    var categoryLine: String {
        guard let topic else { return category.title }
        return "\(category.title) · \(topic)"
    }
}

/// The renter-friendly habit catalogue.
///
/// TODO: Load the full catalogue (22 habits) from the backend. The design names only the 16
/// below; H06, H10, H11, H13, H15 and H16 are not specified, so they're not invented here.
enum HabitCatalog {
    static let all: [Habit] = [
        Habit(code: "H01", title: String(localized: "Run laundry in green hours", comment: "Habit H01"), category: .timing, topic: String(localized: "laundry", comment: "Habit topic")),
        Habit(code: "H02", title: String(localized: "Dishwasher in green hours", comment: "Habit H02"), category: .timing, topic: String(localized: "dishwasher", comment: "Habit topic")),
        Habit(code: "H03", title: String(localized: "Charge devices in green hours", comment: "Habit H03"), category: .timing, topic: String(localized: "electronics", comment: "Habit topic")),
        Habit(code: "H04", title: String(localized: "Batch cooking", comment: "Habit H04"), category: .timing, topic: String(localized: "cooking", comment: "Habit topic")),
        Habit(code: "H05", title: String(localized: "Lower the thermostat by 1°C", comment: "Habit H05"), category: .reduction, topic: String(localized: "heating", comment: "Habit topic")),
        Habit(code: "H07", title: String(localized: "Stoßlüften, not a tilted window", comment: "Habit H07"), category: .reduction, topic: String(localized: "heating", comment: "Habit topic")),
        Habit(code: "H08", title: String(localized: "Doors closed between heated and unheated rooms", comment: "Habit H08"), category: .reduction, topic: String(localized: "heating", comment: "Habit topic")),
        Habit(code: "H09", title: String(localized: "Shorter showers", comment: "Habit H09"), category: .reduction, topic: String(localized: "hot water", comment: "Habit topic")),
        Habit(code: "H12", title: String(localized: "Wash at 30°C, full loads", comment: "Habit H12"), category: .reduction, topic: String(localized: "laundry", comment: "Habit topic")),
        Habit(code: "H14", title: String(localized: "Power strips off at night", comment: "Habit H14"), category: .reduction, topic: String(localized: "electronics", comment: "Habit topic")),
        Habit(code: "H17", title: String(localized: "Swap remaining bulbs for LEDs", comment: "Habit H17"), category: .oneTime, topic: nil),
        Habit(code: "H18", title: String(localized: "Smart power strip or timer plug", comment: "Habit H18"), category: .oneTime, topic: nil),
        Habit(code: "H19", title: String(localized: "Check the fridge seals", comment: "Habit H19"), category: .oneTime, topic: nil),
        Habit(code: "H20", title: String(localized: "Bleed the radiators", comment: "Habit H20"), category: .oneTime, topic: nil),
        Habit(code: "H21", title: String(localized: "Choose a green electricity tariff", comment: "Habit H21"), category: .oneTime, topic: nil),
        Habit(code: "H22", title: String(localized: "Agree on a WG energy agreement", comment: "Habit H22"), category: .oneTime, topic: nil),
    ]

    static func habit(_ code: String) -> Habit? { all.first { $0.code == code } }
}
