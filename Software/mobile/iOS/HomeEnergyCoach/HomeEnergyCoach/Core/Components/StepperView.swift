import UIKit

/// Figma component `v4/Stepper`: − / value / + on a rounded `bg` surface.
///
/// Sends `.valueChanged`. Exposed to VoiceOver as a single adjustable element;
/// set `accessibilityLabel` to describe what is being counted.
final class StepperView: UIControl {
    private enum Metrics {
        static let buttonSize: CGFloat = 44
        static let valueWidth: CGFloat = 36
    }

    let range: ClosedRange<Int>
    private(set) var value: Int

    private let minusButton = UIButton()
    private let plusButton = UIButton()
    private let valueLabel = StyledLabel(style: .h2, color: AppColor.ink, numberOfLines: 1)

    init(value: Int, range: ClosedRange<Int>) {
        self.range = range
        self.value = range.clamped(value)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AppColor.background
        layer.cornerRadius = CornerRadius.field
        layer.cornerCurve = .continuous

        var minusConfig = UIButton.Configuration.plain()
        minusConfig.attributedTitle = AttributedString(TextStyle.h2.attributedString("−", color: AppColor.ink2))
        minusConfig.contentInsets = .zero
        minusButton.configuration = minusConfig

        var plusConfig = UIButton.Configuration.plain()
        plusConfig.image = UIImage(resource: .iconPlus)
        plusConfig.contentInsets = .zero
        plusButton.configuration = plusConfig

        valueLabel.textAlignment = .center
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let preferredValueWidth = valueLabel.widthAnchor.constraint(equalToConstant: Metrics.valueWidth)
        preferredValueWidth.priority = .defaultHigh
        preferredValueWidth.isActive = true

        let stack = UIStackView(arrangedSubviews: [minusButton, valueLabel, plusButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: Metrics.buttonSize),
            minusButton.heightAnchor.constraint(equalToConstant: Metrics.buttonSize),
            plusButton.widthAnchor.constraint(equalToConstant: Metrics.buttonSize),
            plusButton.heightAnchor.constraint(equalToConstant: Metrics.buttonSize),
            valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: Metrics.valueWidth),
        ])

        minusButton.addAction(UIAction { [weak self] _ in self?.step(by: -1) }, for: .primaryActionTriggered)
        plusButton.addAction(UIAction { [weak self] _ in self?.step(by: 1) }, for: .primaryActionTriggered)

        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        render()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func accessibilityIncrement() { step(by: 1) }
    override func accessibilityDecrement() { step(by: -1) }

    private func step(by delta: Int) {
        let newValue = range.clamped(value + delta)
        guard newValue != value else { return }
        value = newValue
        render()
        UISelectionFeedbackGenerator().selectionChanged()
        sendActions(for: .valueChanged)
    }

    private func render() {
        valueLabel.content = "\(value)"
        minusButton.isEnabled = value > range.lowerBound
        plusButton.isEnabled = value < range.upperBound
        minusButton.alpha = minusButton.isEnabled ? 1 : 0.3
        plusButton.alpha = plusButton.isEnabled ? 1 : 0.3
        accessibilityValue = "\(value)"
    }
}

private extension ClosedRange where Bound == Int {
    func clamped(_ value: Int) -> Int {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
