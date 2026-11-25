import UIKit

/// Segmented progress bar with an `ink-3` "STEP n OF 6" meta label beneath.
final class StepProgressHeaderView: UIView {
    init(step: Int, totalSteps: Int = PlanSetupDraft.totalSteps) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let bar = SegmentedProgressView(segmentCount: totalSteps, filledColor: AppColor.brand)
        bar.filledCount = step

        let title = PlanSetupStep.title(step: step, of: totalSteps)
        let label = StyledLabel(style: .meta, color: AppColor.ink3, numberOfLines: 1)
        label.content = title

        let stack = UIStackView(arrangedSubviews: [bar, label])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.pinEdges(to: self)

        isAccessibilityElement = true
        accessibilityLabel = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Lime "Personalises" tag followed by a caption explaining what the answer affects.
final class PersonalisesNoteView: UIView {
    init(text: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let tagTitle = String(localized: "Personalises", comment: "Tag explaining what a setup answer affects")
        let tag = StyledLabel(style: .label, color: AppColor.ink, numberOfLines: 1)
        tag.content = tagTitle
        let tagBackground = UIView()
        tagBackground.backgroundColor = AppColor.lime
        tagBackground.layer.cornerRadius = 15
        tagBackground.layer.cornerCurve = .continuous
        tagBackground.addSubview(tag)
        tag.setContentHuggingPriority(.required, for: .horizontal)
        tag.setContentCompressionResistancePriority(.required, for: .horizontal)

        let caption = StyledLabel(style: .caption, color: AppColor.ink2)
        caption.content = text
        caption.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [tagBackground, caption])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        addSubview(stack)
        stack.pinEdges(to: self)

        NSLayoutConstraint.activate([
            tag.topAnchor.constraint(equalTo: tagBackground.topAnchor, constant: 6),
            tag.bottomAnchor.constraint(equalTo: tagBackground.bottomAnchor, constant: -6),
            tag.leadingAnchor.constraint(equalTo: tagBackground.leadingAnchor, constant: 12),
            tag.trailingAnchor.constraint(equalTo: tagBackground.trailingAnchor, constant: -12),
        ])

        isAccessibilityElement = true
        accessibilityLabel = "\(tagTitle) \(text)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// `v4/Headline` section title above arbitrary content (10pt gap), e.g. "Flat size" + chips.
final class LabeledSectionView: UIView {
    init(title: String, content: UIView) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let label = StyledLabel(style: .headline, color: AppColor.ink)
        label.content = title
        label.accessibilityTraits = .header

        let stack = UIStackView(arrangedSubviews: [label, content])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = Spacing.xs
        addSubview(stack)
        stack.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Card with the household-size stepper and one avatar per possible flatmate.
final class HouseholdSizeCardView: UIView {
    private enum Metrics {
        static let avatarSize: CGFloat = 36
        static let iconSize: CGFloat = 18
    }

    let stepper: StepperView
    private var avatars: [(background: UIView, icon: UIImageView)] = []

    init(value: Int, range: ClosedRange<Int>) {
        stepper = StepperView(value: value, range: range)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AppColor.card
        layer.cornerRadius = CornerRadius.card
        layer.cornerCurve = .continuous

        let title = String(localized: "People", comment: "Household size title")
        let titleLabel = StyledLabel(style: .headline, color: AppColor.ink)
        titleLabel.content = title
        let subtitleLabel = StyledLabel(style: .caption, color: AppColor.ink2)
        subtitleLabel.content = String(localized: "Including you", comment: "Household size subtitle")

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        stepper.accessibilityLabel = String(localized: "People including you", comment: "Household stepper accessibility label")
        stepper.setContentHuggingPriority(.required, for: .horizontal)
        stepper.setContentCompressionResistancePriority(.required, for: .horizontal)

        let topRow = UIStackView(arrangedSubviews: [textStack, stepper])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8

        let avatarRow = UIStackView()
        avatarRow.axis = .horizontal
        avatarRow.spacing = 8
        avatarRow.isAccessibilityElement = false
        avatarRow.accessibilityElementsHidden = true // the stepper already conveys the count
        for _ in range {
            let background = UIView()
            background.layer.cornerRadius = Metrics.avatarSize / 2
            let icon = UIImageView()
            icon.translatesAutoresizingMaskIntoConstraints = false
            background.addSubview(icon)
            NSLayoutConstraint.activate([
                background.widthAnchor.constraint(equalToConstant: Metrics.avatarSize),
                background.heightAnchor.constraint(equalToConstant: Metrics.avatarSize),
                icon.centerXAnchor.constraint(equalTo: background.centerXAnchor),
                icon.centerYAnchor.constraint(equalTo: background.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: Metrics.iconSize),
                icon.heightAnchor.constraint(equalToConstant: Metrics.iconSize),
            ])
            avatarRow.addArrangedSubview(background)
            avatars.append((background, icon))
        }
        avatarRow.addArrangedSubview(UIView())

        let stack = UIStackView(arrangedSubviews: [topRow, avatarRow])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14
        addSubview(stack)
        stack.pinEdges(to: self, insets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))

