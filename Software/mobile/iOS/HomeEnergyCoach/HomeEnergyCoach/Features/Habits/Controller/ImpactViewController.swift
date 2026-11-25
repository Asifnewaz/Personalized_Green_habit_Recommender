import UIKit

/// Figma `v4 08 Impact` — results since starting, coaching effect, and links to app info.
final class ImpactViewController: FormScreenViewController {
    var onShowQuickWins: (() -> Void)?
    var onShowDataPrivacy: (() -> Void)?
    var onShowGreenSoftware: (() -> Void)?

    private let summary: ImpactSummary
    /// Current (done, total) one-time actions; re-read whenever the screen appears.
    private let quickWinsProgress: () -> (done: Int, total: Int)
    private var quickWinsTile: StatTileView?
    private var comparisonBars: [ProgressBarView] = []
    private var hasAnimated = false

    init(summary: ImpactSummary = .sample, quickWinsProgress: @escaping () -> (done: Int, total: Int)) {
        self.summary = summary
        self.quickWinsProgress = quickWinsProgress
        super.init(navigationTitle: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let progress = quickWinsProgress()
        quickWinsTile?.setValue("\(progress.done)/\(progress.total)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let head = UIView.stack([
            StyledLabel.section(String(localized: "Since you started · \(summary.weeks) weeks", comment: "Impact eyebrow")),
            HeadlineView(title: String(localized: "Your impact", comment: "Impact title")),
        ], spacing: 8)

        let userType = CardView(content: UIView.stack([
            TagView(text: summary.userType, backgroundColor: AppColor.lime),
            StyledLabel.make(summary.userTypeDetail, style: .caption, color: AppColor.ink2),
        ], axis: .horizontal, spacing: 12, alignment: .center),
        insets: NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))

        setContent([head, makeStats(), makeComparisonCard(), userType, makeLinks()])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimated else { return }
        hasAnimated = true
        comparisonBars.enumerated().forEach { $1.animateFill(delay: 0.2 + Double($0) * 0.1) }
    }

    private func makeStats() -> UIView {
        let saved = StatTileView(value: "−\(summary.co2SavedKg) kg", subtitle: String(localized: "CO₂ saved", comment: "Impact stat"),
                                 isEmphasized: true, emphasizedValueColor: AppColor.lime, padding: 16)
        let automatic = StatTileView(value: "\(summary.automaticHabits)", subtitle: String(localized: "habit automatic", comment: "Impact stat"), padding: 16)
        let inProgress = StatTileView(value: "\(summary.habitsInProgress)", subtitle: String(localized: "habits in progress", comment: "Impact stat"), padding: 16)
        let progress = quickWinsProgress()
        let quickWins = StatTileView(value: "\(progress.done)/\(progress.total)",
                                     subtitle: String(localized: "one-time actions", comment: "Impact stat"),
                                     padding: 16, isInteractive: true)
        quickWins.accessibilityHint = String(localized: "Opens quick wins", comment: "Impact stat hint")
        quickWins.addAction(UIAction { [weak self] _ in self?.onShowQuickWins?() }, for: .touchUpInside)
        quickWinsTile = quickWins

        return UIView.stack([
            UIView.stack([saved, automatic], axis: .horizontal, spacing: 8, distribution: .fillEqually),
            UIView.stack([inProgress, quickWins], axis: .horizontal, spacing: 8, distribution: .fillEqually),
        ], spacing: 8)
    }

    private func makeComparisonCard() -> UIView {
        var views: [UIView] = [StyledLabel.section(String(localized: "Did the coaching work?", comment: "Impact comparison card"))]
        for (index, comparison) in summary.comparisons.enumerated() {
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = AppColor.line
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                views.append(divider)
            }
            let row = UIView.stack([
                StyledLabel.make(comparison.title, style: .bodyStrong, lines: 1),
                UIView(),
                StyledLabel.make(comparison.change, style: .label, color: AppColor.green, lines: 1),
            ], axis: .horizontal, spacing: 8, alignment: .center)
            row.isAccessibilityElement = true
            row.accessibilityLabel = "\(comparison.title): \(comparison.change)"
            views.append(row)

            if let bars = comparison.bars {
                let before = ProgressBarView(height: 6, trackColor: AppColor.line, fillColor: AppColor.ink3)
                before.progress = bars.before
                let after = ProgressBarView(height: 6, trackColor: AppColor.line, fillColor: AppColor.green)
                after.progress = bars.after
                comparisonBars += [before, after]
                views.append(UIView.stack([before, after], spacing: 6))
            }
        }
        views.append(StyledLabel.section(String(localized: "R · before / after comparison of check-ins", comment: "Impact method")))
        return CardView(content: UIView.stack(views, spacing: 10))
    }

    private func makeLinks() -> UIView {
        func link(_ icon: ImageResource, _ title: String, _ subtitle: String, action: @escaping () -> Void) -> UIView {
            let content = HabitRowContentView(
                code: nil, title: title, subtitle: subtitle,
                trailing: UIImageView(image: UIImage(resource: .iconChevronRightSmall)),
                leading: UIImageView(image: UIImage(resource: icon))
            )
            let row = ListRow(content: content, isTappable: true)
            row.accessibilityLabel = "\(title). \(subtitle)"
            row.addAction(UIAction { _ in action() }, for: .touchUpInside)
            return row
        }
        return DividedListCard(rows: [
            link(.iconLock, String(localized: "Data & privacy", comment: "Impact link"),
                 String(localized: "What each input is used for", comment: "Impact link detail")) { [weak self] in self?.onShowDataPrivacy?() },
            link(.iconLeafInk, String(localized: "Green software", comment: "Impact link"),
                 String(localized: "This app's own footprint", comment: "Impact link detail")) { [weak self] in self?.onShowGreenSoftware?() },
        ])
    }
}
