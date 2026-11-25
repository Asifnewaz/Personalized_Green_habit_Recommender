import Foundation

// MARK: - 03 Habit

@MainActor
final class HabitDetailViewModel {
    private(set) var detail: HabitDetail
    private let todayIndex: Int
    private(set) var hasCheckedInToday = false

    /// - Parameter todayIndex: Monday = 0 … Sunday = 6.
    init(detail: HabitDetail, todayIndex: Int) {
        self.detail = detail
        self.todayIndex = min(max(todayIndex, 0), 6)
        hasCheckedInToday = detail.checkIns.last?[self.todayIndex] == .done
    }

    var automaticityText: String { "\(Int((detail.automaticity * 100).rounded()))%" }

    var progressNote: String {
        String(
            localized: "Day \(detail.day). Habits take about \(detail.typicalDays) days on average, and one missed day doesn't reset your progress.",
            comment: "Habit strength explanation"
        )
    }

    var beforeText: String { "\(Int((detail.before * 100).rounded()))%" }
    var afterText: String { "\(Int((detail.after * 100).rounded()))%" }

    /// Records today's check-in in the current week.
    func checkInToday() {
        guard !hasCheckedInToday, !detail.checkIns.isEmpty else { return }
        detail.checkIns[detail.checkIns.count - 1][todayIndex] = .done
        hasCheckedInToday = true
    }
}

// MARK: - 04 Green Hours

enum GridIntensity: Equatable {
    case window, clean, medium, high
}

@MainActor
final class GreenHoursViewModel {
    /// At or below: "clean" (Figma `green-soft`). At or above `highThreshold`: "high CO₂" (`orange`).
    static let cleanThreshold = 260
    static let highThreshold = 345

    let forecast: GreenHoursForecast

    init(forecast: GreenHoursForecast) {
        self.forecast = forecast
    }

    func intensity(at hour: Int) -> GridIntensity {
        if forecast.window.contains(hour) { return .window }
        let grams = forecast.gramsPerKWh[hour]
        if grams <= Self.cleanThreshold { return .clean }
        if grams >= Self.highThreshold { return .high }
        return .medium
    }

    /// e.g. "12:00–15:00".
    var windowText: String {
        String(format: "%02d:00–%02d:00", forecast.window.lowerBound, forecast.window.upperBound)
    }

    /// Mean intensity inside the window, rounded down to 10 g ("about 180 g").
    var windowGrams: Int {
        let values: [Int] = forecast.window.map { forecast.gramsPerKWh[$0] }
        guard !values.isEmpty else { return 0 }
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let tens = (mean / 10).rounded(.down)
        return Int(tens) * 10
    }

    var peak: (hour: Int, grams: Int) {
        var best = (hour: 0, grams: Int.min)
        for (hour, grams) in forecast.gramsPerKWh.enumerated() where grams > best.grams {
            best = (hour, grams)
        }
        return best
    }

    /// e.g. "About 180 g CO₂/kWh, less than half of the 07:00 peak (400 g)."
    var summary: String {
        let peak = peak
        let comparison = windowGrams * 2 < peak.grams
            ? String(localized: "less than half of", comment: "Intensity comparison")
            : String(localized: "lower than", comment: "Intensity comparison")
        return String(
            localized: "About \(windowGrams) g CO₂/kWh, \(comparison) the \(String(format: "%02d:00", peak.hour)) peak (\(peak.grams) g).",
            comment: "Green window summary"
        )
    }
}

// MARK: - 05 Habit catalogue

@MainActor
final class HabitCatalogueViewModel {
    enum Status { case inPlan, next }

    let habits: [Habit]
    private let inPlan: Set<String>
    private let nextCode: String?

    var query = ""
    var category: HabitCategory?

    init(habits: [Habit] = HabitCatalog.all, inPlan: Set<String> = ["H01", "H05"], nextCode: String? = "H07") {
        self.habits = habits
        self.inPlan = inPlan
        self.nextCode = nextCode
    }

    var title: String { String(localized: "\(habits.count) habits", comment: "Habit catalogue title") }

    func count(of category: HabitCategory) -> Int {
        habits.filter { $0.category == category }.count
    }

    var visibleHabits: [Habit] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        return habits.filter { habit in
            (category == nil || habit.category == category)
                && (trimmed.isEmpty || [habit.code, habit.title, habit.topic ?? ""].contains {
                    $0.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                })
        }
    }

    func status(of habit: Habit) -> Status? {
        if inPlan.contains(habit.code) { return .inPlan }
        if habit.code == nextCode { return .next }
        return nil
    }
}

// MARK: - 06 Quick wins

@MainActor
final class QuickWinsViewModel {
    private(set) var items: [QuickWin]

    init(items: [QuickWin] = QuickWin.sample) {
        self.items = items
    }

    var doneCount: Int { items.filter(\.isDone).count }

    func toggle(_ code: String) {
        guard let index = items.firstIndex(where: { $0.code == code }) else { return }
        items[index].isDone.toggle()
        if items[index].isDone, items[index].doneDetail == nil {
            items[index].doneDetail = String(localized: "Done today", comment: "Quick win done detail")
        }
    }

    /// e.g. "H21 · One decision, big impact" / "H17 · Done in week 1".
    func subtitle(for item: QuickWin) -> String {
        let detail = item.isDone ? item.doneDetail : item.detail
        return [item.code, detail].compactMap { $0 }.joined(separator: " · ")
    }
}

// MARK: - 07 WG

@MainActor
final class WGViewModel {
    let overview: WGOverview

    init(overview: WGOverview) {
        self.overview = overview
    }

    var header: String {
        String(localized: "WG \(overview.name) · \(overview.members.count) flatmates", comment: "WG header")
    }

    var challengeHeader: String {
        String(localized: "\(overview.challengeMonth) challenge · \(overview.daysLeft) days left", comment: "WG challenge header")
    }

    /// Each member's share of the goal, for the stacked bar.
    var contributionFractions: [Double] {
        guard overview.goal > 0 else { return overview.contributions.map { _ in 0 } }
        return overview.contributions.map { Double($0) / Double(overview.goal) }
    }

    var unsignedMembers: [Flatmate] {
        overview.members.filter { !overview.signedBy.contains($0.name) }
    }

    var signatureStatus: String {
        let unsigned = unsignedMembers
        switch unsigned.count {
        case 0: return String(localized: "Everyone has signed", comment: "WG agreement status")
        case 1: return String(localized: "\(unsigned[0].name) hasn't signed yet", comment: "WG agreement status")
        default: return String(localized: "\(unsigned.count) flatmates haven't signed yet", comment: "WG agreement status")
        }
    }
}

// MARK: - 09 Data & privacy

/// User-controlled privacy switches, persisted locally.
struct PrivacySettings: Codable, Equatable, Sendable {
    var shareProgressWithWG = true
    /// Anonymous model training is opt-in (GDPR).
    var improveRecommendations = false
    var reminders = true
}

protocol PrivacySettingsStoring: AnyObject {
    var settings: PrivacySettings { get set }
    func reset()
}

final class UserDefaultsPrivacySettingsStore: PrivacySettingsStoring {
    private let defaults: UserDefaults
    private let key = "privacySettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var settings: PrivacySettings {
        get {
            guard let data = defaults.data(forKey: key),
                  let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) else { return PrivacySettings() }
            return settings
        }
        set {
            defaults.set(try? JSONEncoder().encode(newValue), forKey: key)
        }
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
