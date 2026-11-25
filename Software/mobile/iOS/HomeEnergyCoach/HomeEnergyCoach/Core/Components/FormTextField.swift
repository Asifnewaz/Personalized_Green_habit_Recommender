import UIKit

/// Figma component `v4/Text field` (states Filled / Empty / Focused).
///
/// A `v4/Label` title above a 54pt input box. The box gains a 2pt `brand`
/// border while editing. Configure keyboard behaviour through `textField`.
final class FormTextField: UIView {
    private enum Metrics {
        static let boxHeight: CGFloat = 54
        static let focusedBorderWidth: CGFloat = 2
    }

    let textField = UITextField()
    private let titleLabel = StyledLabel(style: .label, color: AppColor.ink2)
    private let box = UIView()
    private let placeholder: String?

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    init(title: String, placeholder: String? = nil) {
        self.placeholder = placeholder
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.content = title
        titleLabel.isAccessibilityElement = false // the text field carries the label

        box.translatesAutoresizingMaskIntoConstraints = false
        box.layer.cornerRadius = CornerRadius.field
        box.layer.cornerCurve = .continuous
        box.layer.borderColor = AppColor.brand.cgColor
        box.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(focus)))

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.tintColor = AppColor.green
        textField.accessibilityLabel = title
        textField.adjustsFontForContentSizeCategory = false // handled in `applyTypography()`
        box.addSubview(textField)

        let stack = UIStackView(arrangedSubviews: [titleLabel, box])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)

        // 54pt per Figma; grows only if Dynamic Type needs more room.
        let preferredBoxHeight = box.heightAnchor.constraint(equalToConstant: Metrics.boxHeight)
        preferredBoxHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            preferredBoxHeight,
            textField.bottomAnchor.constraint(lessThanOrEqualTo: box.bottomAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            box.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.boxHeight),
            textField.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: Spacing.s),
            textField.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -Spacing.s),
            textField.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            textField.topAnchor.constraint(greaterThanOrEqualTo: box.topAnchor, constant: 8),
        ])

        textField.addAction(UIAction { [weak self] _ in self?.updateFocusAppearance() }, for: .editingDidBegin)
        textField.addAction(UIAction { [weak self] _ in self?.updateFocusAppearance() }, for: .editingDidEnd)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: FormTextField, _: UITraitCollection) in
            view.applyTypography()
        }

        applyTypography()
        updateFocusAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func focus() {
        textField.becomeFirstResponder()
    }

    private func applyTypography() {
        textField.defaultTextAttributes = TextStyle.body.inputAttributes(color: AppColor.ink, compatibleWith: traitCollection)
        if let placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: TextStyle.body.inputAttributes(color: AppColor.ink3, compatibleWith: traitCollection)
            )
        }
    }

    private func updateFocusAppearance() {
        let isFocused = textField.isFirstResponder
        box.backgroundColor = isFocused ? AppColor.background : AppColor.card
        box.layer.borderWidth = isFocused ? Metrics.focusedBorderWidth : 0
    }
}
