import Foundation
import Testing
@testable import HomeEnergyCoach

@MainActor
struct HabitDetailViewModelTests {
    @Test func formatsStrengthAndEffect() {
        let viewModel = HabitDetailViewModel(detail: .sample, todayIndex: 0)
        #expect(viewModel.automaticityText == "35%")
        #expect(viewModel.beforeText == "20%")
        #expect(viewModel.afterText == "75%")
        #expect(viewModel.progressNote.hasPrefix("Day 23."))
    }

    @Test func checkInMarksTodayOnce() {
        let viewModel = HabitDetailViewModel(detail: .sample, todayIndex: 2)
        #expect(!viewModel.hasCheckedInToday)
        viewModel.checkInToday()
        #expect(viewModel.hasCheckedInToday)
        #expect(viewModel.detail.checkIns.last?[2] == .done)
        // Earlier weeks are untouched.
        #expect(viewModel.detail.checkIns[2][1] == .partial)
    }

    @Test func alreadyCheckedInDayIsRecognised() {
        // Saturday (index 5) is already done in the sample's current week.
        #expect(HabitDetailViewModel(detail: .sample, todayIndex: 5).hasCheckedInToday)
    }
}

@MainActor
struct GreenHoursViewModelTests {
    private let viewModel = GreenHoursViewModel(forecast: .sample)

    @Test func classifiesHoursLikeTheDesign() {
        #expect((0...8).allSatisfy { viewModel.intensity(at: $0) == .high })
        #expect(viewModel.intensity(at: 9) == .medium)
        #expect([10, 11, 15, 19, 20, 21].allSatisfy { viewModel.intensity(at: $0) == .clean })
        #expect((12..<15).allSatisfy { viewModel.intensity(at: $0) == .window })
        #expect([16, 17, 18, 22].allSatisfy { viewModel.intensity(at: $0) == .medium })
        #expect(viewModel.intensity(at: 23) == .high)
    }

    @Test func summarisesWindowAgainstPeak() {
        #expect(viewModel.windowText == "12:00–15:00")
        #expect(viewModel.windowGrams == 180)
        #expect(viewModel.peak.hour == 7 && viewModel.peak.grams == 400)
        #expect(viewModel.summary == "About 180 g CO₂/kWh, less than half of the 07:00 peak (400 g).")
    }
}

@MainActor
struct HabitCatalogueViewModelTests {
    @Test func countsAndStatuses() {
        let viewModel = HabitCatalogueViewModel()
        #expect(viewModel.count(of: .timing) == 4)
        #expect(viewModel.count(of: .oneTime) == 6)
        #expect(viewModel.status(of: HabitCatalog.habit("H01")!) == .inPlan)
        #expect(viewModel.status(of: HabitCatalog.habit("H07")!) == .next)
        #expect(viewModel.status(of: HabitCatalog.habit("H09")!) == nil)
    }

    @Test func searchMatchesTitleTopicAndCodeIgnoringCaseAndAccents() {
        let viewModel = HabitCatalogueViewModel()
        viewModel.query = "SHOWER"
        #expect(viewModel.visibleHabits.map(\.code) == ["H09"])
        viewModel.query = "stosslueften"
        #expect(viewModel.visibleHabits.isEmpty)
        viewModel.query = "stoßlüften"
        #expect(viewModel.visibleHabits.map(\.code) == ["H07"])
        viewModel.query = "laundry"
        #expect(viewModel.visibleHabits.map(\.code) == ["H01", "H12"])
        viewModel.query = "h2"
        #expect(viewModel.visibleHabits.map(\.code) == ["H20", "H21", "H22"])
    }

    @Test func categoryFilterCombinesWithSearch() {
        let viewModel = HabitCatalogueViewModel()
        viewModel.category = .timing
        #expect(viewModel.visibleHabits.count == 4)
        viewModel.query = "laundry"
        #expect(viewModel.visibleHabits.map(\.code) == ["H01"])
    }
}

@MainActor
struct QuickWinsViewModelTests {
    @Test func togglesAndCountsProgress() {
        let viewModel = QuickWinsViewModel()
        #expect(viewModel.doneCount == 2)
        viewModel.toggle("H21")
        #expect(viewModel.doneCount == 3)
        #expect(viewModel.subtitle(for: viewModel.items[0]) == "H21 · Done today")
        viewModel.toggle("H21")
        #expect(viewModel.subtitle(for: viewModel.items[0]) == "H21 · One decision, big impact")
    }

    @Test func doneItemsKeepTheirHistory() {
        let viewModel = QuickWinsViewModel()
        let bulbs = viewModel.items.first { $0.code == "H17" }!
        #expect(viewModel.subtitle(for: bulbs) == "H17 · Done in week 1")
        viewModel.toggle("H17")
        #expect(viewModel.subtitle(for: viewModel.items.first { $0.code == "H17" }!) == "H17")
    }
}

@MainActor
struct WGViewModelTests {
    @Test func summarisesChallengeAndSignatures() {
        let viewModel = WGViewModel(overview: .sample)
        #expect(viewModel.header == "WG Sonnenhof · 3 flatmates")
        #expect(viewModel.challengeHeader == "November challenge · 7 days left")
        #expect(viewModel.overview.total == 14)
        #expect(viewModel.contributionFractions.map { ($0 * 30).rounded() } == [7, 6, 1])
        #expect(viewModel.signatureStatus == "Mia hasn't signed yet")
    }
}

struct PrivacySettingsStoreTests {
    @Test func persistsAndResets() throws {
        let suite = "PrivacySettingsStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = UserDefaultsPrivacySettingsStore(defaults: defaults)
        #expect(store.settings == PrivacySettings())
        #expect(store.settings.improveRecommendations == false) // opt-in by default

        var settings = store.settings
        settings.reminders = false
        settings.improveRecommendations = true
        store.settings = settings
        #expect(UserDefaultsPrivacySettingsStore(defaults: defaults).settings == settings)

        store.reset()
        #expect(store.settings == PrivacySettings())
    }
}
