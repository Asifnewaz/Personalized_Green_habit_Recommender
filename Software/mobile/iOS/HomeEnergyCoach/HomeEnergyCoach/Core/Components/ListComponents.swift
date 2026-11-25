import UIKit

/// One padded row inside a `DividedListCard`. Becomes a tappable control when `isTappable`.
final class ListRow: UIControl {
    private let isTappable: Bool

    init(content: UIView, verticalPadding: CGFloat = 12, isTappable: Bool = false) {
        self.isTappable = isTappable
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        content.pinEdges(to: self, insets: NSDirectionalEdgeInsets(top: verticalPadding, leading: 0, bottom: verticalPadding, trailing: 0))
        if isTappable {
            content.isUserInteractionEnabled = false
            isAccessibilityElement = true
            accessibilityTraits = .button
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { if isTappable { alpha = isHighlighted ? 0.6 : 1 } }
    }
}

/// `card` surface listing rows separated by 1pt `line` hairlines (Figma: 20pt sides).
final class DividedListCard: UIView {
    init(rows: [UIView], verticalInset: CGFloat = 4) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let stack = UIView.stack([])
        for (index, row) in rows.enumerated() {
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = AppColor.line
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(divider)
            }
            stack.addArrangedSubview(row)
        }
        let card = CardView(content: stack, insets: NSDirectionalEdgeInsets(top: verticalInset, leading: 20, bottom: verticalInset, trailing: 20))
        addSubview(card)
        card.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Habit list row content: code tag, `Body strong` title over a caption, optional trailing view.
final class HabitRowContentView: UIView {
    init(code: String?, title: String, subtitle: String?, trailing: UIView? = nil, leading: UIView? = nil,
         titleColor: UIColor = AppColor.ink, strikethrough: Bool = false) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = StyledLabel(style: .bodyStrong, color: titleColor)
        titleLabel.content = title
        if strikethrough, let text = titleLabel.attributedText {
            let struck = NSMutableAttributedString(attributedString: text)
            struck.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: struck.length))
            titleLabel.attributedText = struck
        }
        let subtitleLabel = StyledLabel(style: .caption, color: AppColor.ink2)
        subtitleLabel.content = subtitle
        subtitleLabel.isHidden = subtitle == nil
        let text = UIView.stack([titleLabel, subtitleLabel], spacing: 2)
        text.setContentHuggingPriority(.defaultLow, for: .horizontal)
        text.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        var views: [UIView] = []
        if let leading {
            leading.setContentHuggingPriority(.required, for: .horizontal)
            leading.setContentCompressionResistancePriority(.required, for: .horizontal)
            views.append(leading)
        }
        if let code { views.append(TagView.code(code)) }
        views.append(text)
        if let trailing {
            trailing.setContentHuggingPriority(.required, for: .horizontal)
            trailing.setContentCompressionResistancePriority(.required, for: .horizontal)
            views.append(trailing)
        }
        let row = UIView.stack(views, axis: .horizontal, spacing: 12, alignment: .center)
        addSubview(row)
        row.pinEdges(to: self)

        accessibilityLabel = [code, title, subtitle].compactMap { $0 }.joined(separator: ", ")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Green 22pt check circle followed by `v4/Body` text and an optional trailing code.
final class CheckBulletRow: UIView {
    init(text: String, trailingCode: String? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let badge = UIView()
        badge.backgroundColor = AppColor.green
        badge.layer.cornerRadius = 11
        let check = UIImageView(image: UIImage(resource: .iconCheck))
        check.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(check)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 22),
            badge.heightAnchor.constraint(equalToConstant: 22),
            check.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
        ])

        let label = StyledLabel(style: .body, color: AppColor.ink)
        label.content = text
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)

        var views: [UIView] = [badge, label]
        if let trailingCode {
            let code = StyledLabel(style: .meta, color: AppColor.ink3, numberOfLines: 1)
            code.content = trailingCode
            code.setContentHuggingPriority(.required, for: .horizontal)
            code.setContentCompressionResistancePriority(.required, for: .horizontal)
            views.append(code)
        }
        let row = UIView.stack(views, axis: .horizontal, spacing: 10, alignment: .center)
        addSubview(row)
        row.pinEdges(to: self)

        isAccessibilityElement = true
        accessibilityLabel = text
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Rounded tile with a `v4/Stat` value and caption lines. `isEmphasized` switches to the
/// `brand` style; set `isSelected` to toggle it when used as a filter.
final class StatTileView: UIControl {
    private let valueLabel = StyledLabel(style: .stat, numberOfLines: 1)
    private let titleLabel = StyledLabel(style: .label)
    private let subtitleLabel = StyledLabel(style: .caption)
    private let emphasizedValueColor: UIColor?
    private let isInteractive: Bool

