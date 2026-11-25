import UIKit

/// Temporary destination for flows that are designed in Figma but not yet built
/// (e.g. `v4 A1 Welcome`, `v4 A3 Log in`).
final class ComingSoonViewController: UIViewController {
    private let screenTitle: String

    init(title: String) {
        self.screenTitle = title
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background

        let titleLabel = StyledLabel(style: .h1, color: AppColor.ink)
        titleLabel.textAlignment = .center
        titleLabel.content = screenTitle
        titleLabel.accessibilityTraits = .header

        let messageLabel = StyledLabel(style: .body, color: AppColor.ink2)
        messageLabel.textAlignment = .center
        messageLabel.content = String(localized: "This screen is coming soon.", comment: "Placeholder screen message")

        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = Spacing.xs
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
