import UIKit

/// Figma component `v4/Button`.
///
/// A 56pt-tall button with a 16pt corner radius and `v4/Headline` typography:
/// - `.primary` — `brand` fill, `on-ink` text.
/// - `.ghost` — 1.5pt `line` border, `ink` text, no fill.
final class AppButton: UIButton {
    enum Kind {
        case primary
        case ghost
        /// Ghost button with an `orange` title for destructive actions.
        case destructiveGhost
    }

    static let height: CGFloat = 56
    private static let ghostBorderWidth: CGFloat = 1.5

    let kind: Kind

    var title: String {
        didSet { setNeedsUpdateConfiguration() }
    }

    init(kind: Kind = .primary, title: String) {
        self.kind = kind
        self.title = title
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var config: UIButton.Configuration
        switch kind {
        case .primary:
            config = .filled()
            config.baseBackgroundColor = AppColor.brand
            config.baseForegroundColor = AppColor.onInk
        case .ghost, .destructiveGhost:
            config = .plain()
            config.baseForegroundColor = AppColor.ink
            config.background.strokeColor = AppColor.line
            config.background.strokeWidth = Self.ghostBorderWidth
        }
        config.cornerStyle = .fixed
        config.background.cornerRadius = CornerRadius.button
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Spacing.s, bottom: 0, trailing: Spacing.s)
        config.titleLineBreakMode = .byTruncatingTail
        configuration = config

        configurationUpdateHandler = { button in
            guard let button = button as? AppButton, var config = button.configuration else { return }
            let textColor: UIColor = switch button.kind {
            case .primary: AppColor.onInk
            case .ghost: AppColor.ink
            case .destructiveGhost: AppColor.orange
            }
            switch button.kind {
            case .primary:
                let alpha: CGFloat = !button.isEnabled ? 0.4 : (button.isHighlighted ? 0.85 : 1)
                config.background.backgroundColor = AppColor.brand.withAlphaComponent(alpha)
            case .ghost, .destructiveGhost:
                config.background.backgroundColor = button.isHighlighted ? AppColor.line.withAlphaComponent(0.4) : .clear
            }
            config.attributedTitle = AttributedString(
                TextStyle.headline.attributedString(
                    button.title,
                    color: textColor,
                    alignment: .center,
                    lineBreakMode: .byTruncatingTail,
                    compatibleWith: button.traitCollection
                )
            )
            button.configuration = config
        }

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (button: AppButton, _: UITraitCollection) in
            button.setNeedsUpdateConfiguration()
        }

        heightAnchor.constraint(greaterThanOrEqualToConstant: Self.height).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
