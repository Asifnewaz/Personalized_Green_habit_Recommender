import UIKit

/// Text-only `v4/Label` button in `ink`, optionally underlined (inline links).
final class TextLinkButton: TouchTargetButton {
    let title: String
    private let isUnderlined: Bool

    init(title: String, underlined: Bool = false) {
        self.title = title
        self.isUnderlined = underlined
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        configuration = config

        configurationUpdateHandler = { button in
            guard let button = button as? TextLinkButton, var config = button.configuration else { return }
            let text = NSMutableAttributedString(attributedString: TextStyle.label.attributedString(
                button.title,
                color: AppColor.ink.withAlphaComponent(button.isHighlighted ? 0.6 : 1),
                lineBreakMode: .byTruncatingTail,
                compatibleWith: button.traitCollection
            ))
            if button.isUnderlined {
                text.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue,
                                  range: NSRange(location: 0, length: text.length))
            }
            config.attributedTitle = AttributedString(text)
            button.configuration = config
        }
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (button: TextLinkButton, _: UITraitCollection) in
            button.setNeedsUpdateConfiguration()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Centered "prompt + link" line, e.g. "Already have an account? **Log in**".
final class LinkPromptView: UIView {
    let linkButton: TextLinkButton

    init(prompt: String, linkTitle: String) {
        linkButton = TextLinkButton(title: linkTitle, underlined: true)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let promptLabel = StyledLabel(style: .caption, color: AppColor.ink2, numberOfLines: 1)
        promptLabel.content = prompt

        let stack = UIStackView(arrangedSubviews: [promptLabel, linkButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
