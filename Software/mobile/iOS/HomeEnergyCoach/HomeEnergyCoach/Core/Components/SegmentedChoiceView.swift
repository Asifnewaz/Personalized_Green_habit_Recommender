import UIKit

/// Equal-width segmented picker on a `card` track (Figma O6 "Nudges per week").
/// Selected segment: `brand` fill with `on-ink` text; others `ink-2` text.
final class SegmentedChoiceView: UIView {
    private let segments: [UIButton]
    private(set) var selectedIndex: Int?

    var onSelectionChange: ((Int) -> Void)?

    init(options: [String], selectedIndex: Int? = nil) {
        segments = options.map { title in
            let button = UIButton()
            var config = UIButton.Configuration.plain()
            config.cornerStyle = .fixed
            config.background.cornerRadius = 10
            config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 4, bottom: 9, trailing: 4)
            button.configuration = config
            button.configurationUpdateHandler = { button in
                guard var config = button.configuration else { return }
                config.background.backgroundColor = button.isSelected ? AppColor.brand : .clear
                config.attributedTitle = AttributedString(TextStyle.label.attributedString(
                    title,
                    color: (button.isSelected ? AppColor.onInk : AppColor.ink2).withAlphaComponent(button.isHighlighted ? 0.7 : 1),
                    alignment: .center,
                    lineBreakMode: .byTruncatingTail,
                    compatibleWith: button.traitCollection
                ))
                button.configuration = config
            }
            return button
        }
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AppColor.card
        layer.cornerRadius = CornerRadius.field
        layer.cornerCurve = .continuous

        let stack = UIView.stack(segments, axis: .horizontal, distribution: .fillEqually)
        addSubview(stack)
        stack.pinEdges(to: self, insets: NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

        for (index, segment) in segments.enumerated() {
            segment.addAction(UIAction { [weak self] _ in
                self?.select(index)
                self?.onSelectionChange?(index)
            }, for: .primaryActionTriggered)
        }
        select(selectedIndex)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func select(_ index: Int?) {
        selectedIndex = index
        for (segmentIndex, segment) in segments.enumerated() {
            segment.isSelected = segmentIndex == index
        }
    }
}

/// Title + subtitle with a trailing `UISwitch` tinted `brand`.
final class ToggleRowView: UIView {
    let toggle = UISwitch()

    init(title: String, subtitle: String? = nil, isOn: Bool = false, titleStyle: TextStyle = .headline) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = StyledLabel(style: titleStyle, color: AppColor.ink)
        titleLabel.content = title
        let subtitleLabel = StyledLabel(style: .caption, color: AppColor.ink2)
        subtitleLabel.content = subtitle
        subtitleLabel.isHidden = subtitle == nil
        let text = UIView.stack([titleLabel, subtitleLabel], spacing: 2)

        toggle.isOn = isOn
        toggle.onTintColor = AppColor.brand
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)
        // VoiceOver reads the switch with its context; the labels stay out of the way.
        toggle.accessibilityLabel = title
        toggle.accessibilityHint = subtitle
        titleLabel.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = false

        let row = UIView.stack([text, toggle], axis: .horizontal, spacing: 12, alignment: .center)
        addSubview(row)
        row.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
