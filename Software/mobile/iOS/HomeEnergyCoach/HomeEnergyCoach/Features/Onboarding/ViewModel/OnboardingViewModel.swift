import Foundation

/// Presentation logic for the intro carousel. Free of UIKit so it can be unit-tested.
@MainActor
final class OnboardingViewModel {
    /// Where the intro hands off to when the user leaves it.
    enum Route: Equatable {
        /// `v4 A1 Welcome` — reached via "Skip" or "Let's go".
        case welcome
        /// `v4 A3 Log in` — reached via "Log in" on the last page.
        case login
    }

    /// Result of tapping the primary button.
    enum PrimaryAction: Equatable {
        case showPage(Int)
        case finish(Route)
    }

    let pages: [OnboardingPage]
    private(set) var currentIndex: Int = 0

    init(pages: [OnboardingPage] = OnboardingPage.introPages) {
        precondition(!pages.isEmpty, "Onboarding needs at least one page")
        self.pages = pages
    }

    var pageCount: Int { pages.count }
    var isLastPage: Bool { currentIndex == pages.count - 1 }

    var primaryButtonTitle: String {
        isLastPage
            ? String(localized: "Let's go", comment: "Primary button on the last intro page")
            : String(localized: "Next", comment: "Primary button on intro pages")
    }

    var secondaryButtonTitle: String {
        isLastPage
            ? String(localized: "Log in", comment: "Top-right button on the last intro page")
            : String(localized: "Skip", comment: "Top-right button on intro pages")
    }

    var secondaryRoute: Route { isLastPage ? .login : .welcome }

    /// Step label, e.g. "01 / 03 · Understand" (rendered uppercase by the Meta style).
    func stepText(at index: Int) -> String {
        let position = String(format: "%02d / %02d", index + 1, pages.count)
        return "\(position) · \(pages[index].topic)"
    }

    /// Spoken version of the step label, e.g. "Step 1 of 3, Understand".
    func stepAccessibilityLabel(at index: Int) -> String {
        String(
            localized: "Step \(index + 1) of \(pages.count), \(pages[index].topic)",
            comment: "VoiceOver label for the intro step, e.g. 'Step 1 of 3, Understand'"
        )
    }

    /// Records that the page at `index` is now on screen (e.g. after a swipe).
    func didShowPage(at index: Int) {
        guard pages.indices.contains(index) else { return }
        currentIndex = index
    }

    /// Advances the flow in response to the primary button.
    func primaryAction() -> PrimaryAction {
        guard !isLastPage else { return .finish(.welcome) }
        currentIndex += 1
        return .showPage(currentIndex)
    }
}
