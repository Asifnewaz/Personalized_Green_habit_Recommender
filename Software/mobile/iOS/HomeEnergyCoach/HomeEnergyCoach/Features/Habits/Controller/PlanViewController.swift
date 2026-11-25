import UIKit

/// Figma `v4 02 Plan` — the next recommended habit and alternatives.
final class PlanViewController: FormScreenViewController {
    var onStartHabit: ((String) -> Void)?
    var onDismissHabit: ((String) -> Void)?
    var onShowCatalogue: (() -> Void)?

    private let content: PlanTabContent
    private let startButton = AppButton(kind: .primary, title: String(localized: "Start habit", comment: "Plan primary action"))
    private let notNowButton = AppButton(kind: .ghost, title: String(localized: "Not now", comment: "Plan secondary action"))
    private var recommendationCard: UIView?

    init(content: PlanTabContent = .sample) {
        self.content = content
        super.init(navigationTitle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let head = UIView.stack([
            StyledLabel.section(String(localized: "Ranked for your WG", comment: "Plan eyebrow")),
            HeadlineView(title: String(localized: "Next habit for you", comment: "Plan title")),
        ], spacing: 8)

        let card = makeRecommendationCard()
        recommendationCard = card

        let alternatives = DividedListCard(rows: content.alternatives.map { suggestion in
            ListRow(content: HabitRowContentView(
                code: suggestion.code, title: suggestion.title, subtitle: suggestion.detail,
                trailing: StrengthDotsView(level: suggestion.fit)
            ))
        })

        let seeAll = TextLinkButton(title: String(localized: "See all \(HabitCatalog.all.count) habits →", comment: "Plan link to catalogue"))
        seeAll.contentHorizontalAlignment = .leading
        seeAll.addAction(UIAction { [weak self] _ in self?.onShowCatalogue?() }, for: .primaryActionTriggered)

        setContent([
            head,
            card,
            StyledLabel.section(String(localized: "Also good for you", comment: "Plan section")),
            alternatives,
            UIView.stack([seeAll, UIView()], axis: .horizontal),
        ])

        startButton.addAction(UIAction { [weak self] _ in self?.startHabit() }, for: .primaryActionTriggered)
        notNowButton.addAction(UIAction { [weak self] _ in self?.dismissRecommendation() }, for: .primaryActionTriggered)
    }

    private func makeRecommendationCard() -> UIView {
        let next = content.next
        let tags = UIView.stack([
            TagView.code(next.code),
            TagView(text: next.categoryLine, textColor: AppColor.ink2, backgroundColor: AppColor.background),
            UIView(),
        ], axis: .horizontal, spacing: 8, alignment: .center)

        let title = StyledLabel.make(next.title, style: .h2)
        title.accessibilityTraits = .header

        let reasons = next.reasons.map { CheckBulletRow(text: $0) as UIView }

        let impactValue = UIView.stack([
            StyledLabel.make(next.impact, style: .bodyStrong, lines: 1),
            StrengthDotsView(level: next.impactLevel),
            UIView(),
        ], axis: .horizontal, spacing: 6, alignment: .center)
        let facts = UIView.stack([
            Self.fact(String(localized: "Impact", comment: "Habit fact"), value: impactValue, spoken: next.impact),
            Self.fact(String(localized: "Effort", comment: "Habit fact"), value: StyledLabel.make(next.effort, style: .bodyStrong, lines: 1), spoken: next.effort),
            Self.fact(String(localized: "When", comment: "Habit fact"), value: StyledLabel.make(next.timing, style: .bodyStrong, lines: 1), spoken: next.timing),
        ], axis: .horizontal, spacing: 12, distribution: .fillEqually)

        let actions = UIView.stack([startButton, notNowButton], axis: .horizontal, spacing: 8, distribution: .fillEqually)

        return CardView(content: UIView.stack(
            [tags, title, StyledLabel.section(String(localized: "Why this is for you", comment: "Recommendation reasons header"))]
                + reasons + [facts, actions],
            spacing: 14
        ))
    }

    private static func fact(_ title: String, value: UIView, spoken: String) -> UIView {
        let stack = UIView.stack([StyledLabel.section(title), value], spacing: 4)
        stack.isAccessibilityElement = true
        stack.accessibilityLabel = "\(title): \(spoken)"
        return stack
    }

    private func startHabit() {
        startButton.title = String(localized: "Started", comment: "Plan habit started state")
        startButton.isEnabled = false
        notNowButton.isHidden = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onStartHabit?(content.next.code)
    }

    private func dismissRecommendation() {
        let animations = { self.recommendationCard?.isHidden = true; self.recommendationCard?.alpha = 0 }
        if UIAccessibility.isReduceMotionEnabled { animations() } else { UIView.animate(withDuration: 0.25, animations: animations) }
        onDismissHabit?(content.next.code)
    }
}
