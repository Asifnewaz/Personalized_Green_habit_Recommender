import UIKit

/// Answers collected across the 6-step plan setup (Figma `v4 O1–O6`).
struct PlanSetupDraft: Equatable, Sendable {
    static let totalSteps = 6
    static let householdSizeRange = 1...6
    static let weeklyRunsRange = 0...14

    // O1 · Your home
    var householdSize = 3
    var flatSize: FlatSize?
    var postcode = ""
    var yearlyKWh: Int?

    // O2 · Hot water
    var hotWater: HotWaterSystem?
    var showerDuration: ShowerDuration?

    // O3 · Heating
    var heating: HeatingSystem?

    // O4 · Appliances
    var appliances: Set<Appliance> = []
    var laundryLoadsPerWeek = 2
    var dishwasherRunsPerWeek = 3

    // O5 · Your week
    var homeSlots: Set<HomeSlot> = []
    var washerHasDelayTimer = false

    // O6 · Your focus
    var focusAreas: Set<CoachFocus> = []
    var nudgeFrequency: NudgeFrequency = .fewTimesAWeek
    /// Anonymous data sharing is opt-in (GDPR), so it starts off.
    var sharesCheckInsAnonymously = false
}

// MARK: - O1

enum FlatSize: CaseIterable, Sendable {
    case under50, from50To80, from80To110, over110

    var title: String {
        switch self {
        case .under50: String(localized: "< 50 m²", comment: "Flat size option")
        case .from50To80: String(localized: "50–80 m²", comment: "Flat size option")
        case .from80To110: String(localized: "80–110 m²", comment: "Flat size option")
        case .over110: String(localized: "> 110 m²", comment: "Flat size option")
        }
    }
}

// MARK: - O2

enum HotWaterSystem: CaseIterable, Sendable {
    case centralBoiler, electricInstant, electricTank, notSure

    var title: String {
        switch self {
        case .centralBoiler: String(localized: "Central boiler", comment: "Hot water option")
        case .electricInstant: String(localized: "Electric instant heater", comment: "Hot water option")
        case .electricTank: String(localized: "Electric tank", comment: "Hot water option")
        case .notSure: String(localized: "Not sure", comment: "Hot water option")
        }
    }

    var subtitle: String {
        switch self {
        case .centralBoiler: String(localized: "Same system as your heating", comment: "Hot water option detail")
        case .electricInstant: String(localized: "Durchlauferhitzer in the bathroom", comment: "Hot water option detail")
        case .electricTank: String(localized: "Small boiler under the sink", comment: "Hot water option detail")
        case .notSure: String(localized: "We use the usual setup", comment: "Hot water option detail")
        }
    }
}

enum ShowerDuration: CaseIterable, Sendable {
    case under5, from5To10, over10

    var title: String {
        switch self {
        case .under5: String(localized: "Under 5 min", comment: "Shower duration option")
        case .from5To10: String(localized: "5–10 min", comment: "Shower duration option")
        case .over10: String(localized: "Over 10 min", comment: "Shower duration option")
        }
    }
}

// MARK: - O3

enum HeatingSystem: CaseIterable, Sendable {
    case gasCentral, district, electricHeaters, heatPump

    var title: String {
        switch self {
        case .gasCentral: String(localized: "Gas central heating", comment: "Heating option")
        case .district: String(localized: "District heating", comment: "Heating option")
        case .electricHeaters: String(localized: "Electric heaters", comment: "Heating option")
        case .heatPump: String(localized: "Heat pump", comment: "Heating option")
        }
    }

    var subtitle: String {
        switch self {
        case .gasCentral: String(localized: "Boiler and radiators", comment: "Heating option detail")
        case .district: String(localized: "Fernwärme", comment: "Heating option detail")
        case .electricHeaters: String(localized: "Storage or plug-in", comment: "Heating option detail")
        case .heatPump: String(localized: "Electric and efficient", comment: "Heating option detail")
        }
    }
}

// MARK: - O4

enum Appliance: CaseIterable, Sendable {
    case washer, dishwasher, dryer, oven, gamingPC, eScooter, fanHeater, freezer

    var title: String {
        switch self {
        case .washer: String(localized: "Washer", comment: "Appliance")
        case .dishwasher: String(localized: "Dishwasher", comment: "Appliance")
        case .dryer: String(localized: "Dryer", comment: "Appliance")
        case .oven: String(localized: "Oven", comment: "Appliance")
        case .gamingPC: String(localized: "Gaming PC", comment: "Appliance")
        case .eScooter: String(localized: "E-scooter", comment: "Appliance")
        case .fanHeater: String(localized: "Fan heater", comment: "Appliance")
        case .freezer: String(localized: "Freezer", comment: "Appliance")
        }
    }

    var icon: ImageResource {
        switch self {
        case .washer: .iconWasher
        case .dishwasher: .iconDroplet
        case .dryer: .iconWind
        case .oven: .iconFlame
        case .gamingPC: .iconCpu
        case .eScooter: .iconZap
        case .fanHeater: .iconThermometer
        case .freezer: .iconPlug
        }
    }
}

// MARK: - O5

enum DayPart: CaseIterable, Sendable {
    case morning, midday, afternoon, evening, night

    var title: String {
        switch self {
        case .morning: String(localized: "Morning", comment: "Part of day")
        case .midday: String(localized: "Midday", comment: "Part of day")
        case .afternoon: String(localized: "Afternoon", comment: "Part of day")
        case .evening: String(localized: "Evening", comment: "Part of day")
        case .night: String(localized: "Night", comment: "Part of day")
        }
    }

    /// Hour range, e.g. "6–10".
    var hours: String {
        switch self {
        case .morning: "6–10"
        case .midday: "10–14"
        case .afternoon: "14–18"
        case .evening: "18–22"
        case .night: "22–6"
        }
    }
}

enum DayType: CaseIterable, Sendable {
    case weekdays, weekend

    var title: String {
        switch self {
        case .weekdays: String(localized: "Weekdays", comment: "Availability column")
        case .weekend: String(localized: "Weekend", comment: "Availability column")
        }
    }
}

/// One cell of the "When are you usually home?" grid.
struct HomeSlot: Hashable, Sendable {
    let part: DayPart
    let days: DayType
}

// MARK: - O6

enum CoachFocus: CaseIterable, Sendable {
    case cuttingCO2, savingMoney, withMyWG, seeingProgress

    var title: String {
        switch self {
        case .cuttingCO2: String(localized: "Cutting CO₂", comment: "Coach focus option")
        case .savingMoney: String(localized: "Saving money", comment: "Coach focus option")
        case .withMyWG: String(localized: "Doing it with my WG", comment: "Coach focus option")
        case .seeingProgress: String(localized: "Seeing my progress", comment: "Coach focus option")
        }
    }

    var subtitle: String {
        switch self {
        case .cuttingCO2: String(localized: "See your impact in kg", comment: "Coach focus detail")
        case .savingMoney: String(localized: "Lower bills for the WG", comment: "Coach focus detail")
        case .withMyWG: String(localized: "Shared challenges and agreements", comment: "Coach focus detail")
        case .seeingProgress: String(localized: "Trends and habit strength", comment: "Coach focus detail")
        }
    }
}

enum NudgeFrequency: CaseIterable, Sendable {
    case weekly, fewTimesAWeek, daily

    var title: String {
        switch self {
        case .weekly: String(localized: "Weekly", comment: "Nudge frequency")
        case .fewTimesAWeek: String(localized: "2–3 times", comment: "Nudge frequency")
        case .daily: String(localized: "Daily", comment: "Nudge frequency")
        }
    }
}
