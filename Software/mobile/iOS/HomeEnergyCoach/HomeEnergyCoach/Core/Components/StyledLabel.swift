import UIKit

/// A `UILabel` that renders its text using a design-system `TextStyle`
/// and re-renders automatically when the Dynamic Type size changes.
final class StyledLabel: UILabel {
    var style: TextStyle { didSet { render() } }
    var styledColor: UIColor { didSet { render() } }

    /// The plain text to render in `style`. Use this instead of `text`.
    var content: String? { didSet { render() } }

    init(style: TextStyle, color: UIColor = AppColor.ink, numberOfLines: Int = 0) {
        self.style = style
        self.styledColor = color
        super.init(frame: .zero)
        self.numberOfLines = numberOfLines
        translatesAutoresizingMaskIntoConstraints = false
        adjustsFontForContentSizeCategory = false // handled in `render()`
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (label: StyledLabel, _: UITraitCollection) in
            label.render()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func render() {
        guard let content else {
            attributedText = nil
            return
        }
        attributedText = style.attributedString(
            content,
            color: styledColor,
            alignment: textAlignment,
            lineBreakMode: numberOfLines == 1 ? .byTruncatingTail : .byWordWrapping,
            compatibleWith: traitCollection
        )
    }
}
