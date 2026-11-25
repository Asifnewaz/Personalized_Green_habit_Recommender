import UIKit

/// 4-segment strength meter with a `v4/Label` caption in `green`.
final class PasswordStrengthView: UIView {
    private let meter = SegmentedProgressView(segmentCount: 4, filledColor: AppColor.green)
    private let label = StyledLabel(style: .label, color: AppColor.green, numberOfLines: 1)

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [meter, label])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            // Keep the row height stable while the label is empty.
            heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ])

        isAccessibilityElement = true
        update(.empty)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(_ strength: PasswordStrength) {
        meter.filledCount = strength.filledSegments
        label.content = strength.title
        accessibilityLabel = String(localized: "Password strength", comment: "Accessibility label of the password meter")
        accessibilityValue = strength == .empty ? nil : strength.title
    }
}
