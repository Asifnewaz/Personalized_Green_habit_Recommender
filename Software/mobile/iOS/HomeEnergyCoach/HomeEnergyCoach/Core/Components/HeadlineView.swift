import UIKit

/// Screen heading: a `v4/H1` title with an optional `v4/Body` subtitle below (8pt gap).
final class HeadlineView: UIView {
    init(title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = StyledLabel(style: .h1, color: AppColor.ink)
        titleLabel.content = title
        titleLabel.accessibilityTraits = .header

        let stack = UIStackView(arrangedSubviews: [titleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        if let subtitle {
            let subtitleLabel = StyledLabel(style: .body, color: AppColor.ink2)
            subtitleLabel.content = subtitle
            stack.addArrangedSubview(subtitleLabel)
        }
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
