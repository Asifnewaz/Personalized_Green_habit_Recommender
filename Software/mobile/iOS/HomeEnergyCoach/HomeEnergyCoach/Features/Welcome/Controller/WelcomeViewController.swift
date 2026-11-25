import UIKit

@MainActor
protocol WelcomeViewControllerDelegate: AnyObject {
    /// "Get started" — continue to account creation (`v4 A2 Create account`).
    func welcomeViewControllerDidSelectGetStarted(_ controller: WelcomeViewController)
    /// "I already have an account" — continue to log in (`v4 A3 Log in`).
    func welcomeViewControllerDidSelectLogIn(_ controller: WelcomeViewController)
}

/// Welcome screen shown after the intro carousel (Figma `v4 A1 Welcome`).
///
/// Content scrolls when it doesn't fit (small devices, large Dynamic Type);
/// otherwise a flexible spacer pins the actions to the bottom, as in the design.
final class WelcomeViewController: UIViewController {
    private enum Metrics {
        static let topPadding: CGFloat = 40
        static let sectionSpacing: CGFloat = 28
        static let headSpacing: CGFloat = 8
        static let featureSpacing: CGFloat = 18
        static let actionSpacing: CGFloat = 10
    }

    weak var delegate: WelcomeViewControllerDelegate?

    private let features: [WelcomeFeature]

    private let scrollView = UIScrollView()
    private let brandMarkView = BrandMarkView(
        title: String(localized: "Home Energy Coach", comment: "App name shown in the welcome header")
    )
    private let headStack = UIStackView()
    private let featureStack = UIStackView()
    private let actionStack = UIStackView()
    private let getStartedButton = AppButton(
        kind: .primary,
        title: String(localized: "Get started", comment: "Welcome primary action")
    )
    private let logInButton = AppButton(
        kind: .ghost,
        title: String(localized: "I already have an account", comment: "Welcome secondary action")
    )
    private var bottomPaddingConstraint: NSLayoutConstraint?
    private var hasPlayedEntrance = false

    init(features: [WelcomeFeature] = WelcomeFeature.highlights) {
        self.features = features
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setUpContent()
        setUpLayout()
        setUpActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        guard !hasPlayedEntrance else { return }
        hasPlayedEntrance = true
        // Figma timeline: brand 50ms, head 100ms, features 150ms, actions 250ms.
        let steps: [EntranceAnimation.Step] = [
            .rise(brandMarkView, delay: 0.05),
            .rise(headStack, delay: 0.10),
            .rise(featureStack, delay: 0.15),
            .rise(actionStack, delay: 0.25),
        ]
        EntranceAnimation.prepare(steps)
        EntranceAnimation.play(steps)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // Figma: actions sit 32pt above the screen edge, but never inside the home-indicator area.
        bottomPaddingConstraint?.constant = -max(Spacing.l, view.safeAreaInsets.bottom)
    }

    // MARK: - Setup

    private func setUpContent() {
        let titleLabel = StyledLabel(style: .display, color: AppColor.ink)
        titleLabel.content = String(localized: "Green habits that stick.", comment: "Welcome headline")
        titleLabel.accessibilityTraits = .header

        let subtitleLabel = StyledLabel(style: .body, color: AppColor.ink2)
        subtitleLabel.content = String(
            localized: "A personal energy coach for your WG, timed to Germany's real grid data.",
            comment: "Welcome subheadline"
        )

        headStack.axis = .vertical
        headStack.spacing = Metrics.headSpacing
        [titleLabel, subtitleLabel].forEach(headStack.addArrangedSubview)

        featureStack.axis = .vertical
        featureStack.spacing = Metrics.featureSpacing
        for (index, feature) in features.enumerated() {
            featureStack.addArrangedSubview(
                WelcomeFeatureRowView(ordinal: WelcomeFeature.ordinal(at: index), feature: feature)
            )
        }

        actionStack.axis = .vertical
        actionStack.spacing = Metrics.actionSpacing
        [getStartedButton, logInButton].forEach(actionStack.addArrangedSubview)
    }

    private func setUpLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        // Absorbs leftover height so the actions rest at the bottom.
        let spacer = UIView()
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)

        let brandRow = UIStackView(arrangedSubviews: [brandMarkView, UIView()])
        brandRow.axis = .horizontal

        let contentStack = UIStackView(arrangedSubviews: [brandRow, headStack, featureStack, spacer, actionStack])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = Metrics.sectionSpacing
        scrollView.addSubview(contentStack)

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        let bottomPadding = contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Spacing.l)
        bottomPaddingConstraint = bottomPadding

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: content.topAnchor, constant: Metrics.topPadding),
            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Spacing.m),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Spacing.m),
            contentStack.widthAnchor.constraint(equalTo: frame.widthAnchor, constant: -2 * Spacing.m),
            bottomPadding,
            // Fill at least the visible height so the spacer can push actions down.
            content.heightAnchor.constraint(greaterThanOrEqualTo: frame.heightAnchor),
        ])
    }

    private func setUpActions() {
        getStartedButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.welcomeViewControllerDidSelectGetStarted(self)
        }, for: .primaryActionTriggered)

        logInButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.welcomeViewControllerDidSelectLogIn(self)
        }, for: .primaryActionTriggered)
    }
}
