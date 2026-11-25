import UIKit

/// Round checkbox with a `v4/Caption` label. Checked: `green` fill with a white tick;
/// unchecked: 1.5pt `ink-3` ring. Sends `.valueChanged` when toggled.
final class CheckboxControl: UIControl {
    private enum Metrics {
        static let checkSize: CGFloat = 12
        static let ringWidth: CGFloat = 1.5
        static let minimumHitHeight: CGFloat = 44
    }

    private let box = UIView()
    private let checkView = UIImageView(image: UIImage(resource: .iconCheckSmall))
    private let titleLabel = StyledLabel(style: .caption, color: AppColor.ink2)

    var isOn: Bool {
        didSet { applyState() }
    }

    /// - Parameters:
    ///   - boxSize: Diameter of the check circle (Figma: 20pt for consent, 18pt for "Remember me").
    ///   - spacing: Gap between the circle and the label.
    init(title: String, isOn: Bool = false, boxSize: CGFloat = 20, spacing: CGFloat = 10) {
        self.isOn = isOn
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.content = title

        box.translatesAutoresizingMaskIntoConstraints = false
        box.layer.cornerRadius = boxSize / 2
        box.isUserInteractionEnabled = false
        checkView.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(checkView)
        titleLabel.isUserInteractionEnabled = false

        addSubview(box)
        addSubview(titleLabel)

        // Hug the taller of the circle and the label.
        let hugHeight = heightAnchor.constraint(equalToConstant: 0)
        hugHeight.priority = .defaultLow

        NSLayoutConstraint.activate([
            hugHeight,
            box.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            box.leadingAnchor.constraint(equalTo: leadingAnchor),
            box.centerYAnchor.constraint(equalTo: centerYAnchor),
            box.widthAnchor.constraint(equalToConstant: boxSize),
            box.heightAnchor.constraint(equalToConstant: boxSize),
            box.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),

            checkView.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            checkView.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            checkView.widthAnchor.constraint(equalToConstant: Metrics.checkSize),
            checkView.heightAnchor.constraint(equalToConstant: Metrics.checkSize),

            titleLabel.leadingAnchor.constraint(equalTo: box.trailingAnchor, constant: spacing),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.isOn.toggle()
            self.sendActions(for: .valueChanged)
        }, for: .touchUpInside)

        isAccessibilityElement = true
        accessibilityLabel = title
        applyState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { box.alpha = isHighlighted ? 0.6 : 1 }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let dy = max(0, Metrics.minimumHitHeight - bounds.height) / 2
        return bounds.insetBy(dx: 0, dy: -dy).contains(point)
    }

    private func applyState() {
        box.backgroundColor = isOn ? AppColor.green : .clear
        box.layer.borderWidth = isOn ? 0 : Metrics.ringWidth
        box.layer.borderColor = AppColor.ink3.cgColor
        checkView.isHidden = !isOn
        accessibilityTraits = isOn ? [.button, .selected] : .button
    }
}
