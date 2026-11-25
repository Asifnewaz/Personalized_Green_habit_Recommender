import UIKit

/// Figma `v4 06 Quick wins` — one-time actions checklist.
final class QuickWinsViewController: FormScreenViewController {
    /// Called for actions handled elsewhere (H22 → WG agreement).
    var onOpenWG: (() -> Void)?

    private let viewModel: QuickWinsViewModel
    private let countLabel = StyledLabel(style: .stat, color: AppColor.ink, numberOfLines: 1)
    private let progress: SegmentedProgressView
    private let listContainer = UIView.stack([])

    init(viewModel: QuickWinsViewModel = QuickWinsViewModel()) {
        self.viewModel = viewModel
        progress = SegmentedProgressView(segmentCount: viewModel.items.count, filledColor: AppColor.green, height: 8, spacing: 4)
        super.init(navigationTitle: String(localized: "Quick wins", comment: "Quick wins nav title"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        let total = StyledLabel.make(String(localized: "of \(viewModel.items.count) done", comment: "Quick wins progress"),
                                     style: .headline, color: AppColor.ink2, lines: 1)
        let summary = CardView(content: UIView.stack([
            UIView.stack([countLabel, total], axis: .horizontal, spacing: 8, alignment: .firstBaseline),
            progress,
        ], spacing: 12))

        setContent([
            HeadlineView(
                title: String(localized: "One-time actions", comment: "Quick wins title"),
                subtitle: String(localized: "Do it once, save every year.", comment: "Quick wins subtitle")
            ),
            summary,
            listContainer,
        ])
        render()
    }

    private func render() {
        countLabel.content = "\(viewModel.doneCount)"
        progress.filledCount = viewModel.doneCount
        progress.isAccessibilityElement = true
        progress.accessibilityLabel = String(localized: "\(viewModel.doneCount) of \(viewModel.items.count) done", comment: "Quick wins progress")

        listContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows = viewModel.items.map(makeRow)
        listContainer.addArrangedSubview(DividedListCard(rows: rows))
    }

    private func makeRow(for item: QuickWin) -> UIView {
        let indicator = UIView()
        indicator.isUserInteractionEnabled = false
        indicator.layer.cornerRadius = 11
        indicator.backgroundColor = item.isDone ? AppColor.green : .clear
        indicator.layer.borderWidth = item.isDone ? 0 : 1.5
        indicator.layer.borderColor = AppColor.ink3.cgColor
        if item.isDone {
            let check = UIImageView(image: UIImage(resource: .iconCheck))
            check.translatesAutoresizingMaskIntoConstraints = false
            indicator.addSubview(check)
            NSLayoutConstraint.activate([
                check.centerXAnchor.constraint(equalTo: indicator.centerXAnchor),
                check.centerYAnchor.constraint(equalTo: indicator.centerYAnchor),
            ])
        }
        NSLayoutConstraint.activate([
            indicator.widthAnchor.constraint(equalToConstant: 22),
            indicator.heightAnchor.constraint(equalToConstant: 22),
        ])

        var trailing: UIView?
        if let badge = item.badge, !item.isDone {
            trailing = TagView(text: badge, backgroundColor: AppColor.lime)
        } else if item.opensWG {
            trailing = UIImageView(image: UIImage(resource: .iconChevronRightSmall))
        }

        let content = HabitRowContentView(
            code: nil, title: item.title, subtitle: viewModel.subtitle(for: item), trailing: trailing, leading: indicator,
            titleColor: item.isDone ? AppColor.ink3 : AppColor.ink, strikethrough: item.isDone
        )
        let row = ListRow(content: content, isTappable: true)
        row.accessibilityLabel = "\(item.title). \(viewModel.subtitle(for: item))"

        if item.opensWG {
            row.accessibilityHint = String(localized: "Opens your WG agreement", comment: "Quick win hint")
            row.addAction(UIAction { [weak self] _ in self?.onOpenWG?() }, for: .touchUpInside)
        } else {
            row.accessibilityTraits = item.isDone ? [.button, .selected] : .button
            row.addAction(UIAction { [weak self] _ in
                self?.viewModel.toggle(item.code)
                UISelectionFeedbackGenerator().selectionChanged()
                self?.render()
            }, for: .touchUpInside)
        }
        return row
    }
}
