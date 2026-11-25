import UIKit

@MainActor
protocol LogInViewControllerDelegate: AnyObject {
    func logInViewController(_ controller: LogInViewController, didSubmit form: LogInForm)
    func logInViewControllerDidSelectFaceID(_ controller: LogInViewController)
    func logInViewControllerDidSelectForgotPassword(_ controller: LogInViewController)
    func logInViewControllerDidSelectCreateAccount(_ controller: LogInViewController)
}

/// Figma `v4 A3 Log in`.
final class LogInViewController: FormScreenViewController {
    weak var delegate: LogInViewControllerDelegate?

    private let viewModel: LogInViewModel

    private let emailField = FormTextField(
        title: String(localized: "Email", comment: "Log-in field"),
        placeholder: String(localized: "lena@example.de", comment: "Email placeholder")
    )
    private let passwordField = FormTextField(
        title: String(localized: "Password", comment: "Log-in field")
    )
    private let rememberMeCheckbox = CheckboxControl(
        title: String(localized: "Remember me", comment: "Log-in option"),
        boxSize: 18,
        spacing: 8
    )
    private let forgotPasswordButton = TextLinkButton(
        title: String(localized: "Forgot password?", comment: "Log-in link")
    )
    private let logInButton = AppButton(kind: .primary, title: String(localized: "Log in", comment: "Log-in primary action"))
    private let faceIDButton = AppButton(kind: .ghost, title: String(localized: "Use Face ID", comment: "Log-in biometric action"))
    private let createAccountPrompt = LinkPromptView(
        prompt: String(localized: "New here?", comment: "Log-in footer prompt"),
        linkTitle: String(localized: "Create account", comment: "Log-in footer link")
    )

    init(viewModel: LogInViewModel = LogInViewModel()) {
        self.viewModel = viewModel
        super.init(navigationTitle: String(localized: "Account", comment: "Account screens nav title"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureFields()

        let optionsRow = UIStackView(arrangedSubviews: [rememberMeCheckbox, UIView(), forgotPasswordButton])
        optionsRow.axis = .horizontal
        optionsRow.alignment = .center
        optionsRow.spacing = 8

        let actions = UIStackView(arrangedSubviews: [logInButton, faceIDButton])
        actions.axis = .vertical
        actions.spacing = 10

        setContent(
            [
                HeadlineView(
                    title: String(localized: "Welcome back", comment: "Log-in title"),
                    subtitle: String(localized: "Your WG saved 4.1 kg of CO₂ this week.", comment: "Log-in subtitle")
                ),
                emailField,
                passwordField,
                optionsRow,
            ],
            actions: [actions, createAccountPrompt]
        )
        bindActions()
        render()
    }

    // MARK: - Setup

    private func configureFields() {
        let email = emailField.textField
        email.textContentType = .username
        email.keyboardType = .emailAddress
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.returnKeyType = .next

        let password = passwordField.textField
        password.textContentType = .password
        password.isSecureTextEntry = true
        password.returnKeyType = .go

        [email, password].forEach { $0.delegate = self }
    }

    private func bindActions() {
        emailField.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.form.email = emailField.text
            render()
        }, for: .editingChanged)

        passwordField.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.form.password = passwordField.text
            render()
        }, for: .editingChanged)

        rememberMeCheckbox.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.form.rememberMe = rememberMeCheckbox.isOn
        }, for: .valueChanged)

        logInButton.addAction(UIAction { [weak self] _ in self?.submit() }, for: .primaryActionTriggered)

        faceIDButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.logInViewControllerDidSelectFaceID(self)
        }, for: .primaryActionTriggered)

        forgotPasswordButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.logInViewControllerDidSelectForgotPassword(self)
        }, for: .primaryActionTriggered)

        createAccountPrompt.linkButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.logInViewControllerDidSelectCreateAccount(self)
        }, for: .primaryActionTriggered)
    }

    private func render() {
        logInButton.isEnabled = viewModel.canSubmit
    }

    private func submit() {
        guard viewModel.canSubmit else { return }
        view.endEditing(true)
        delegate?.logInViewController(self, didSubmit: viewModel.form)
    }
}

// MARK: - UITextFieldDelegate

extension LogInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField.textField {
            passwordField.textField.becomeFirstResponder()
        } else {
            submit()
        }
        return false
    }
}
