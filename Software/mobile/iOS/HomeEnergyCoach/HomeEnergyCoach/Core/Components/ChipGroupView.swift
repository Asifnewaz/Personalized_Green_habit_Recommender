import UIKit

/// Content of one chip: a title and an optional leading icon.
struct ChipOption {
    let title: String
    var icon: ImageResource?
}

/// Capsule chip: `brand` fill when selected, `card` otherwise.
/// Icons are tinted `lime` when selected and `ink-2` otherwise (Figma O4).
final class ChipButton: TouchTargetButton {
    private enum Metrics {
        static let iconSpacing: CGFloat = 8
    }

    let option: ChipOption

    init(option: ChipOption) {
        self.option = option
        super.init(frame: .zero)

        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        if let icon = option.icon {
            config.image = UIImage(resource: icon).withRenderingMode(.alwaysTemplate)
            config.imagePadding = Metrics.iconSpacing
            config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 14)
        } else {
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        }
        configuration = config

        configurationUpdateHandler = { button in
            guard let button = button as? ChipButton, var config = button.configuration else { return }
            let selected = button.isSelected
            let alpha: CGFloat = button.isHighlighted ? 0.7 : 1
            config.background.backgroundColor = selected ? AppColor.brand : AppColor.card
            config.baseForegroundColor = (selected ? AppColor.lime : AppColor.ink2).withAlphaComponent(alpha)
            config.attributedTitle = AttributedString(
                TextStyle.label.attributedString(
                    button.option.title,
                    color: (selected ? AppColor.onInk : AppColor.ink).withAlphaComponent(alpha),
                    lineBreakMode: .byTruncatingTail,
                    compatibleWith: button.traitCollection
                )
            )
            button.configuration = config
        }
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (button: ChipButton, _: UITraitCollection) in
            button.setNeedsUpdateConfiguration()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// A wrapping group of `ChipButton`s with single or multiple selection.
final class ChipGroupView: UIView {
    private enum Metrics {
        static let spacing: CGFloat = 8
    }

    private let chips: [ChipButton]
    private let allowsMultipleSelection: Bool
    private var contentHeight: CGFloat = 0
    private(set) var selectedIndices: Set<Int> = []

    /// The selected chip in single-selection mode.
    var selectedIndex: Int? { selectedIndices.first }

    /// Called with the tapped index after the selection has been updated.
    var onSelectionChange: ((Int) -> Void)?

    init(options: [ChipOption], selectedIndices: Set<Int> = [], allowsMultipleSelection: Bool = false) {
        self.chips = options.map(ChipButton.init(option:))
        self.allowsMultipleSelection = allowsMultipleSelection
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        for (index, chip) in chips.enumerated() {
            addSubview(chip)
            chip.addAction(UIAction { [weak self] _ in self?.didTap(index) }, for: .primaryActionTriggered)
        }
        select(selectedIndices)

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ChipGroupView, _: UITraitCollection) in
            view.setNeedsLayout()
        }
    }

    /// Single-selection group of plain text chips.
    convenience init(options: [String], selectedIndex: Int? = nil) {
        self.init(options: options.map { ChipOption(title: $0) }, selectedIndices: selectedIndex.map { [$0] } ?? [])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func select(_ indices: Set<Int>) {
        selectedIndices = indices
        for (index, chip) in chips.enumerated() {
            chip.isSelected = indices.contains(index)
        }
    }

    private func didTap(_ index: Int) {
        if allowsMultipleSelection {
            var indices = selectedIndices
            if indices.contains(index) { indices.remove(index) } else { indices.insert(index) }
            select(indices)
        } else {
            select([index])
        }
        onSelectionChange?(index)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        let height = layoutChips(in: bounds.width)
        if height != contentHeight {
            contentHeight = height
            invalidateIntrinsicContentSize()
        }
    }

    /// Flow layout: fills each row left to right, wrapping when a chip doesn't fit.
    private func layoutChips(in width: CGFloat) -> CGFloat {
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        for chip in chips {
            var size = chip.intrinsicContentSize
            size.width = min(size.width, width)
            if origin.x > 0, origin.x + size.width > width {
                origin.x = 0
                origin.y += rowHeight + Metrics.spacing
                rowHeight = 0
            }
            chip.frame = CGRect(origin: origin, size: size)
            origin.x += size.width + Metrics.spacing
            rowHeight = max(rowHeight, size.height)
        }
        return chips.isEmpty ? 0 : origin.y + rowHeight
    }
}
