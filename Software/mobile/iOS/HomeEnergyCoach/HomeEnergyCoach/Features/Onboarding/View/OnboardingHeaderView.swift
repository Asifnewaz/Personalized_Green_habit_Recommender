import UIKit

/// Top row of the intro screens: brand lockup on the leading edge,
/// secondary pill button ("Skip" / "Log in") on the trailing edge.
final class OnboardingHeaderView: UIView {
    let brandMarkView = BrandMarkView(
        title: String(localized: "Home Energy Coach", comment: "App name shown in the intro header")
    )
    let secondaryButton = PillButton(title: "")

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(brandMarkView)
        addSubview(secondaryButton)

        brandMarkView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        secondaryButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        secondaryButton.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            brandMarkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            brandMarkView.topAnchor.constraint(equalTo: topAnchor),
            brandMarkView.bottomAnchor.constraint(equalTo: bottomAnchor),

            secondaryButton.leadingAnchor.constraint(greaterThanOrEqualTo: brandMarkView.trailingAnchor, constant: Spacing.xs),
            secondaryButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            secondaryButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            secondaryButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
