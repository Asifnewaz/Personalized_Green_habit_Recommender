import UIKit

/// Figma `v4 04 Green Hours` — tomorrow's SMARD forecast and the greenest window.
final class GreenHoursViewController: FormScreenViewController {
    private let viewModel: GreenHoursViewModel
    private let chart: GridForecastChartView
    private var hasAnimated = false

    init(viewModel: GreenHoursViewModel) {
        self.viewModel = viewModel
        chart = GridForecastChartView(viewModel: viewModel)
        super.init(navigationTitle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let head = UIView.stack([
            StyledLabel.section(viewModel.forecast.dayLabel),
            HeadlineView(title: String(localized: "Greenest window", comment: "Green Hours title")),
        ], spacing: 8)

        let window = UIView.stack([
            StyledLabel.make(viewModel.windowText, style: .display, color: AppColor.green, lines: 1),
            StyledLabel.make(viewModel.summary, style: .body, color: AppColor.ink2),
        ], spacing: 4)
        window.isAccessibilityElement = true
        window.accessibilityLabel = "\(viewModel.windowText). \(viewModel.summary)"

        let habits = DividedListCard(rows: viewModel.forecast.suggestions.map { suggestion in
            ListRow(content: HabitRowContentView(
                code: suggestion.code, title: suggestion.title, subtitle: suggestion.detail,
                trailing: TagView(text: suggestion.time, backgroundColor: AppColor.lime)
            ))
        })

        setContent([
            head, window, CardView(content: chart),
            StyledLabel.section(String(localized: "Your timing habits", comment: "Green Hours section")),
            habits,
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimated else { return }
        hasAnimated = true
        chart.animateBars()
    }
}

/// 24 hourly intensity bars, a "you're home" strip, hour axis and legend.
final class GridForecastChartView: UIView {
    private enum Metrics {
        static let chartHeight: CGFloat = 120
        /// Grams that map to the full chart height (Figma: 400 g ≈ 116 of 120pt).
        static let scaleMax: Double = 414
    }

    private var bars: [UIView] = []

    init(viewModel: GreenHoursViewModel) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let grams = viewModel.forecast.gramsPerKWh
        let columns: [UIView] = grams.indices.map { hour in
            let column = UIView()
            let bar = UIView()
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.layer.cornerRadius = 3
            bar.backgroundColor = Self.color(for: viewModel.intensity(at: hour))
            column.addSubview(bar)
            NSLayoutConstraint.activate([
                column.heightAnchor.constraint(equalToConstant: Metrics.chartHeight),
                bar.leadingAnchor.constraint(equalTo: column.leadingAnchor),
                bar.trailingAnchor.constraint(equalTo: column.trailingAnchor),
                bar.bottomAnchor.constraint(equalTo: column.bottomAnchor),
                bar.heightAnchor.constraint(equalToConstant: Metrics.chartHeight * min(Double(grams[hour]) / Metrics.scaleMax, 1)),
            ])
            bars.append(bar)
            return column
        }
        let barRow = UIView.stack(columns, axis: .horizontal, spacing: 4, distribution: .fillEqually)
        barRow.clipsToBounds = true

        let homeStrip = UIView.stack(grams.indices.map { hour in
            let segment = UIView()
            segment.layer.cornerRadius = 2
            segment.backgroundColor = viewModel.forecast.homeHours.contains(hour) ? AppColor.ink : AppColor.line
            segment.heightAnchor.constraint(equalToConstant: 4).isActive = true
            return segment
        }, axis: .horizontal, spacing: 2, distribution: .fillEqually)

        let axis = UIView.stack(["00", "06", "12", "18", "24"].map {
            StyledLabel.make($0, style: .meta, color: AppColor.ink3, lines: 1)
        }, axis: .horizontal, distribution: .equalSpacing)

        let legend = FlowLayoutView(views: [
            Self.legendItem(AppColor.green, String(localized: "Your window", comment: "Chart legend")),
            Self.legendItem(AppColor.greenSoft, String(localized: "Clean", comment: "Chart legend")),
            Self.legendItem(AppColor.orange, String(localized: "High CO₂", comment: "Chart legend")),
            Self.legendItem(AppColor.ink, String(localized: "You're home", comment: "Chart legend")),
        ], horizontalSpacing: 14, verticalSpacing: 6)

        let stack = UIView.stack([barRow, homeStrip, axis, legend], spacing: 10)
        addSubview(stack)
        stack.pinEdges(to: self)

        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Hourly grid CO₂ forecast. Greenest window \(viewModel.windowText). \(viewModel.summary)",
                                    comment: "Forecast chart accessibility summary")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Bars rise from the baseline (Figma: ease-out, ~0.5s, slight stagger).
    func animateBars() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        layoutIfNeeded()
        for (index, bar) in bars.enumerated() {
            bar.transform = CGAffineTransform(translationX: 0, y: bar.bounds.height)
            UIView.animate(withDuration: 0.5, delay: 0.1 + Double(index) * 0.015, options: [.curveEaseOut]) {
                bar.transform = .identity
            }
        }
    }

    private static func color(for intensity: GridIntensity) -> UIColor {
        switch intensity {
        case .window: AppColor.green
        case .clean: AppColor.greenSoft
        case .medium: AppColor.ink3
        case .high: AppColor.orange
        }
    }

    private static func legendItem(_ color: UIColor, _ title: String) -> UIView {
        let swatch = UIView()
        swatch.backgroundColor = color
        swatch.layer.cornerRadius = 3
        NSLayoutConstraint.activate([
            swatch.widthAnchor.constraint(equalToConstant: 10),
            swatch.heightAnchor.constraint(equalToConstant: 10),
        ])
        return UIView.stack([swatch, StyledLabel.make(title, style: .caption, color: AppColor.ink2, lines: 1)],
                            axis: .horizontal, spacing: 6, alignment: .center)
    }
}
