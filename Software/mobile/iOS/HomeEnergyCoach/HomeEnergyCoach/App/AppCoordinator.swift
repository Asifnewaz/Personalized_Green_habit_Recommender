import UIKit

/// Owns the window and routes between the top-level flows:
/// intro → welcome/account → plan setup → main app (tabs).
@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let navigationController = AppNavigationController()
    private var planSetupCoordinator: PlanSetupCoordinator?
    private var mainCoordinator: MainCoordinator?
    /// First name from sign-up, used to greet the user on Home.
    private var userName: String?

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        #if DEBUG
        if let screen = UserDefaults.standard.string(forKey: "startScreen"), startDebugScreen(screen) { return }
        #endif
        showOnboardingFlow([makeOnboarding()])
    }

    // MARK: - Flows

    private func showOnboardingFlow(_ stack: [UIViewController]) {
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.setViewControllers(stack, animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    /// Swaps the whole window to the tabbed app (no way "back" into setup).
    @discardableResult
    private func showMainApp(animated: Bool = true) -> MainCoordinator {
        let main = MainCoordinator(userName: userName)
        main.onSignOut = { [weak self] in self?.signOut() }
        mainCoordinator = main
        planSetupCoordinator = nil
        swapRoot(to: main.tabBarController, animated: animated)
        return main
    }

    /// Returns to the welcome screen after the account is deleted.
    private func signOut() {
        userName = nil
        mainCoordinator = nil
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.setViewControllers([makeWelcome()], animated: false)
        swapRoot(to: navigationController, animated: true)
    }

    private func swapRoot(to controller: UIViewController, animated: Bool) {
        guard animated, window.rootViewController != nil else {
            window.rootViewController = controller
            window.makeKeyAndVisible()
            return
        }
        UIView.transition(with: window, duration: 0.35, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
            self.window.rootViewController = controller
        }
    }

    // MARK: - Factories

    private func makeOnboarding() -> UIViewController {
        let controller = OnboardingViewController(viewModel: OnboardingViewModel())
        controller.delegate = self
        return controller
    }

    private func makeWelcome() -> WelcomeViewController {
        let controller = WelcomeViewController()
        controller.delegate = self
        return controller
    }

    private func makeCreateAccount() -> CreateAccountViewController {
        let controller = CreateAccountViewController()
        controller.delegate = self
        return controller
    }

    private func makeLogIn() -> LogInViewController {
        let controller = LogInViewController()
        controller.delegate = self
        return controller
    }

    private func makePlanSetup() -> PlanSetupCoordinator {
        let coordinator = PlanSetupCoordinator(navigationController: navigationController)
        coordinator.onFinish = { [weak self] _, _ in
            // TODO: Persist the draft/plan once a backend exists.
            self?.showMainApp()
        }
        planSetupCoordinator = coordinator
        return coordinator
    }

    // TODO: Replace with a password-reset flow once designed.
    private func makeResetPasswordPlaceholder() -> UIViewController {
        ComingSoonViewController(title: String(localized: "Reset password", comment: "Placeholder title for password reset"))
    }

    /// Swaps the top screen for `controller` (e.g. Create account ⇄ Log in) so the stack doesn't grow.
    private func replaceTop(with controller: UIViewController) {
        var stack = navigationController.viewControllers
        stack.removeLast()
        stack.append(controller)
        navigationController.setViewControllers(stack, animated: true)
    }

    // MARK: - Debug deep links

    #if DEBUG
    /// Launch with `-startScreen <name>` to open a screen directly.
    /// Onboarding: welcome, signup, login, setup, hotwater, heating, appliances, week, focus, plan.
    /// Main app: home, planTab, habit, greenHours, catalogue, quickWins, wg, impact, privacy, greenSoftware.
    private func startDebugScreen(_ name: String) -> Bool {
        let setupSteps: [String: PlanSetupCoordinator.Step] = [
            "setup": .yourHome, "hotwater": .hotWater, "heating": .heating, "appliances": .appliances,
            "week": .yourWeek, "focus": .yourFocus, "plan": .plan,
        ]
        switch name {
        case "welcome": showOnboardingFlow([makeWelcome()])
        case "signup": showOnboardingFlow([makeWelcome(), makeCreateAccount()])
        case "login": showOnboardingFlow([makeWelcome(), makeLogIn()])
        case "home": showMainApp(animated: false)
        case "planTab": showMainApp(animated: false).open(.plan)
        default:
            if let route = MainCoordinator.Route(rawValue: name) {
                showMainApp(animated: false).open(route)
                return true
            }
            guard let step = setupSteps[name] else { return false }
            showOnboardingFlow([makeWelcome()] + makePlanSetup().viewControllers(through: step))
        }
        return true
    }
    #endif
}

// MARK: - OnboardingViewControllerDelegate

extension AppCoordinator: OnboardingViewControllerDelegate {
    func onboardingViewController(_ controller: OnboardingViewController,
                                  didFinishWith route: OnboardingViewModel.Route) {
        // The intro is one-way: replace it so "Back" never returns to the carousel.
        let stack: [UIViewController] = switch route {
        case .welcome: [makeWelcome()]
        case .login: [makeWelcome(), makeLogIn()]
        }
        navigationController.setViewControllers(stack, animated: true)
    }
}

// MARK: - WelcomeViewControllerDelegate

extension AppCoordinator: WelcomeViewControllerDelegate {
    func welcomeViewControllerDidSelectGetStarted(_ controller: WelcomeViewController) {
        navigationController.pushViewController(makeCreateAccount(), animated: true)
    }

    func welcomeViewControllerDidSelectLogIn(_ controller: WelcomeViewController) {
        navigationController.pushViewController(makeLogIn(), animated: true)
    }
}

// MARK: - CreateAccountViewControllerDelegate

extension AppCoordinator: CreateAccountViewControllerDelegate {
    func createAccountViewController(_ controller: CreateAccountViewController, didSubmit form: CreateAccountForm) {
        // TODO: Call the account API; on success continue into plan setup.
        userName = form.name.trimmingCharacters(in: .whitespaces)
        makePlanSetup().start()
    }

    func createAccountViewControllerDidSelectLogIn(_ controller: CreateAccountViewController) {
        replaceTop(with: makeLogIn())
    }
}

// MARK: - LogInViewControllerDelegate

extension AppCoordinator: LogInViewControllerDelegate {
    func logInViewController(_ controller: LogInViewController, didSubmit form: LogInForm) {
        // TODO: Authenticate against the account API, then go straight to Home for returning users.
        // For now login is skipped: every "Log in" runs the plan-setup questionnaire, then Home.
        makePlanSetup().start()
    }

    func logInViewControllerDidSelectFaceID(_ controller: LogInViewController) {
        // TODO: Unlock a stored session with LocalAuthentication once sessions exist.
        makePlanSetup().start()
    }

    func logInViewControllerDidSelectForgotPassword(_ controller: LogInViewController) {
        navigationController.pushViewController(makeResetPasswordPlaceholder(), animated: true)
    }

    func logInViewControllerDidSelectCreateAccount(_ controller: LogInViewController) {
        replaceTop(with: makeCreateAccount())
    }
}
