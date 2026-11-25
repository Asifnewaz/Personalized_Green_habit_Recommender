import UIKit

/// Figma `v4 03 Habit` — progress, check-ins and effectiveness of one habit.
final class HabitDetailViewController: FormScreenViewController {
    /// Called after the user checks in for today.
    var onCheckIn: (() -> Void)?

    private let viewModel: HabitDetailViewModel
    private let strengthBar = ProgressBarView(height: 8, trackColor: UIColor.white.withAlphaComponent(0.14), fillColor: AppColor.lime)
    private let checkInGrid = UIView.stack([], spacing: 8)
    private let checkInButton = AppButton(kind: .primary, title: String(localized: "Check in today", comment: "Habit primary action"))
    private var hasAnimated = false

    init(viewModel: HabitDetailViewModel) {
        self.viewModel = viewModel
        super.init(navigationTitle: String(localized: "Habit", comment: "Habit detail nav title"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let detail = viewModel.detail

        let tags = UIView.stack([
            TagView.code(detail.code),
            TagView(text: detail.categoryLine, textColor: AppColor.ink2, backgroundColor: AppColor.card),
            UIView(),
        ], axis: .horizontal, spacing: 8, alignment: .center)
        let title = StyledLabel.make(detail.title, style: .h1)
        title.accessibilityTraits = .header

        setContent([tags, title, makeStrengthCard(), makeCheckInCard(), makeRemindersCard(), makeEffectCard()],
                   actions: [checkInButton])
        renderCheckIns()

        checkInButton.addAction(UIAction { [weak self] _ in self?.checkIn() }, for: .primaryActionTriggered)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimated else { return }
        hasAnimated = true
        strengthBar.animateFill(delay: 0.2)
    }

    // MARK: - Cards

    private func makeStrengthCard() -> UIView {
        strengthBar.progress = viewModel.detail.automaticity
        let value = UIView.stack([
            StyledLabel.make(viewModel.automaticityText, style: .stat, color: AppColor.onInk, lines: 1),
            StyledLabel.make(String(localized: "automatic", comment: "Habit strength unit"), style: .headline, color: AppColor.onInk2, lines: 1),
            UIView(),
        ], axis: .horizontal, spacing: 8, alignment: .firstBaseline)
        let scale = UIView.stack(
            [String(localized: "Start", comment: "Habit scale"), String(localized: "Building", comment: "Habit scale"), String(localized: "Automatic", comment: "Habit scale")]
                .map { StyledLabel.make($0, style: .meta, color: AppColor.onInk2, lines: 1) },
            axis: .horizontal, distribution: .equalSpacing
        )
        let card = CardView(content: UIView.stack([
            StyledLabel.section(String(localized: "Habit strength", comment: "Habit strength card"), color: AppColor.onInk2),
            value, strengthBar, scale,
            StyledLabel.make(viewModel.progressNote, style: .caption, color: AppColor.onInk2),
        ], spacing: 12), backgroundColor: AppColor.brand)
        card.isAccessibilityElement = true
        card.accessibilityLabel = "\(String(localized: "Habit strength", comment: "Habit strength card")): \(viewModel.automaticityText). \(viewModel.progressNote)"
        return card
    }

    private func makeCheckInCard() -> UIView {
        let days = ["M", "T", "W", "T", "F", "S", "S"].map { letter -> UIView in
            let label = StyledLabel.make(letter, style: .meta, color: AppColor.ink3, lines: 1)
            label.textAlignment = .center
            return label
        }
        let header = UIView.stack(days, axis: .horizontal, spacing: 6, distribution: .fillEqually)
        header.accessibilityElementsHidden = true
        return CardView(content: UIView.stack([
            StyledLabel.section(String(localized: "Check-ins · last 4 weeks", comment: "Check-in card")),
            header, checkInGrid,
        ], spacing: 8))
    }

    private func renderCheckIns() {
        checkInGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for week in viewModel.detail.checkIns {
            let cells = week.map { state -> UIView in
                let cell = UIView()
                cell.layer.cornerRadius = 6
                cell.backgroundColor = switch state {
                case .none: AppColor.background
                case .done: AppColor.green
                case .partial: AppColor.greenSoft
                }
                cell.heightAnchor.constraint(equalToConstant: 22).isActive = true
                return cell
            }
            checkInGrid.addArrangedSubview(UIView.stack(cells, axis: .horizontal, spacing: 6, distribution: .fillEqually))
        }
        let total = viewModel.detail.checkIns.joined().filter { $0 != .none }.count
        checkInGrid.isAccessibilityElement = true
        checkInGrid.accessibilityLabel = String(localized: "\(total) check-ins in the last 4 weeks", comment: "Check-in grid summary")

        checkInButton.isEnabled = !viewModel.hasCheckedInToday
        if viewModel.hasCheckedInToday {
            checkInButton.title = String(localized: "Checked in today", comment: "Habit primary action done")
        }
    }

    private func makeRemindersCard() -> UIView {
        let stages = viewModel.detail.reminderStages.map { stage -> UIView in
            let filled = stage.isCurrent ? AppColor.green : AppColor.ink3
            let dots = StrengthDotsView(level: stage.level, dotSize: 8, spacing: 4, filledColor: filled, emptyColor: AppColor.line)
            let stack = UIView.stack([
                UIView.stack([dots, UIView()], axis: .horizontal),
                StyledLabel.make(stage.frequency, style: .bodyStrong, color: stage.isCurrent ? AppColor.ink : AppColor.ink3, lines: 1),
                StyledLabel.make(stage.period, style: .meta, color: AppColor.ink3, lines: 1),
            ], spacing: 4)
            stack.isAccessibilityElement = true
            stack.accessibilityLabel = "\(stage.period): \(stage.frequency)"
            return stack
        }
        return CardView(content: UIView.stack([
            StyledLabel.section(String(localized: "Reminders fade as it sticks", comment: "Reminders card")),
            UIView.stack(stages, axis: .horizontal, spacing: 8, alignment: .bottom, distribution: .fillEqually),
        ], spacing: 10))
    }

    private func makeEffectCard() -> UIView {
        func column(_ value: String, color: UIColor, caption: String) -> UIView {
            UIView.stack([
                StyledLabel.make(value, style: .stat, color: color, lines: 1),
                StyledLabel.make(caption, style: .caption, color: AppColor.ink2),
            ], spacing: 2)
        }
        let metric = viewModel.detail.metric
        let arrow = UIImageView(image: UIImage(resource: .iconArrowRight))
        arrow.setContentHuggingPriority(.required, for: .horizontal)
        let before = column(viewModel.beforeText, color: AppColor.ink3, caption: String(localized: "\(metric) before", comment: "Effect before"))
        let after = column(viewModel.afterText, color: AppColor.green, caption: String(localized: "\(metric) now", comment: "Effect after"))
        let row = UIView.stack([before, arrow, after], axis: .horizontal, spacing: 16, alignment: .center)
        before.widthAnchor.constraint(equalTo: after.widthAnchor).isActive = true
        row.isAccessibilityElement = true
        row.accessibilityLabel = String(localized: "\(viewModel.beforeText) \(metric) before, \(viewModel.afterText) now", comment: "Effect summary")

        return CardView(content: UIView.stack([
            StyledLabel.section(String(localized: "Is it working?", comment: "Effect card")),
            row,
            StyledLabel.section(String(localized: "R · before / after test on your check-ins", comment: "Effect method")),
        ], spacing: 10))
    }

    private func checkIn() {
        viewModel.checkInToday()
        renderCheckIns()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onCheckIn?()
    }
}
