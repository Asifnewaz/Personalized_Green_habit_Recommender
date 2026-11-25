import UIKit

/// Content for one page of the intro carousel (Figma frames `v4 I1–I3 Intro`).
struct OnboardingPage: Equatable, Sendable {
    /// Short topic shown in the step label, e.g. "Understand".
    let topic: String
    let title: String
    let message: String
    let illustration: ImageResource
    /// VoiceOver description of the illustration.
    let illustrationDescription: String
}

extension OnboardingPage {
    static let introPages: [OnboardingPage] = [
        OnboardingPage(
            topic: String(localized: "Understand", comment: "Intro page 1 topic"),
            title: String(localized: "See where your WG's energy goes.", comment: "Intro page 1 title"),
            message: String(
                localized: "Answer 6 quick questions. We estimate your flat's footprint and compare it with similar WGs. No meter needed.",
                comment: "Intro page 1 body"
            ),
            illustration: .onboardingUnderstand,
            illustrationDescription: String(
                localized: "Two flatmates relaxing in a cosy living room beneath a rising energy bar chart.",
                comment: "Intro page 1 illustration description"
            )
        ),
        OnboardingPage(
            topic: String(localized: "Time it right", comment: "Intro page 2 topic"),
            title: String(localized: "Run it when the grid is greenest.", comment: "Intro page 2 title"),
            message: String(
                localized: "Live SMARD data shows when Germany's power is cleanest. We match it to the hours you're at home.",
                comment: "Intro page 2 body"
            ),
            illustration: .onboardingTimeItRight,
            illustrationDescription: String(
                localized: "A washing machine with a green leaf badge next to a window overlooking wind turbines.",
                comment: "Intro page 2 illustration description"
            )
        ),
        OnboardingPage(
            topic: String(localized: "Make it stick", comment: "Intro page 3 topic"),
            title: String(localized: "Small habits. Real impact. Together.", comment: "Intro page 3 title"),
            message: String(
                localized: "Tips ranked for your flat, check-ins that turn them into routine, and a WG challenge to share the wins.",
                comment: "Intro page 3 body"
            ),
            illustration: .onboardingMakeItStick,
            illustrationDescription: String(
                localized: "Three hands high-fiving above a small house with a sprouting plant.",
                comment: "Intro page 3 illustration description"
            )
        ),
    ]
}
