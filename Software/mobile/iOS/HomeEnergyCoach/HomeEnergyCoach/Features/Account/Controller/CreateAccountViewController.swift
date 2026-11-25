import UIKit

@MainActor
protocol CreateAccountViewControllerDelegate: AnyObject {
    func createAccountViewController(_ controller: CreateAccountViewController, didSubmit form: CreateAccountForm)
    func createAccountViewControllerDidSelectLogIn(_ controller: CreateAccountViewController)
}

/// Figma `v4 A2 Create account`.
final class CreateAccountViewController: FormScreenViewController {
    weak var delegate: CreateAccountViewControllerDelegate?

    private let viewModel: CreateAccountViewModel

    private let nameField = FormTextField(
        title: String(localized: "Name", comment: "Sign-up field"),
        placeholder: String(localized: "Lena", comment: "Sign-up name placeholder")
    )
    private let emailField = FormTextField(
        title: String(localized: "Email", comment: "Sign-up field"),
        placeholder: String(localized: "lena@example.de", comment: "Email placeholder")
    )
    private let passwordField = FormTextField(
        title: String(localized: "Password", comment: "Sign-up field"),
        placeholder: String(localized: "At least 8 characters", comment: "Password placeholder")
    )
    private let strengthView = PasswordStrengthView()
    private let inviteCodeField = FormTextField(
        title: String(localized: "WG invite code (optional)", comment: "Sign-up field"),
        placeholder: String(localized: "e.g. SONNE-12", comment: "Invite code placeholder")
    )
    private let termsCheckbox = CheckboxControl(
        title: String(localized: "I agree to the Terms and the Privacy Policy.", comment: "Sign-up consent")
    )
    private let submitButton = AppButton(
        kind: .primary,
        title: String(localized: "Create account", comment: "Sign-up primary action")
    )
    private let logInPrompt = LinkPromptView(
        prompt: String(localized: "Already have an account?", comment: "Sign-up footer prompt"),
        linkTitle: String(localized: "Log in", comment: "Sign-up footer link")
    )

    init(viewModel: CreateAccountViewModel = CreateAccountViewModel()) {
        self.viewModel = viewModel
        super.init(navigationTitle: String(localized: "Account", comment: "Account screens nav title"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureFields()

        let passwordGroup = UIStackView(arrangedSubviews: [passwordField, strengthView])
        passwordGroup.axis = .vertical
        passwordGroup.spacing = 8

        setContent(
            [
                HeadlineView(
                    title: String(localized: "Create your account", comment: "Sign-up title"),
                    subtitle: String(
                        localized: "Your plan learns from your check-ins, so we keep them with your account.",
                        comment: "Sign-up subtitle"
                    )
                ),
                nameField,
                emailField,
                passwordGroup,
                inviteCodeField,
                termsCheckbox,
            ],
            actions: [submitButton, logInPrompt]
        )
        bindActions()
        render()
    }

    // MARK: - Setup

    private func configureFields() {
        let name = nameField.textField
        name.textContentType = .name
        name.autocapitalizationType = .words
        name.returnKeyType = .next

        let email = emailField.textField
        email.textContentType = .emailAddress
        email.keyboardType = .emailAddress
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.returnKeyType = .next

        let password = passwordField.textField
        password.textContentType = .newPassword
        password.passwordRules = UITextInputPasswordRules(descriptor: "minlength: \(PasswordStrength.minimumLength);")
        password.isSecureTextEntry = true
        password.returnKeyType = .next

        let invite = inviteCodeField.textField
        invite.autocapitalizationType = .allCharacters
        invite.autocorrectionType = .no
        invite.returnKeyType = .done

        [name, email, password, invite].forEach { $0.delegate = self }
    }

    private func bindActions() {
        let fields: [(FormTextField, WritableKeyPath<CreateAccountForm, String>)] = [
            (nameField, \.name), (emailField, \.email), (passwordField, \.password), (inviteCodeField, \.inviteCode),
        ]
        for (field, keyPath) in fields {
            field.textField.addAction(UIAction { [weak self, weak field] _ in
                guard let self, let field else { return }
                viewModel.form[keyPath: keyPath] = field.text
                render()
            }, for: .editingChanged)
        }

        termsCheckbox.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.form.acceptsTerms = termsCheckbox.isOn
            render()
        }, for: .valueChanged)

        submitButton.addAction(UIAction { [weak self] _ in self?.submit() }, for: .primaryActionTriggered)

        logInPrompt.linkButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            delegate?.createAccountViewControllerDidSelectLogIn(self)
        }, for: .primaryActionTriggered)
    }

    private func render() {
        strengthView.update(viewModel.passwordStrength)
        submitButton.isEnabled = viewModel.canSubmit
    }

    private func submit() {
        guard viewModel.canSubmit else { return }
        view.endEditing(true)
        delegate?.createAccountViewController(self, didSubmit: viewModel.form)
    }
}

// MARK: - UITextFieldDelegate

extension CreateAccountViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameField.textField: emailField.textField.becomeFirstResponder()
        case emailField.textField: passwordField.textField.becomeFirstResponder()
        case passwordField.textField: inviteCodeField.textField.becomeFirstResponder()
        default: textField.resignFirstResponder()
        }
        return false
    }
}
