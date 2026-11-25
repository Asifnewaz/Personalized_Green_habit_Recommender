import UIKit

/// Figma `v4 O7 Your plan` — the personalised plan summary that ends setup.
final class YourPlanViewController: FormScreenViewController {
    /// Called when the user starts their plan.
    var onStart: (() -> Void)?

    private let plan: PlanSummary
    private let footprintBar = ProgressBarView(
        height: 6,
        trackColor: UIColor.white.withAlphaComponent(0.14),
        fillColor: AppColor.green
    )
    private let startButton = AppButton(kind: .primary, title: String(localized: "Start my plan", comment: "Plan summary primary action"))
    private var hasAnimatedBar = false

    init(plan: PlanSummary) {
        self.plan = plan
        super.init(navigationTitle: nil, topPadding: 20, blockSpacing: 14)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sectionLabel = StyledLabel(style: .meta, color: AppColor.ink3, numberOfLines: 1)
        sectionLabel.content = String(localized: "Your first \(plan.firstHabits.count) habits", comment: "Plan summary section")
        sectionLabel.accessibilityTraits = .header

        setContent(
            [
                makeHead(),
                makeTags(),
                makeFootprintCard(),
                sectionLabel,
                UIView.stack(plan.firstHabits.map(RecommendedHabitRowView.init(habit:)), spacing: 8),
            ],
            actions: [startButton]
        )

        startButton.addAction(UIAction { [weak self] _ in self?.onStart?() }, for: .primaryActionTriggered)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimatedBar else { return }
        hasAnimatedBar = true
        footprintBar.animateFill(delay: 0.2)
    }

    // MARK: - Sections

    private func makeHead() -> UIView {
        let eyebrow = StyledLabel(style: .meta, color: AppColor.ink3, numberOfLines: 1)
        eyebrow.content = String(localized: "Your plan is ready", comment: "Plan summary eyebrow")
        let headline = HeadlineView(title: plan.headline, subtitle: plan.explanation)
        return UIView.stack([eyebrow, headline], spacing: 8)
    }

    private func makeTags() -> UIView {
        let tags = UIView.stack(
            [
                TagView(text: plan.userTypeName, backgroundColor: AppColor.lime),
                TagView(text: plan.userTypeSource, textColor: AppColor.ink2, backgroundColor: AppColor.card),
                UIView(),
            ],
            axis: .horizontal,
            spacing: 8,
            alignment: .center
        )
        return tags
    }

    private func makeFootprintCard() -> UIView {
        let eyebrow = StyledLabel(style: .meta, color: AppColor.onInk2, numberOfLines: 1)
        eyebrow.content = String(localized: "Estimated footprint", comment: "Footprint card title")

        let value = StyledLabel(style: .stat, color: AppColor.onInk, numberOfLines: 1)
        value.content = "\(plan.footprintKgPerMonth)"
        value.setContentHuggingPriority(.required, for: .horizontal)
        let unit = StyledLabel(style: .headline, color: AppColor.onInk2, numberOfLines: 1)
        unit.content = String(localized: "kg CO₂ / month", comment: "Footprint unit")
        let valueRow = UIView.stack([value, unit], axis: .horizontal, spacing: 8, alignment: .firstBaseline)

        let comparison = StyledLabel(style: .caption, color: AppColor.onInk2, numberOfLines: 1)
        comparison.content = String(
            localized: "Your WG vs. similar WGs (\(plan.similarWGsKgPerMonth) kg)",
            comment: "Footprint comparison"
        )
        let ownValue = StyledLabel(style: .label, color: AppColor.onInk, numberOfLines: 1)
        ownValue.content = String(localized: "\(plan.footprintKgPerMonth) kg", comment: "Footprint value in kg")
        ownValue.setContentHuggingPriority(.required, for: .horizontal)
        ownValue.setContentCompressionResistancePriority(.required, for: .horizontal)
        let comparisonRow = UIView.stack([comparison, ownValue], axis: .horizontal, spacing: 8, alignment: .center)

        footprintBar.progress = plan.footprintRatio

        let card = CardView(
            content: UIView.stack([eyebrow, valueRow, comparisonRow, footprintBar], spacing: 12),
            backgroundColor: AppColor.brand
        )
        card.isAccessibilityElement = true
        card.accessibilityLabel = String(
            localized: "Estimated footprint: \(plan.footprintKgPerMonth) kilograms CO₂ per month. Similar WGs: \(plan.similarWGsKgPerMonth) kilograms.",
            comment: "Footprint card accessibility summary"
        )
        return card
    }
}

/// One recommended habit: code tag, title, reason and a 3-dot strength indicator.
final class RecommendedHabitRowView: UIView {
    init(habit: RecommendedHabit) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let code = TagView(
            text: habit.code, style: .meta, textColor: AppColor.ink,
            backgroundColor: AppColor.background, borderColor: AppColor.line
        )
        let title = StyledLabel(style: .bodyStrong, color: AppColor.ink)
        title.content = habit.title
        let reason = StyledLabel(style: .caption, color: AppColor.ink2)
        reason.content = habit.reason
        let text = UIView.stack([title, reason], spacing: 2)
        text.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = UIView.stack(
            [code, text, StrengthDotsView(level: habit.strength)],
            axis: .horizontal, spacing: 12, alignment: .center
        )
        let card = CardView(content: row, insets: NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        addSubview(card)
        card.pinEdges(to: self)

        isAccessibilityElement = true
        accessibilityLabel = String(
            localized: "\(habit.code), \(habit.title). \(habit.reason). Fit \(habit.strength) of 3.",
            comment: "Recommended habit accessibility summary"
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
