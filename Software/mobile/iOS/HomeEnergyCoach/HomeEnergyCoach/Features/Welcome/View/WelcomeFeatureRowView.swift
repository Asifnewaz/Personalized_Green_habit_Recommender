import UIKit

/// A numbered feature row: green `v4/H2` ordinal, then a `v4/Headline` title
/// over a `v4/Caption` subtitle.
final class WelcomeFeatureRowView: UIView {
    init(ordinal: String, feature: WelcomeFeature) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let ordinalLabel = StyledLabel(style: .h2, color: AppColor.green, numberOfLines: 1)
        ordinalLabel.content = ordinal
        ordinalLabel.setContentHuggingPriority(.required, for: .horizontal)
        ordinalLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleLabel = StyledLabel(style: .headline, color: AppColor.ink)
        titleLabel.content = feature.title

        let subtitleLabel = StyledLabel(style: .caption, color: AppColor.ink2)
        subtitleLabel.content = feature.subtitle

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [ordinalLabel, textStack])
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.axis = .horizontal
        rowStack.alignment = .top
        rowStack.spacing = Spacing.s
        addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        // Read the row as one sentence rather than three fragments.
        isAccessibilityElement = true
        accessibilityLabel = "\(feature.title). \(feature.subtitle)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
