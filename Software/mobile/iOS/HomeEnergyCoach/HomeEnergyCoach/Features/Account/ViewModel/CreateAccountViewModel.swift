import Foundation

struct CreateAccountForm: Equatable, Sendable {
    var name = ""
    var email = ""
    var password = ""
    var inviteCode = ""
    /// Consent must be an explicit opt-in (GDPR), so it starts unchecked.
    var acceptsTerms = false
}

/// State and validation for `v4 A2 Create account`.
@MainActor
final class CreateAccountViewModel {
    var form = CreateAccountForm()

    var passwordStrength: PasswordStrength { .evaluate(form.password) }

    var trimmedInviteCode: String? {
        let code = form.inviteCode.trimmingCharacters(in: .whitespaces).uppercased()
        return code.isEmpty ? nil : code
    }

    var canSubmit: Bool {
        !form.name.trimmingCharacters(in: .whitespaces).isEmpty
            && EmailValidator.isValid(form.email)
            && form.password.count >= PasswordStrength.minimumLength
            && form.acceptsTerms
    }
}
