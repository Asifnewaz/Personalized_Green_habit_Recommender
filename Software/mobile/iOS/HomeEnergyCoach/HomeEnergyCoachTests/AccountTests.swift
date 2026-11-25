import Testing
@testable import HomeEnergyCoach

struct EmailValidatorTests {
    @Test(arguments: ["lena@example.de", "  lena@example.de ", "a.b+c@sub.domain.org"])
    func acceptsValidAddresses(email: String) {
        #expect(EmailValidator.isValid(email))
    }

    @Test(arguments: ["", "lena", "lena@", "lena@example", "lena@example.d", "le na@example.de"])
    func rejectsInvalidAddresses(email: String) {
        #expect(!EmailValidator.isValid(email))
    }
}

struct PasswordStrengthTests {
    @Test(arguments: [
        ("", PasswordStrength.empty),
        ("abc", .weak),
        ("abcdefgh", .weak),
        ("abcdefgh1", .fair),
        ("Abcdefgh1", .strong),
        ("Abcdefgh1234", .veryStrong),
    ])
    func evaluatesStrength(password: String, expected: PasswordStrength) {
        #expect(PasswordStrength.evaluate(password) == expected)
    }

    @Test func strongFillsThreeOfFourSegments() {
        #expect(PasswordStrength.strong.filledSegments == 3)
        #expect(PasswordStrength.strong.title == "Strong")
    }
}

@MainActor
struct CreateAccountViewModelTests {
    private func validForm() -> CreateAccountForm {
        CreateAccountForm(name: "Lena", email: "lena@example.de", password: "Abcdefgh1", inviteCode: "", acceptsTerms: true)
    }

    @Test func termsStartUnchecked() {
        #expect(CreateAccountViewModel().form.acceptsTerms == false)
    }

    @Test func validFormCanSubmit() {
        let viewModel = CreateAccountViewModel()
        viewModel.form = validForm()
        #expect(viewModel.canSubmit)
    }

    @Test func eachRequirementBlocksSubmit() {
        let viewModel = CreateAccountViewModel()
        let mutations: [(inout CreateAccountForm) -> Void] = [
            { $0.name = "  " },
            { $0.email = "lena@" },
            { $0.password = "short" },
            { $0.acceptsTerms = false },
        ]
        for mutate in mutations {
            var form = validForm()
            mutate(&form)
            viewModel.form = form
            #expect(!viewModel.canSubmit)
        }
    }

    @Test func inviteCodeIsNormalised() {
        let viewModel = CreateAccountViewModel()
        viewModel.form.inviteCode = " sonne-12 "
        #expect(viewModel.trimmedInviteCode == "SONNE-12")
        viewModel.form.inviteCode = "   "
        #expect(viewModel.trimmedInviteCode == nil)
    }
}

@MainActor
struct LogInViewModelTests {
    @Test func requiresValidEmailAndPassword() {
        let viewModel = LogInViewModel(requiresCredentials: true)
        #expect(!viewModel.canSubmit)
        viewModel.form.email = "lena@example.de"
        #expect(!viewModel.canSubmit)
        viewModel.form.password = "secret"
        #expect(viewModel.canSubmit)
    }

    @Test func canSubmitEmptyFormWhileLoginIsSkipped() {
        #expect(LogInViewModel().canSubmit)
    }
}
