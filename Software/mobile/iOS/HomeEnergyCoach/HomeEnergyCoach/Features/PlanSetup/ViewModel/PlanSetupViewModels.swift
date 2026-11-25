import Foundation

/// Step label shared by every setup screen, e.g. "Step 1 of 6".
enum PlanSetupStep {
    static func title(step: Int, of total: Int = PlanSetupDraft.totalSteps) -> String {
        String(localized: "Step \(step) of \(total)", comment: "Plan setup progress label")
    }
}

/// State and validation for `v4 O1 Your home`.
@MainActor
final class YourHomeViewModel {
    static let step = 1
    static let postcodeLength = 5
    static let maxKWhDigits = 6

    private(set) var draft: PlanSetupDraft
    private(set) var yearlyKWhText: String

    init(draft: PlanSetupDraft) {
        self.draft = draft
        self.yearlyKWhText = draft.yearlyKWh.map(String.init) ?? ""
    }

    var isPostcodeValid: Bool {
        draft.postcode.count == Self.postcodeLength && draft.postcode.allSatisfy(\.isASCIIDigit)
    }

    var canContinue: Bool { draft.flatSize != nil && isPostcodeValid }

    func setHouseholdSize(_ size: Int) {
        draft.householdSize = min(max(size, PlanSetupDraft.householdSizeRange.lowerBound),
                                  PlanSetupDraft.householdSizeRange.upperBound)
    }

    func setFlatSize(_ size: FlatSize) { draft.flatSize = size }

    /// Keeps only digits, capped at 5 (German postcodes).
    func setPostcode(_ text: String) {
        draft.postcode = String(text.filter(\.isASCIIDigit).prefix(Self.postcodeLength))
    }

    /// Keeps only digits; an empty value means "not provided".
    func setYearlyKWh(_ text: String) {
        yearlyKWhText = String(text.filter(\.isASCIIDigit).prefix(Self.maxKWhDigits))
        draft.yearlyKWh = Int(yearlyKWhText)
    }
}

/// State and validation for `v4 O2 Hot water`.
@MainActor
final class HotWaterViewModel {
    static let step = 2

    private(set) var draft: PlanSetupDraft

    init(draft: PlanSetupDraft) {
        self.draft = draft
    }

    var canContinue: Bool { draft.hotWater != nil && draft.showerDuration != nil }

    func setHotWater(_ system: HotWaterSystem) { draft.hotWater = system }
    func setShowerDuration(_ duration: ShowerDuration) { draft.showerDuration = duration }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}

/// State and validation for `v4 O3 Heating`.
@MainActor
final class HeatingViewModel {
    static let step = 3

    private(set) var draft: PlanSetupDraft

    init(draft: PlanSetupDraft) {
        self.draft = draft
    }

    var canContinue: Bool { draft.heating != nil }

    func setHeating(_ system: HeatingSystem) { draft.heating = system }
}

/// State for `v4 O4 Appliances`. Owning no appliances is a valid answer.
@MainActor
final class AppliancesViewModel {
    static let step = 4

    private(set) var draft: PlanSetupDraft

    init(draft: PlanSetupDraft) {
        self.draft = draft
    }

    var canContinue: Bool { true }

    /// Usage questions only apply to appliances the WG owns.
    var asksLaundryLoads: Bool { draft.appliances.contains(.washer) }
    var asksDishwasherRuns: Bool { draft.appliances.contains(.dishwasher) }

    func toggle(_ appliance: Appliance) {
        if draft.appliances.contains(appliance) {
            draft.appliances.remove(appliance)
        } else {
            draft.appliances.insert(appliance)
        }
    }

    func setLaundryLoads(_ value: Int) {
        draft.laundryLoadsPerWeek = PlanSetupDraft.weeklyRunsRange.clamping(value)
    }

    func setDishwasherRuns(_ value: Int) {
        draft.dishwasherRunsPerWeek = PlanSetupDraft.weeklyRunsRange.clamping(value)
    }
}

/// State and validation for `v4 O5 Your week`.
@MainActor
final class YourWeekViewModel {
    static let step = 5

    private(set) var draft: PlanSetupDraft

    init(draft: PlanSetupDraft) {
        self.draft = draft
    }

    var canContinue: Bool { !draft.homeSlots.isEmpty }

    /// The delay-timer question only applies if the WG has a washer.
    var asksAboutDelayTimer: Bool { draft.appliances.contains(.washer) }

    func setHomeSlots(_ slots: Set<HomeSlot>) { draft.homeSlots = slots }
    func setWasherHasDelayTimer(_ value: Bool) { draft.washerHasDelayTimer = value }
}

/// State and validation for `v4 O6 Your focus`.
@MainActor
final class YourFocusViewModel {
    static let step = 6

    private(set) var draft: PlanSetupDraft

    init(draft: PlanSetupDraft) {
        self.draft = draft
    }

    var canContinue: Bool { !draft.focusAreas.isEmpty }

    func toggle(_ focus: CoachFocus) {
        if draft.focusAreas.contains(focus) {
            draft.focusAreas.remove(focus)
        } else {
            draft.focusAreas.insert(focus)
        }
    }

    func setNudgeFrequency(_ frequency: NudgeFrequency) { draft.nudgeFrequency = frequency }
    func setSharesCheckIns(_ value: Bool) { draft.sharesCheckInsAnonymously = value }
}

extension ClosedRange where Bound == Int {
    func clamping(_ value: Int) -> Int {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
