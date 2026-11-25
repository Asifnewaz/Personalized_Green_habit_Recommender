import Foundation
import Testing
@testable import HomeEnergyCoach

@MainActor
struct HomeViewModelTests {
    private let locale = Locale(identifier: "en_GB")

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    /// Monday, 23 November 2026, noon in Berlin.
    private var monday: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 12))!
    }

    private func makeViewModel(name: String? = "Lena") -> HomeViewModel {
        HomeViewModel(
            dashboard: StubHomeDashboardProvider().dashboard(userName: name),
            now: monday, calendar: calendar, locale: locale
        )
    }

    @Test func formatsHeaderLikeTheDesign() {
        let viewModel = makeViewModel()
        #expect(viewModel.dateText == "Monday 23 November" || viewModel.dateText == "Monday, 23 November")
        #expect(viewModel.greeting == "Hi Lena")
        #expect(viewModel.avatarInitial == "L")
    }

    @Test func fallsBackToSampleNameWhenEmpty() {
        #expect(makeViewModel(name: "  ").greeting == "Hi Lena")
        #expect(makeViewModel(name: "Jonas").avatarInitial == "J")
    }

    @Test func formatsWeeklyFigures() {
        let viewModel = makeViewModel()
        #expect(viewModel.weeklyChangeText == "−4.1")
        #expect(viewModel.trendText == "+18% vs last week")
        #expect(viewModel.weekTitle == "This week · WG Sonnenhof")
    }

    @Test func weekStartsOnMondayAndHighlightsToday() {
        let viewModel = makeViewModel()
        #expect(viewModel.dayLabels.first == "Mon")
        #expect(viewModel.dayLabels.last == "Sun")
        #expect(viewModel.todayIndex == 0)
        #expect(viewModel.barFractions.max() == 1)
    }

    @Test func formatsHabitCards() {
        let viewModel = makeViewModel()
        #expect(viewModel.greenWindowTitle == "Green window until 15:00")
        #expect(viewModel.greenWindowSubtitle == "Good time for H01 · laundry")
        #expect(viewModel.habitStatusText == "Day 23 · 35% automatic")
        #expect(viewModel.habitTypicalText == "~66 days typical")
        #expect(viewModel.nextHabitTitle == "H07 · Stoßlüften")
    }
}
