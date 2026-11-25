import UIKit

/// Bottom row of the intro screens: page indicator and primary button.
final class OnboardingFooterView: UIView {
    private enum Metrics {
        /// Figma: "Next" button is 150pt wide, "Let's go" is 180pt wide.
        static let buttonWidth: CGFloat = 150
        static let finalButtonWidth: CGFloat = 180
    }

    let pageIndicator: PageIndicatorView
    let primaryButton = AppButton(kind: .primary, title: "")
    private let buttonWidthConstraint: NSLayoutConstraint

    init(numberOfPages: Int) {
        pageIndicator = PageIndicatorView(numberOfPages: numberOfPages)
        buttonWidthConstraint = primaryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Metrics.buttonWidth)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(pageIndicator)
        addSubview(primaryButton)

        NSLayoutConstraint.activate([
            pageIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            primaryButton.leadingAnchor.constraint(greaterThanOrEqualTo: pageIndicator.trailingAnchor, constant: Spacing.m),
            primaryButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            primaryButton.topAnchor.constraint(equalTo: topAnchor),
            primaryButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonWidthConstraint,
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(currentPage: Int, buttonTitle: String, isFinalStep: Bool, animated: Bool) {
        pageIndicator.setCurrentPage(currentPage, animated: animated)
        primaryButton.title = buttonTitle
        buttonWidthConstraint.constant = isFinalStep ? Metrics.finalButtonWidth : Metrics.buttonWidth

        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            layoutIfNeeded()
            return
        }
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0,
                       options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.layoutIfNeeded()
        }
    }
}