    var isEmphasized: Bool { didSet { applyStyle() } }

    override var isSelected: Bool {
        didSet { isEmphasized = isSelected }
    }

    override var isHighlighted: Bool {
        didSet { if isInteractive { alpha = isHighlighted ? 0.8 : 1 } }
    }

    init(value: String, title: String? = nil, subtitle: String? = nil, isEmphasized: Bool = false,
         emphasizedValueColor: UIColor? = nil, padding: CGFloat = 14, isInteractive: Bool = false) {
        self.isEmphasized = isEmphasized
        self.emphasizedValueColor = emphasizedValueColor
        self.isInteractive = isInteractive
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = CornerRadius.card
        layer.cornerCurve = .continuous

        valueLabel.content = value
        titleLabel.content = title
        titleLabel.isHidden = title == nil
        subtitleLabel.content = subtitle
        subtitleLabel.isHidden = subtitle == nil

        let stack = UIView.stack([valueLabel, titleLabel, subtitleLabel, UIView()], spacing: 2)
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.pinEdges(to: self, insets: NSDirectionalEdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding))

        isAccessibilityElement = true
        accessibilityLabel = [value, title, subtitle].compactMap { $0 }.joined(separator: " ")
        if isInteractive { accessibilityTraits = .button }
        applyStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Updates the big value (e.g. after the underlying data changes).
    func setValue(_ value: String) {
        valueLabel.content = value
    }

    private func applyStyle() {
        backgroundColor = isEmphasized ? AppColor.brand : AppColor.card
        valueLabel.styledColor = isEmphasized ? (emphasizedValueColor ?? AppColor.onInk) : AppColor.ink
        titleLabel.styledColor = isEmphasized ? AppColor.onInk : AppColor.ink
        subtitleLabel.styledColor = isEmphasized ? AppColor.onInk2 : AppColor.ink2
        if isInteractive {
            accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }
}

/// Wraps arranged views onto new lines when they don't fit (Figma `flex-wrap`).
final class FlowLayoutView: UIView {
    private let views: [UIView]
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    private var contentHeight: CGFloat = 0

    init(views: [UIView], horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.views = views
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = true
            addSubview($0)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        for view in views {
            var size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            size.width = min(size.width, bounds.width)
            if origin.x > 0, origin.x + size.width > bounds.width {
                origin = CGPoint(x: 0, y: origin.y + rowHeight + verticalSpacing)
                rowHeight = 0
            }
            view.frame = CGRect(origin: origin, size: size)
            origin.x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        let height = views.isEmpty ? 0 : origin.y + rowHeight
        if height != contentHeight {
            contentHeight = height
            invalidateIntrinsicContentSize()
        }
    }
}

extension StyledLabel {
    /// Section eyebrow in `v4/Meta` / `ink-3`, e.g. "ALSO GOOD FOR YOU".
    static func section(_ text: String, color: UIColor = AppColor.ink3) -> StyledLabel {
        let label = StyledLabel(style: .meta, color: color)
        label.content = text
        label.accessibilityTraits = .header
        return label
    }

    /// Convenience for a label with content set.
    static func make(_ text: String?, style: TextStyle, color: UIColor = AppColor.ink, lines: Int = 0) -> StyledLabel {
        let label = StyledLabel(style: style, color: color, numberOfLines: lines)
        label.content = text
        return label
    }
}
