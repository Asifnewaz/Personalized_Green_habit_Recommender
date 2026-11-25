import UIKit

/// Figma `v4 10 Green software` — the app's own energy footprint.
final class GreenSoftwareViewController: FormScreenViewController {
    private let report: GreenSoftwareReport

    init(report: GreenSoftwareReport = .sample) {
        self.report = report
        super.init(navigationTitle: String(localized: "Green software", comment: "Green software nav title"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let formatter = Self.energyFormatter
        let head = UIView.stack([
            StyledLabel.section(String(localized: "How green is this app?", comment: "Green software eyebrow")),
            HeadlineView(
                title: String(localized: "\(formatter(report.latestWattHours)) per day of use", comment: "Green software headline"),
                subtitle: String(localized: "Placeholder values until we measure the first prototype.", comment: "Green software note")
            ),
        ], spacing: 8)

        let changes = UIView.stack(report.changes.map { change in
            let icon = UIImageView(image: UIImage(resource: .iconCheckPlain))
            icon.setContentHuggingPriority(.required, for: .horizontal)
            icon.setContentCompressionResistancePriority(.required, for: .horizontal)
            let row = UIView.stack([icon, StyledLabel.make(change, style: .body)], axis: .horizontal, spacing: 10, alignment: .top)
            row.isAccessibilityElement = true
            row.accessibilityLabel = change
            return row
        }, spacing: 10)

        setContent([
            head,
            makeSprintChart(),
            DividedListCard(rows: report.metrics.map(makeMetricRow)),
            StyledLabel.section(String(localized: "What we changed", comment: "Green software section")),
            changes,
        ])
    }

    private func makeSprintChart() -> UIView {
        let maxValue = report.sprints.map(\.wattHours).max() ?? 1
        let lastIndex = report.sprints.count - 1
        let columns = report.sprints.enumerated().map { index, sprint -> UIView in
            let isLatest = index == lastIndex
            let bar = UIView()
            bar.backgroundColor = isLatest ? AppColor.green : AppColor.line
            bar.layer.cornerRadius = 8
            bar.heightAnchor.constraint(equalToConstant: 80 * sprint.wattHours / maxValue).isActive = true
            let column = UIView.stack([
                UIView(),
                StyledLabel.make(Self.energyFormatter(sprint.wattHours), style: .label, color: isLatest ? AppColor.green : AppColor.ink2, lines: 1),
                bar,
            ], spacing: 6)
            column.heightAnchor.constraint(equalToConstant: 120).isActive = true
            return column
        }
        let names = report.sprints.map { StyledLabel.make($0.name, style: .meta, color: AppColor.ink3, lines: 1) as UIView }

        let card = CardView(content: UIView.stack([
            StyledLabel.section(String(localized: "Energy per day, by sprint", comment: "Green software chart")),
            UIView.stack(columns, axis: .horizontal, spacing: 12, distribution: .fillEqually),
            UIView.stack(names, axis: .horizontal, spacing: 12, distribution: .fillEqually),
        ], spacing: 10))
        card.isAccessibilityElement = true
        card.accessibilityLabel = report.sprints.map { "\($0.name): \(Self.energyFormatter($0.wattHours))" }.joined(separator: ", ")
        return card
    }

    private func makeMetricRow(_ metric: GreenSoftwareReport.Metric) -> UIView {
        let iconResource: ImageResource = switch metric.icon {
        case .cpu: .iconCpuMetric
        case .cloud: .iconCloudMetric
        case .zap: .iconZapMetric
        }
        let icon = UIImageView(image: UIImage(resource: iconResource))
        icon.setContentHuggingPriority(.required, for: .horizontal)
        let title = StyledLabel.make(metric.title, style: .bodyStrong)
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let value = StyledLabel.make(metric.value, style: .bodyStrong, lines: 1)
        value.setContentHuggingPriority(.required, for: .horizontal)
        value.setContentCompressionResistancePriority(.required, for: .horizontal)
        let change = TagView(text: metric.change, textColor: AppColor.green, backgroundColor: AppColor.greenSoft)

        let row = UIView.stack([icon, title, value, change], axis: .horizontal, spacing: 12, alignment: .center)
        row.isAccessibilityElement = true
        row.accessibilityLabel = "\(metric.title): \(metric.value), \(metric.change)"
        return ListRow(content: row)
    }

    /// e.g. "0.8 Wh".
    private static func energyFormatter(_ wattHours: Double) -> String {
        // Foundation's UnitEnergy has no watt-hours unit, so format the number and append "Wh".
        "\(wattHours.formatted(.number.precision(.fractionLength(1)))) Wh"
    }
}
