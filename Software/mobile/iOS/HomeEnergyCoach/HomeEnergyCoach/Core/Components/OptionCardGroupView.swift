import UIKit

/// Selectable card with a title, subtitle and radio indicator.
/// Selected: `brand` fill with a check; unselected: `card` fill with an `ink-3` ring.
final class OptionCard: UIControl {
    private enum Metrics {
        static let indicatorSize: CGFloat = 22
        static let checkSize: CGFloat = 14
        static let ringWidth: CGFloat = 1.5
    }

    private let titleLabel = StyledLabel(style: .headline)
    private let subtitleLabel = StyledLabel(style: .caption)
    private let indicator = UIView()
    private let checkView = UIImageView(image: UIImage(resource: .iconCheck))

    override var isSelected: Bool {
        didSet { applyState() }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1 }
    }

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = CornerRadius.card
        layer.cornerCurve = .continuous
        titleLabel.content = title
        subtitleLabel.content = subtitle

        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.layer.cornerRadius = Metrics.indicatorSize / 2
        checkView.translatesAutoresizingMaskIntoConstraints = false
        indicator.addSubview(checkView)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [textStack, indicator])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isUserInteractionEnabled = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.s),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.s),
            indicator.widthAnchor.constraint(equalToConstant: Metrics.indicatorSize),
            indicator.heightAnchor.constraint(equalToConstant: Metrics.indicatorSize),
            checkView.centerXAnchor.constraint(equalTo: indicator.centerXAnchor),
            checkView.centerYAnchor.constraint(equalTo: indicator.centerYAnchor),
            checkView.widthAnchor.constraint(equalToConstant: Metrics.checkSize),
            checkView.heightAnchor.constraint(equalToConstant: Metrics.checkSize),
        ])

        isAccessibilityElement = true
        accessibilityLabel = "\(title), \(subtitle)"
        applyState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyState() {
        backgroundColor = isSelected ? AppColor.brand : AppColor.card
        titleLabel.styledColor = isSelected ? AppColor.onInk : AppColor.ink
        subtitleLabel.styledColor = isSelected ? AppColor.onInk2 : AppColor.ink2
        indicator.backgroundColor = isSelected ? AppColor.green : .clear
        indicator.layer.borderWidth = isSelected ? 0 : Metrics.ringWidth
        indicator.layer.borderColor = AppColor.ink3.cgColor
        checkView.isHidden = !isSelected
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}

/// Vertical list of `OptionCard`s with single or multiple selection.
final class OptionCardGroupView: UIView {
    private let cards: [OptionCard]
    private let allowsMultipleSelection: Bool
    private(set) var selectedIndices: Set<Int> = []

    /// The selected card in single-selection mode.
    var selectedIndex: Int? { selectedIndices.first }

    /// Called with the tapped index after the selection has been updated.
    var onSelectionChange: ((Int) -> Void)?

    init(options: [(title: String, subtitle: String)], selectedIndices: Set<Int> = [], allowsMultipleSelection: Bool = false) {
        cards = options.map { OptionCard(title: $0.title, subtitle: $0.subtitle) }
        self.allowsMultipleSelection = allowsMultipleSelection
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: cards)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.pinEdges(to: self)

        for (index, card) in cards.enumerated() {
            card.addAction(UIAction { [weak self] _ in self?.didTap(index) }, for: .touchUpInside)
        }
        select(selectedIndices)
    }

    convenience init(options: [(title: String, subtitle: String)], selectedIndex: Int?) {
        self.init(options: options, selectedIndices: selectedIndex.map { [$0] } ?? [])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func select(_ indices: Set<Int>) {
        selectedIndices = indices
        for (index, card) in cards.enumerated() {
            card.isSelected = indices.contains(index)
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
}
