import UIKit

/// Figma component `v4/Nav`: a 40pt circular back button followed by a small section title.
final class NavHeaderView: UIView {
    private enum Metrics {
        static let height: CGFloat = 48
        static let backButtonSize: CGFloat = 40
    }

    let backButton = TouchTargetButton()
    private let titleLabel = StyledLabel(style: .label, color: AppColor.ink2, numberOfLines: 1)

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.content = title

        var config = UIButton.Configuration.plain()
        config.image = UIImage(resource: .iconChevronLeft)
        config.background.backgroundColor = AppColor.card
        config.cornerStyle = .capsule
        config.contentInsets = .zero
        backButton.configuration = config
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.accessibilityLabel = String(localized: "Back", comment: "Back button accessibility label")

        addSubview(backButton)
        addSubview(titleLabel)

        let preferredHeight = heightAnchor.constraint(equalToConstant: Metrics.height)
        preferredHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            preferredHeight,
            heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.height),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: Metrics.backButtonSize),
            backButton.heightAnchor.constraint(equalToConstant: Metrics.backButtonSize),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Spacing.m),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
