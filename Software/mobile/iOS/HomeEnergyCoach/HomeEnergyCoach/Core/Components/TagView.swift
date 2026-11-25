import UIKit

/// Non-interactive capsule tag, e.g. "Personalises", "H05", "+18% vs last week".
final class TagView: UIView {
    private let label: StyledLabel

    init(
        text: String,
        style: TextStyle = .label,
        textColor: UIColor = AppColor.ink,
        backgroundColor: UIColor,
        borderColor: UIColor? = nil
    ) {
        label = StyledLabel(style: style, color: textColor, numberOfLines: 1)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = backgroundColor
        if let borderColor {
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 1
        }

        label.content = text
        addSubview(label)
        label.pinEdges(to: self, insets: NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))

        for view in [self, label] as [UIView] {
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        isAccessibilityElement = true
        accessibilityLabel = text
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    /// Habit-code tag, e.g. "H01": Geist Mono on `bg` with a `line` border.
    static func code(_ code: String) -> TagView {
        TagView(text: code, style: .meta, textColor: AppColor.ink, backgroundColor: AppColor.background, borderColor: AppColor.line)
    }
}

/// Rounded container (20pt radius) with padding around a single content view.
final class CardView: UIView {
    init(content: UIView, backgroundColor: UIColor = AppColor.card,
         insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = backgroundColor
        layer.cornerRadius = CornerRadius.card
        layer.cornerCurve = .continuous
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        content.pinEdges(to: self, insets: insets)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension UIView {
    /// Pins all four edges to `view`, with optional insets.
    func pinEdges(to view: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.trailing),
        ])
    }

    /// Convenience vertical/horizontal stack builder used across feature views.
    static func stack(
        _ views: [UIView],
        axis: NSLayoutConstraint.Axis = .vertical,
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = axis
        stack.spacing = spacing
        stack.alignment = alignment
        stack.distribution = distribution
        return stack
    }
}