        setCount(value)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCount(_ count: Int) {
        for (index, avatar) in avatars.enumerated() {
            let isFilled = index < count
            avatar.background.backgroundColor = isFilled ? AppColor.brand : AppColor.background
            avatar.icon.image = UIImage(resource: isFilled ? .iconUserFilled : .iconUserEmpty)
        }
    }
}

/// Lime callout with a big `v4/Stat` figure and a caption (Figma O3 "2/3 …").
final class StatCalloutView: UIView {
    init(stat: String, caption: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let statLabel = StyledLabel(style: .stat, color: AppColor.ink, numberOfLines: 1)
        statLabel.content = stat
        statLabel.setContentHuggingPriority(.required, for: .horizontal)
        statLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let captionLabel = StyledLabel(style: .caption, color: AppColor.ink)
        captionLabel.content = caption

        let card = CardView(
            content: UIView.stack([statLabel, captionLabel], axis: .horizontal, spacing: 14, alignment: .center),
            backgroundColor: AppColor.lime
        )
        addSubview(card)
        card.pinEdges(to: self)

        isAccessibilityElement = true
        accessibilityLabel = "\(stat) \(caption)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Card of labelled steppers separated by hairlines (Figma O4 "Laundry loads per week").
final class StepperRowsCardView: UIView {
    struct Row {
        let title: String
        let value: Int
        let range: ClosedRange<Int>
    }

    private(set) var steppers: [StepperView] = []
    private var rowViews: [UIView] = []
    private var dividers: [UIView] = []

    init(rows: [Row]) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let stack = UIView.stack([])
        for (index, row) in rows.enumerated() {
            let divider = UIView()
            divider.backgroundColor = AppColor.line
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            if index > 0 { stack.addArrangedSubview(divider) }
            dividers.append(divider)

            let label = StyledLabel(style: .headline, color: AppColor.ink)
            label.content = row.title
            label.isAccessibilityElement = false
            let stepper = StepperView(value: row.value, range: row.range)
            stepper.accessibilityLabel = row.title
            stepper.setContentHuggingPriority(.required, for: .horizontal)
            stepper.setContentCompressionResistancePriority(.required, for: .horizontal)

            let rowStack = UIView.stack([label, stepper], axis: .horizontal, spacing: 12, alignment: .center)
            let rowContainer = UIView()
            rowContainer.addSubview(rowStack)
            rowStack.pinEdges(to: rowContainer, insets: NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            stack.addArrangedSubview(rowContainer)

            steppers.append(stepper)
            rowViews.append(rowContainer)
        }

        let card = CardView(
            content: stack,
            insets: NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)
        )
        addSubview(card)
        card.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Shows only the rows in `visible`; hides the whole card when none remain.
    func setVisibleRows(_ visible: Set<Int>) {
        var hasVisibleRowAbove = false
        for index in rowViews.indices {
            let isVisible = visible.contains(index)
            rowViews[index].isHidden = !isVisible
            dividers[index].isHidden = !(isVisible && hasVisibleRowAbove)
            hasVisibleRowAbove = hasVisibleRowAbove || isVisible
        }
        isHidden = visible.isEmpty
    }
}

/// "When are you usually home?" grid: day parts × weekdays/weekend toggles (Figma O5).
final class AvailabilityGridView: UIView {
    private enum Metrics {
        static let labelColumnWidth: CGFloat = 92
        static let cellHeight: CGFloat = 38
        static let cellRadius: CGFloat = 10
        static let checkSize: CGFloat = 16
    }

    private var cells: [HomeSlot: UIButton] = [:]
    private(set) var selection: Set<HomeSlot>

    var onChange: ((Set<HomeSlot>) -> Void)?

    init(selection: Set<HomeSlot>) {
        self.selection = selection
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let header = UIView.stack([Self.fixedWidthSpacer()], axis: .horizontal, spacing: 8)
        for day in DayType.allCases {
            let label = StyledLabel(style: .meta, color: AppColor.ink2, numberOfLines: 1)
            label.textAlignment = .center
            label.content = day.title
            label.isAccessibilityElement = false
            header.addArrangedSubview(label)
        }
        header.distribution = .fill
        Self.equalizeColumns(in: header)

        let grid = UIView.stack([header], spacing: 8)
        for part in DayPart.allCases {
            let partLabel = StyledLabel(style: .label, color: AppColor.ink, numberOfLines: 1)
            partLabel.content = part.title
            let hoursLabel = StyledLabel(style: .caption, color: AppColor.ink3, numberOfLines: 1)
            hoursLabel.content = part.hours
            let labelColumn = UIView.stack([partLabel, hoursLabel])
            labelColumn.widthAnchor.constraint(equalToConstant: Metrics.labelColumnWidth).isActive = true
            labelColumn.isAccessibilityElement = false
            labelColumn.accessibilityElementsHidden = true

            let row = UIView.stack([labelColumn], axis: .horizontal, spacing: 8, alignment: .center)
            for day in DayType.allCases {
                let slot = HomeSlot(part: part, days: day)
                let cell = makeCell(for: slot)
                cells[slot] = cell
                row.addArrangedSubview(cell)
            }
            Self.equalizeColumns(in: row)
            grid.addArrangedSubview(row)
        }

        let card = CardView(content: grid, insets: NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        addSubview(card)
        card.pinEdges(to: self)
        render()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func makeCell(for slot: HomeSlot) -> UIButton {
        let cell = UIButton()
        var config = UIButton.Configuration.plain()
        config.cornerStyle = .fixed
        config.background.cornerRadius = Metrics.cellRadius
        cell.configuration = config
        cell.configurationUpdateHandler = { button in
            guard var config = button.configuration else { return }
            config.background.backgroundColor = button.isSelected ? AppColor.brand : AppColor.background
            config.image = button.isSelected ? UIImage(resource: .iconCheckSlot) : nil
            button.configuration = config
            button.alpha = button.isHighlighted ? 0.8 : 1
        }
        cell.heightAnchor.constraint(equalToConstant: Metrics.cellHeight).isActive = true
        cell.accessibilityLabel = "\(slot.part.title) \(slot.part.hours), \(slot.days.title)"
        cell.addAction(UIAction { [weak self] _ in self?.toggle(slot) }, for: .primaryActionTriggered)
        return cell
    }

    private func toggle(_ slot: HomeSlot) {
        if selection.contains(slot) { selection.remove(slot) } else { selection.insert(slot) }
        render()
        UISelectionFeedbackGenerator().selectionChanged()
        onChange?(selection)
    }

    private func render() {
        for (slot, cell) in cells {
            cell.isSelected = selection.contains(slot)
        }
    }

    private static func fixedWidthSpacer() -> UIView {
        let spacer = UIView()
        spacer.widthAnchor.constraint(equalToConstant: Metrics.labelColumnWidth).isActive = true
        return spacer
    }

    /// Makes every column after the label column share the remaining width equally.
    private static func equalizeColumns(in row: UIStackView) {
        let columns = row.arrangedSubviews.dropFirst()
        guard let first = columns.first else { return }
        for column in columns.dropFirst() {
            column.widthAnchor.constraint(equalTo: first.widthAnchor).isActive = true
        }
    }
}
