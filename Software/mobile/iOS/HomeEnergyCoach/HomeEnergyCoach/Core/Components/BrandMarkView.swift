import UIKit

/// App brand lockup: a green rounded tile with the leaf icon, followed by the app name.
final class BrandMarkView: UIView {
    private enum Metrics {
        static let tileSize: CGFloat = 32
        static let iconSize: CGFloat = 18
    }

    private let tileView = UIView()
    private let iconView = UIImageView(image: UIImage(resource: .iconLeaf))
    private let titleLabel = StyledLabel(style: .headline, color: AppColor.ink, numberOfLines: 1)

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.content = title
        setUpLayout()
        setUpAccessibility(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUpLayout() {
        tileView.translatesAutoresizingMaskIntoConstraints = false
        tileView.backgroundColor = AppColor.green
        tileView.layer.cornerRadius = CornerRadius.tile
        tileView.layer.cornerCurve = .continuous

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        tileView.addSubview(iconView)
        addSubview(tileView)
        addSubview(titleLabel)

        // Hug the 32pt tile; grow only if Dynamic Type makes the title taller.
        let preferredHeight = heightAnchor.constraint(equalToConstant: Metrics.tileSize)
        preferredHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            preferredHeight,
            tileView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tileView.centerYAnchor.constraint(equalTo: centerYAnchor),
            tileView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            tileView.widthAnchor.constraint(equalToConstant: Metrics.tileSize),
            tileView.heightAnchor.constraint(equalToConstant: Metrics.tileSize),

            iconView.centerXAnchor.constraint(equalTo: tileView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: tileView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Metrics.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Metrics.iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: tileView.trailingAnchor, constant: Spacing.xs),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        ])
    }

    private func setUpAccessibility(title: String) {
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .header
    }
}
