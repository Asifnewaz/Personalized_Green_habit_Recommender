import Testing
@testable import HomeEnergyCoach

@MainActor
struct YourHomeViewModelTests {
    @Test func requiresFlatSizeAndValidPostcode() {
        let viewModel = YourHomeViewModel(draft: PlanSetupDraft())
        #expect(!viewModel.canContinue)

        viewModel.setFlatSize(.from50To80)
        #expect(!viewModel.canContinue)

        viewModel.setPostcode("6031")
        #expect(!viewModel.canContinue)

        viewModel.setPostcode("60311")
        #expect(viewModel.canContinue)
    }

    @Test func postcodeKeepsFiveDigitsOnly() {
        let viewModel = YourHomeViewModel(draft: PlanSetupDraft())
        viewModel.setPostcode("60a3-1199")
        #expect(viewModel.draft.postcode == "60311")
    }

    @Test func yearlyKWhIsOptionalAndNumeric() {
        let viewModel = YourHomeViewModel(draft: PlanSetupDraft())
        viewModel.setYearlyKWh("2,100 kWh")
        #expect(viewModel.draft.yearlyKWh == 2100)
        #expect(viewModel.yearlyKWhText == "2100")

        viewModel.setYearlyKWh("")
        #expect(viewModel.draft.yearlyKWh == nil)
    }

    @Test func householdSizeIsClamped() {
        let viewModel = YourHomeViewModel(draft: PlanSetupDraft())
        viewModel.setHouseholdSize(99)
        #expect(viewModel.draft.householdSize == PlanSetupDraft.householdSizeRange.upperBound)
        viewModel.setHouseholdSize(0)
        #expect(viewModel.draft.householdSize == PlanSetupDraft.householdSizeRange.lowerBound)
    }
}

@MainActor
struct HotWaterViewModelTests {
    @Test func requiresBothAnswers() {
        let viewModel = HotWaterViewModel(draft: PlanSetupDraft())
        #expect(!viewModel.canContinue)
        viewModel.setHotWater(.centralBoiler)
        #expect(!viewModel.canContinue)
        viewModel.setShowerDuration(.from5To10)
        #expect(viewModel.canContinue)
    }

    @Test func keepsEarlierAnswers() {
        var draft = PlanSetupDraft()
        draft.postcode = "60311"
        let viewModel = HotWaterViewModel(draft: draft)
        viewModel.setHotWater(.notSure)
        #expect(viewModel.draft.postcode == "60311")
    }
}

struct PlanSetupStepTests {
    @Test func stepTitle() {
        #expect(PlanSetupStep.title(step: 2) == "Step 2 of 6")
    }
}

@MainActor
struct LaterSetupStepTests {
    @Test func heatingRequiresAnAnswer() {
        let viewModel = HeatingViewModel(draft: PlanSetupDraft())
        #expect(!viewModel.canContinue)
        viewModel.setHeating(.heatPump)
        #expect(viewModel.canContinue)
    }

    @Test func applianceUsageQuestionsFollowOwnership() {
        let viewModel = AppliancesViewModel(draft: PlanSetupDraft())
        #expect(viewModel.canContinue) // owning nothing is valid
        #expect(!viewModel.asksLaundryLoads && !viewModel.asksDishwasherRuns)

        viewModel.toggle(.washer)
        #expect(viewModel.asksLaundryLoads)
        viewModel.toggle(.dishwasher)
        #expect(viewModel.asksDishwasherRuns)
        viewModel.toggle(.washer)
        #expect(!viewModel.asksLaundryLoads)
    }

    @Test func weeklyRunsAreClamped() {
        let viewModel = AppliancesViewModel(draft: PlanSetupDraft())
        viewModel.setLaundryLoads(99)
        viewModel.setDishwasherRuns(-3)
        #expect(viewModel.draft.laundryLoadsPerWeek == PlanSetupDraft.weeklyRunsRange.upperBound)
        #expect(viewModel.draft.dishwasherRunsPerWeek == 0)
    }

    @Test func weekNeedsAtLeastOneSlotAndAsksTimerOnlyWithWasher() {
        var draft = PlanSetupDraft()
        let withoutWasher = YourWeekViewModel(draft: draft)
        #expect(!withoutWasher.canContinue)
        #expect(!withoutWasher.asksAboutDelayTimer)

        draft.appliances = [.washer]
        let viewModel = YourWeekViewModel(draft: draft)
        #expect(viewModel.asksAboutDelayTimer)
        viewModel.setHomeSlots([HomeSlot(part: .evening, days: .weekdays)])
        #expect(viewModel.canContinue)
    }

    @Test func focusAllowsMultipleAndDefaultsArePrivacyFriendly() {
        let viewModel = YourFocusViewModel(draft: PlanSetupDraft())
        #expect(!viewModel.canContinue)
        #expect(viewModel.draft.sharesCheckInsAnonymously == false)
        #expect(viewModel.draft.nudgeFrequency == .fewTimesAWeek)

        viewModel.toggle(.cuttingCO2)
        viewModel.toggle(.withMyWG)
        #expect(viewModel.draft.focusAreas == [.cuttingCO2, .withMyWG])
        #expect(viewModel.canContinue)
    }
}

struct PlanSummaryTests {
    @Test func footprintRatioComparesWithSimilarWGs() {
        let plan = StubPlanRecommender().makePlan(from: PlanSetupDraft())
        #expect(abs(plan.footprintRatio - 110.0 / 125.0) < 0.0001)
        #expect(plan.firstHabits.map(\.code) == ["H05", "H01", "H07"])
    }
}
