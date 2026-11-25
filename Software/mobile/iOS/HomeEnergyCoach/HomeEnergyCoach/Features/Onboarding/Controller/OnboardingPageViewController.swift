import UIKit

/// Hosts a single intro page inside the carousel's `UIPageViewController`.
final class OnboardingPageViewController: UIViewController {
    let pageIndex: Int
    private let contentView = OnboardingPageContentView()
    private var hasPlayedEntrance = false

    init(page: OnboardingPage, pageIndex: Int, stepText: String, stepAccessibilityLabel: String) {
        self.pageIndex = pageIndex
        super.init(nibName: nil, bundle: nil)
        contentView.configure(with: page, stepText: stepText, stepAccessibilityLabel: stepAccessibilityLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = contentView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Play the entrance once, as the page starts sliding on screen.
        guard !hasPlayedEntrance else { return }
        hasPlayedEntrance = true
        let steps = contentView.entranceSteps
        EntranceAnimation.prepare(steps)
        EntranceAnimation.play(steps)
    }
}
