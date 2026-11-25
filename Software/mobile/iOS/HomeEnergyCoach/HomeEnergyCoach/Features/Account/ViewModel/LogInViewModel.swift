import Foundation

struct LogInForm: Equatable, Sendable {
    var email = ""
    var password = ""
    var rememberMe = false
}

/// State and validation for `v4 A3 Log in`.
@MainActor
final class LogInViewModel {
    var form = LogInForm()

    /// When `false`, "Log in" is always enabled and the fields are optional.
    /// TODO: Default to `true` once the account API exists — until then login is skipped.
    let requiresCredentials: Bool

    init(requiresCredentials: Bool = false) {
        self.requiresCredentials = requiresCredentials
    }

    var canSubmit: Bool {
        guard requiresCredentials else { return true }
        return EmailValidator.isValid(form.email) && !form.password.isEmpty
    }
}
