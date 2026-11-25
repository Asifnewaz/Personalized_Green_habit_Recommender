import UIKit

/// Pill-style page indicator: the current page is a 28×8pt `brand` capsule,
/// other pages are 8×8pt `line` dots, separated by 6pt.
final class PageIndicatorView: UIView {
    private enum Metrics {
        static let dotSize: CGFloat = 8
        static let activeWidth: CGFloat = 28
    }

    private let stackView = UIStackView()
    private var dots: [UIView] = []
    private var widthConstraints: [NSLayoutConstraint] = []

    private(set) var numberOfPages: Int = 0
    private(set) var currentPage: Int = 0

    init(numberOfPages: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Spacing.xxs
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        isAccessibilityElement = true
        accessibilityTraits = .none
        accessibilityLabel = String(localized: "Page", comment: "Accessibility label of the onboarding page indicator")

        build(numberOfPages: numberOfPages)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCurrentPage(_ page: Int, animated: Bool) {
        guard (0..<numberOfPages).contains(page) else { return }
        currentPage = page
        let updates = { self.applyState() }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0,
                           options: [.beginFromCurrentState, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }

    private func build(numberOfPages: Int) {
        self.numberOfPages = numberOfPages
        dots = (0..<numberOfPages).map { _ in
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = CornerRadius.indicator
            dot.heightAnchor.constraint(equalToConstant: Metrics.dotSize).isActive = true
            return dot
        }
        widthConstraints = dots.map { $0.widthAnchor.constraint(equalToConstant: Metrics.dotSize) }
        NSLayoutConstraint.activate(widthConstraints)
        dots.forEach(stackView.addArrangedSubview)
        applyState()
    }

    private func applyState() {
        for (index, dot) in dots.enumerated() {
            let isActive = index == currentPage
            dot.backgroundColor = isActive ? AppColor.brand : AppColor.line
            widthConstraints[index].constant = isActive ? Metrics.activeWidth : Metrics.dotSize
        }
        layoutIfNeeded()
        accessibilityValue = String(
            localized: "\(currentPage + 1) of \(numberOfPages)",
            comment: "Accessibility value of the page indicator, e.g. '1 of 3'"
        )
    }
}
