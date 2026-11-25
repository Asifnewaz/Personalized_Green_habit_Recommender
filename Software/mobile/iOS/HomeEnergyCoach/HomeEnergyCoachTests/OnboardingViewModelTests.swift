import Testing
@testable import HomeEnergyCoach

@MainActor
struct OnboardingViewModelTests {
    private let pages = OnboardingPage.introPages

    @Test func startsOnFirstPageWithSkipAndNext() {
        let viewModel = OnboardingViewModel(pages: pages)

        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.pageCount == 3)
        #expect(!viewModel.isLastPage)
        #expect(viewModel.primaryButtonTitle == "Next")
        #expect(viewModel.secondaryButtonTitle == "Skip")
        #expect(viewModel.secondaryRoute == .welcome)
    }

    @Test func primaryActionAdvancesThroughPagesThenFinishes() {
        let viewModel = OnboardingViewModel(pages: pages)

        #expect(viewModel.primaryAction() == .showPage(1))
        #expect(viewModel.primaryAction() == .showPage(2))
        #expect(viewModel.isLastPage)
        #expect(viewModel.primaryAction() == .finish(.welcome))
        #expect(viewModel.currentIndex == 2)
    }

    @Test func lastPageOffersLetsGoAndLogIn() {
        let viewModel = OnboardingViewModel(pages: pages)
        viewModel.didShowPage(at: 2)

        #expect(viewModel.primaryButtonTitle == "Let's go")
        #expect(viewModel.secondaryButtonTitle == "Log in")
        #expect(viewModel.secondaryRoute == .login)
    }

    @Test func didShowPageIgnoresOutOfRangeIndices() {
        let viewModel = OnboardingViewModel(pages: pages)
        viewModel.didShowPage(at: 1)
        viewModel.didShowPage(at: 7)
        viewModel.didShowPage(at: -1)

        #expect(viewModel.currentIndex == 1)
    }

    @Test(arguments: [
        (0, "01 / 03 · Understand"),
        (1, "02 / 03 · Time it right"),
        (2, "03 / 03 · Make it stick"),
    ])
    func stepTextMatchesDesign(index: Int, expected: String) {
        #expect(OnboardingViewModel(pages: pages).stepText(at: index) == expected)
    }

    @Test func stepAccessibilityLabelIsSpeakable() {
        #expect(OnboardingViewModel(pages: pages).stepAccessibilityLabel(at: 0) == "Step 1 of 3, Understand")
    }
}
