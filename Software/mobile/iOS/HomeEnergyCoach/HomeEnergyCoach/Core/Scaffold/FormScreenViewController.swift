import UIKit

/// Shared layout for v4 screens with a `v4/Nav` header, scrolling content and
/// bottom-anchored actions (account and plan-setup screens).
///
/// Layout (from Figma): content inset 12pt top / 24pt sides, 16pt between blocks,
/// a flexible spacer, then the actions 32pt above the screen edge (never inside the
/// home-indicator area). The content scrolls when it doesn't fit and moves above
/// the keyboard. Every block plays the standard staggered entrance once.
///
/// Subclasses call `setContent(_:actions:)` from `viewDidLoad()`.
class FormScreenViewController: UIViewController {
    private let navHeader: NavHeaderView?
    private let topPadding: CGFloat
    let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var bottomPaddingConstraint: NSLayoutConstraint?
    private var hasPlayedEntrance = false

    /// - Parameters:
    ///   - navigationTitle: Title for the `v4/Nav` header; `nil` hides the header (e.g. O7, Home).
    ///   - topPadding: Gap above the first block (Figma: 12pt under the nav, 20pt without it).
    ///   - blockSpacing: Gap between blocks (Figma: 16pt, 14pt on O7).
    init(navigationTitle: String?, topPadding: CGFloat = 12, blockSpacing: CGFloat = 16) {
        navHeader = navigationTitle.map(NavHeaderView.init(title:))
        self.topPadding = topPadding
        super.init(nibName: nil, bundle: nil)
        contentStack.spacing = blockSpacing
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setUpLayout()

        navHeader?.backButton.addAction(UIAction { [weak self] _ in self?.didTapBack() }, for: .primaryActionTriggered)

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        guard !hasPlayedEntrance else { return }
        hasPlayedEntrance = true
        let steps = EntranceAnimation.cascade(contentStack.arrangedSubviews)
        EntranceAnimation.prepare(steps)
        EntranceAnimation.play(steps)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        bottomPaddingConstraint?.constant = -max(Spacing.l, view.safeAreaInsets.bottom)
    }

    // MARK: - Subclass API

    /// Installs the screen's blocks. `actions` are pinned to the bottom when content is short.
    func setContent(_ blocks: [UIView], actions: [UIView] = []) {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let spacer = UIView()
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)

        (blocks + [spacer] + actions).forEach(contentStack.addArrangedSubview)
    }

    /// Overrides the 16pt gap after `block`.
    func setSpacing(_ spacing: CGFloat, after block: UIView) {
        contentStack.setCustomSpacing(spacing, after: block)
    }

    /// Called when the nav back button is tapped. Pops by default.
    func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Layout

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setUpLayout() {
        let contentTop: NSLayoutYAxisAnchor
        if let navHeader {
            view.addSubview(navHeader)
            NSLayoutConstraint.activate([
                navHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                navHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            contentTop = navHeader.bottomAnchor
        } else {
            contentTop = view.safeAreaLayoutGuide.topAnchor
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        scrollView.addSubview(contentStack)

        // Track the keyboard; without it, extend to the screen edge (Figma padding handles the rest).
        view.keyboardLayoutGuide.usesBottomSafeArea = false

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        let bottomPadding = contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -Spacing.l)
        bottomPaddingConstraint = bottomPadding

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentTop),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            contentStack.topAnchor.constraint(equalTo: content.topAnchor, constant: topPadding),
            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Spacing.m),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Spacing.m),
            contentStack.widthAnchor.constraint(equalTo: frame.widthAnchor, constant: -2 * Spacing.m),
            bottomPadding,
            content.heightAnchor.constraint(greaterThanOrEqualTo: frame.heightAnchor),
        ])
    }
}
