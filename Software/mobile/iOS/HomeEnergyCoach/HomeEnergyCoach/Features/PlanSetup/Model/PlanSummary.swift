import Foundation

/// The personalised plan shown on `v4 O7 Your plan`.
struct PlanSummary: Equatable, Sendable {
    /// Short segment name, e.g. "Heating-heavy".
    let userTypeName: String
    /// Where the segment comes from, e.g. "User type 1 of 3 · R k-means".
    let userTypeSource: String
    let headline: String
    let explanation: String
    let footprintKgPerMonth: Int
    let similarWGsKgPerMonth: Int
    let firstHabits: [RecommendedHabit]

    /// Share of the comparison bar to fill (own footprint vs. similar WGs).
    var footprintRatio: Double {
        guard similarWGsKgPerMonth > 0 else { return 0 }
        return min(Double(footprintKgPerMonth) / Double(similarWGsKgPerMonth), 1)
    }
}

struct RecommendedHabit: Equatable, Sendable {
    /// Catalogue code, e.g. "H05".
    let code: String
    let title: String
    let reason: String
    /// Expected fit / impact, 1…3 dots.
    let strength: Int
}

/// Produces a plan from the setup answers.
protocol PlanRecommending: Sendable {
    func makePlan(from draft: PlanSetupDraft) -> PlanSummary
}

/// Placeholder recommender returning the Figma sample plan.
///
/// TODO: Replace with the R k-means clustering / ranking service once its API is available.
struct StubPlanRecommender: PlanRecommending {
    func makePlan(from draft: PlanSetupDraft) -> PlanSummary {
        PlanSummary(
            userTypeName: String(localized: "Heating-heavy", comment: "User type name"),
            userTypeSource: String(localized: "User type 1 of 3 · R k-means", comment: "User type source"),
            headline: String(localized: "Your WG is heating-heavy.", comment: "Plan headline"),
            explanation: String(
                localized: "Heating is about two-thirds of your energy, so your plan starts there.",
                comment: "Plan explanation"
            ),
            footprintKgPerMonth: 110,
            similarWGsKgPerMonth: 125,
            firstHabits: [
                RecommendedHabit(
                    code: "H05",
                    title: String(localized: "Lower the thermostat by 1°C", comment: "Habit H05"),
                    reason: String(localized: "Biggest lever for heating-heavy WGs", comment: "Habit H05 reason"),
                    strength: 3
                ),
                RecommendedHabit(
                    code: "H01",
                    title: String(localized: "Run laundry in green hours", comment: "Habit H01"),
                    reason: String(localized: "You're home Saturdays 12–15", comment: "Habit H01 reason"),
                    strength: 2
                ),
                RecommendedHabit(
                    code: "H07",
                    title: String(localized: "Stoßlüften instead of a tilted window", comment: "Habit H07"),
                    reason: String(localized: "4 of 5 similar users kept it", comment: "Habit H07 reason"),
                    strength: 2
                ),
            ]
        )
    }
}
