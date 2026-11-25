import UIKit

/// Capsule text button (`card` fill, `v4/Label` text) used for secondary
/// navigation such as "Skip" and "Log in".
///
/// The visual pill is 34pt tall; its hit area is expanded to the
/// 44×44pt minimum recommended by the Human Interface Guidelines.
final class PillButton: TouchTargetButton {
    var title: String {
        didSet { setNeedsUpdateConfiguration() }
    }

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        config.background.backgroundColor = AppColor.card
        config.baseForegroundColor = AppColor.ink
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration = config

        configurationUpdateHandler = { button in
            guard let button = button as? PillButton, var config = button.configuration else { return }
            config.attributedTitle = AttributedString(
                TextStyle.label.attributedString(
                    button.title,
                    color: AppColor.ink.withAlphaComponent(button.isHighlighted ? 0.6 : 1),
                    lineBreakMode: .byTruncatingTail,
                    compatibleWith: button.traitCollection
                )
            )
            button.configuration = config
        }

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (button: PillButton, _: UITraitCollection) in
            button.setNeedsUpdateConfiguration()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}
