import UIKit

/// Date eyebrow, "Hi Lena" headline and the initial avatar.
final class GreetingHeaderView: UIView {
    init(date: String, greeting: String, initial: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let dateLabel = StyledLabel(style: .meta, color: AppColor.ink3, numberOfLines: 1)
        dateLabel.content = date
        let greetingLabel = StyledLabel(style: .h1, color: AppColor.ink, numberOfLines: 1)
        greetingLabel.content = greeting
        greetingLabel.accessibilityTraits = .header
        let text = UIView.stack([dateLabel, greetingLabel], spacing: 4)

        let avatar = UIView()
        avatar.backgroundColor = AppColor.card
        avatar.layer.cornerRadius = 20
        let initialLabel = StyledLabel(style: .headline, color: AppColor.ink, numberOfLines: 1)
        initialLabel.content = initial
        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(initialLabel)
        avatar.isAccessibilityElement = false
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 40),
            avatar.heightAnchor.constraint(equalToConstant: 40),
            initialLabel.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
        ])

        let row = UIView.stack([text, avatar], axis: .horizontal, spacing: 12, alignment: .center)
        addSubview(row)
        row.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Seven rounded bars (30pt wide, 44pt tall area); today's bar is `lime`.
/// Bars rise from the baseline on first appearance (Figma: staggered, ease-out).
final class WeeklyBarsView: UIView {
    private enum Metrics {
        static let height: CGFloat = 44
        static let barWidth: CGFloat = 30
    }

    private var bars: [UIView] = []

    init(fractions: [Double], highlightIndex: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        let columns: [UIView] = fractions.enumerated().map { index, fraction in
            let column = UIView()
            column.translatesAutoresizingMaskIntoConstraints = false
            let bar = UIView()
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.layer.cornerRadius = 6
            bar.backgroundColor = index == highlightIndex ? AppColor.lime : UIColor.white.withAlphaComponent(0.18)
            column.addSubview(bar)
            NSLayoutConstraint.activate([
                column.widthAnchor.constraint(equalToConstant: Metrics.barWidth),
                column.heightAnchor.constraint(equalToConstant: Metrics.height),
                bar.leadingAnchor.constraint(equalTo: column.leadingAnchor),
                bar.trailingAnchor.constraint(equalTo: column.trailingAnchor),
                bar.bottomAnchor.constraint(equalTo: column.bottomAnchor),
                bar.heightAnchor.constraint(equalToConstant: max(6, Metrics.height * fraction)),
            ])
            bars.append(bar)
            return column
        }
        let stack = UIView.stack(columns, axis: .horizontal, distribution: .equalSpacing)
        addSubview(stack)
        stack.pinEdges(to: self)
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func animateRise(delay: TimeInterval = 0.4) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        layoutIfNeeded()
        for (index, bar) in bars.enumerated() {
            bar.transform = CGAffineTransform(translationX: 0, y: bar.bounds.height)
            UIView.animate(withDuration: 0.5, delay: delay + Double(index) * 0.03, options: [.curveEaseOut]) {
                bar.transform = .identity
            }
        }
    }
}

/// Brand card: weekly CO₂ change, trend tag, daily bars and weekday labels.
final class WeeklySummaryCardView: UIView {
    let bars: WeeklyBarsView

    init(viewModel: HomeViewModel) {
        bars = WeeklyBarsView(fractions: viewModel.barFractions, highlightIndex: viewModel.todayIndex)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let title = StyledLabel(style: .meta, color: AppColor.onInk2, numberOfLines: 1)
        title.content = viewModel.weekTitle

        let value = StyledLabel(style: .stat, color: AppColor.onInk, numberOfLines: 1)
        value.content = viewModel.weeklyChangeText
        value.setContentHuggingPriority(.required, for: .horizontal)
        let unit = StyledLabel(style: .headline, color: AppColor.onInk2, numberOfLines: 1)
        unit.content = String(localized: "kg CO₂", comment: "Weekly CO₂ unit")
        unit.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let trend = TagView(text: viewModel.trendText, backgroundColor: AppColor.greenSoft)
        let valueRow = UIView.stack([value, unit, trend], axis: .horizontal, spacing: 8, alignment: .center)

        let dayLabels: [UIView] = viewModel.dayLabels.map { day in
            let label = StyledLabel(style: .meta, color: AppColor.onInk, numberOfLines: 1)
            label.content = day
            label.textAlignment = .center
            label.widthAnchor.constraint(equalToConstant: 30).isActive = true
            return label
        }
        let daysRow = UIView.stack(dayLabels, axis: .horizontal, distribution: .equalSpacing)

        let card = CardView(content: UIView.stack([title, valueRow, bars, daysRow], spacing: 12), backgroundColor: AppColor.brand)
        addSubview(card)
        card.pinEdges(to: self)

        isAccessibilityElement = true
        accessibilityLabel = "\(viewModel.weekTitle). \(viewModel.weeklyChangeText) kg CO₂, \(viewModel.trendText)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Tappable card base: dims while pressed and passes touches through its content.
class TappableCardControl: UIControl {
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1 }
    }

