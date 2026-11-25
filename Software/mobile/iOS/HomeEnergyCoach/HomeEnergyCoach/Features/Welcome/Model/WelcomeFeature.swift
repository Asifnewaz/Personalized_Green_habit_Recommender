import Foundation

/// One numbered value proposition on the Welcome screen (Figma `v4 A1 Welcome`).
struct WelcomeFeature: Equatable, Sendable {
    let title: String
    let subtitle: String
}

extension WelcomeFeature {
    static let highlights: [WelcomeFeature] = [
        WelcomeFeature(
            title: String(localized: "A plan for your flat", comment: "Welcome feature 1 title"),
            subtitle: String(localized: "Built from your answers and WGs like yours", comment: "Welcome feature 1 subtitle")
        ),
        WelcomeFeature(
            title: String(localized: "Prompts at the greenest hour", comment: "Welcome feature 2 title"),
            subtitle: String(localized: "Live SMARD forecast, matched to when you're home", comment: "Welcome feature 2 subtitle")
        ),
        WelcomeFeature(
            title: String(localized: "Coaching until it's automatic", comment: "Welcome feature 3 title"),
            subtitle: String(localized: "Check-ins and reminders that fade as habits stick", comment: "Welcome feature 3 subtitle")
        ),
    ]

    /// Two-digit ordinal shown next to a feature, e.g. "01".
    static func ordinal(at index: Int) -> String {
        String(format: "%02d", index + 1)
    }
}
