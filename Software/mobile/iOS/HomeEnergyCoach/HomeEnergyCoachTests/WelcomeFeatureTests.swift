import Testing
@testable import HomeEnergyCoach

struct WelcomeFeatureTests {
    @Test func highlightsMatchDesign() {
        #expect(WelcomeFeature.highlights.map(\.title) == [
            "A plan for your flat",
            "Prompts at the greenest hour",
            "Coaching until it's automatic",
        ])
    }

    @Test(arguments: [(0, "01"), (1, "02"), (2, "03"), (9, "10")])
    func ordinalIsZeroPadded(index: Int, expected: String) {
        #expect(WelcomeFeature.ordinal(at: index) == expected)
    }
}