    func install(_ content: UIView, backgroundColor: UIColor, insets: NSDirectionalEdgeInsets) {
        translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = backgroundColor
        layer.cornerRadius = CornerRadius.card
        layer.cornerCurve = .continuous
        content.isUserInteractionEnabled = false
        addSubview(content)
        content.pinEdges(to: self, insets: insets)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}

/// `green-soft` card announcing the current green window (→ Green Hours).
final class GreenWindowCardView: TappableCardControl {
    init(title: String, subtitle: String) {
        super.init(frame: .zero)

        let tile = UIView()
        tile.backgroundColor = AppColor.brand
        tile.layer.cornerRadius = 12
        let icon = UIImageView(image: UIImage(resource: .iconZapTile))
        icon.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(icon)
        NSLayoutConstraint.activate([
            tile.widthAnchor.constraint(equalToConstant: 40),
            tile.heightAnchor.constraint(equalToConstant: 40),
            icon.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
        ])

        let titleLabel = StyledLabel(style: .headline, color: AppColor.ink)
        titleLabel.content = title
        let subtitleLabel = StyledLabel(style: .caption, color: AppColor.ink)
        subtitleLabel.content = subtitle
        let text = UIView.stack([titleLabel, subtitleLabel], spacing: 2)

        let chevron = UIImageView(image: UIImage(resource: .iconChevronRight))
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        install(
            UIView.stack([tile, text, chevron], axis: .horizontal, spacing: 14, alignment: .center),
            backgroundColor: AppColor.greenSoft,
            insets: NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        )
        accessibilityLabel = "\(title). \(subtitle)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Card for the habit currently being built, with its automaticity progress (→ Habit).
final class HabitProgressCardView: TappableCardControl {
    let progressBar = ProgressBarView(height: 8, trackColor: AppColor.line, fillColor: AppColor.green)

    init(habit: HomeDashboard.HabitProgress, status: String, typical: String) {
        super.init(frame: .zero)

        let eyebrow = StyledLabel(style: .meta, color: AppColor.ink3, numberOfLines: 1)
        eyebrow.content = String(localized: "Habit in progress", comment: "Home habit card eyebrow")
        let code = TagView(text: habit.code, style: .meta, textColor: AppColor.ink,
                           backgroundColor: AppColor.background, borderColor: AppColor.line)
        let header = UIView.stack([eyebrow, UIView(), code], axis: .horizontal, alignment: .center)

        let title = StyledLabel(style: .h2, color: AppColor.ink)
        title.content = habit.title

        progressBar.progress = habit.automaticity

        let statusLabel = StyledLabel(style: .label, color: AppColor.ink, numberOfLines: 1)
        statusLabel.content = status
        let typicalLabel = StyledLabel(style: .caption, color: AppColor.ink3, numberOfLines: 1)
        typicalLabel.content = typical
        typicalLabel.textAlignment = .right
        let footer = UIView.stack([statusLabel, typicalLabel], axis: .horizontal, spacing: 8)

        install(
            UIView.stack([header, title, progressBar, footer], spacing: 10),
            backgroundColor: AppColor.card,
            insets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        )
        accessibilityLabel = "\(eyebrow.content ?? ""): \(habit.code), \(habit.title). \(status). \(typical)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Compact card teasing the next recommended habit (→ Plan).
final class NextHabitCardView: TappableCardControl {
    init(title: String, reason: String) {
        super.init(frame: .zero)

        let tagTitle = String(localized: "Next", comment: "Next habit tag")
        let tag = TagView(text: tagTitle, backgroundColor: AppColor.lime)
        let titleLabel = StyledLabel(style: .bodyStrong, color: AppColor.ink)
        titleLabel.content = title
        let reasonLabel = StyledLabel(style: .caption, color: AppColor.ink2)
        reasonLabel.content = reason
        let text = UIView.stack([titleLabel, reasonLabel], spacing: 2)
        let chevron = UIImageView(image: UIImage(resource: .iconChevronRightMuted))
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        install(
            UIView.stack([tag, text, chevron], axis: .horizontal, spacing: 12, alignment: .center),
            backgroundColor: AppColor.card,
            insets: NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        )
        accessibilityLabel = "\(tagTitle): \(title). \(reason)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
