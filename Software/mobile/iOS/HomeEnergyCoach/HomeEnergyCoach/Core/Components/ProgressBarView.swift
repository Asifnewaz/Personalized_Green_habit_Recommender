import UIKit

/// Rounded horizontal progress bar with an optional "fill from zero" animation.
final class ProgressBarView: UIView {
    private let fill = UIView()
    private let barHeight: CGFloat
    private var displayedProgress: CGFloat = 0

    /// Target progress, 0…1.
    var progress: CGFloat = 0 {
        didSet {
            progress = min(max(progress, 0), 1)
            displayedProgress = progress
            setNeedsLayout()
        }
    }

    init(height: CGFloat, trackColor: UIColor, fillColor: UIColor) {
        self.barHeight = height
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = trackColor
        clipsToBounds = true
        layer.cornerRadius = height / 2
        fill.backgroundColor = fillColor
        fill.layer.cornerRadius = height / 2
        addSubview(fill)
        heightAnchor.constraint(equalToConstant: height).isActive = true
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        fill.frame = CGRect(x: 0, y: 0, width: bounds.width * displayedProgress, height: barHeight)
    }

    /// Grows the fill from empty to `progress` (Figma: ease-out, ~0.6s).
    func animateFill(delay: TimeInterval, duration: TimeInterval = 0.6) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let target = progress
        displayedProgress = 0
        layoutIfNeeded()
        displayedProgress = target
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseOut, .allowUserInteraction]) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
}

/// Dot-level indicator. Default: three 7pt dots, 3pt gap, filled `brand`, empty `line`.
final class StrengthDotsView: UIView {
    init(
        level: Int,
        maximum: Int = 3,
        dotSize: CGFloat = 7,
        spacing: CGFloat = 3,
        filledColor: UIColor = AppColor.brand,
        emptyColor: UIColor = AppColor.line
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let dots: [UIView] = (0..<maximum).map { index in
            let dot = UIView()
            dot.backgroundColor = index < level ? filledColor : emptyColor
            dot.layer.cornerRadius = dotSize / 2
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: dotSize),
                dot.heightAnchor.constraint(equalToConstant: dotSize),
            ])
            return dot
        }
        let stack = UIView.stack(dots, axis: .horizontal, spacing: spacing)
        addSubview(stack)
        stack.pinEdges(to: self)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
