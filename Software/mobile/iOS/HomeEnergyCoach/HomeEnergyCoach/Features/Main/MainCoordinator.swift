import UIKit

/// Builds the tabbed main app (Figma `v4 · 2 · Main app`) and routes between its screens.
@MainActor
final class MainCoordinator {
    /// Screens that can be opened directly (debug deep links, future push notifications).
    enum Route: String {
        case home, plan, habit, greenHours, catalogue, quickWins, wg, impact, privacy, greenSoftware
    }

    let tabBarController = MainTabBarController()
    /// Called after the account is deleted, to return to the welcome flow.
    var onSignOut: (() -> Void)?

    private let homeNavigation = AppNavigationController()
    private let planNavigation = AppNavigationController()
    private let greenHoursNavigation = AppNavigationController()
    private let wgNavigation = AppNavigationController()
    private let impactNavigation = AppNavigationController()

    private let quickWins = QuickWinsViewModel()
    private let privacyStore: PrivacySettingsStoring

    init(
        userName: String?,
        dashboardProvider: HomeDashboardProviding = StubHomeDashboardProvider(),
        privacyStore: PrivacySettingsStoring = UserDefaultsPrivacySettingsStore()
    ) {
        self.privacyStore = privacyStore

        let home = HomeViewController(viewModel: HomeViewModel(dashboard: dashboardProvider.dashboard(userName: userName)))
        homeNavigation.setViewControllers([home], animated: false)
        planNavigation.setViewControllers([makePlan()], animated: false)
        greenHoursNavigation.setViewControllers([GreenHoursViewController(viewModel: GreenHoursViewModel(forecast: .sample))], animated: false)
        wgNavigation.setViewControllers([WGViewController(viewModel: WGViewModel(overview: .sample))], animated: false)
        impactNavigation.setViewControllers([makeImpact()], animated: false)

        tabBarController.viewControllers = [homeNavigation, planNavigation, greenHoursNavigation, wgNavigation, impactNavigation]
        home.delegate = self
    }

    /// Opens a screen inside its tab.
    func open(_ route: Route) {
        switch route {
        case .home: tabBarController.select(.home)
        case .plan: tabBarController.select(.plan)
        case .greenHours: tabBarController.select(.greenHours)
        case .wg: tabBarController.select(.wg)
        case .impact: tabBarController.select(.impact)
        case .habit:
            tabBarController.select(.plan)
            planNavigation.pushViewController(makeHabitDetail(), animated: false)
        case .catalogue:
            tabBarController.select(.plan)
            planNavigation.pushViewController(makeCatalogue(), animated: false)
        case .quickWins:
            tabBarController.select(.impact)
            impactNavigation.pushViewController(makeQuickWins(), animated: false)
        case .privacy:
            tabBarController.select(.impact)
            impactNavigation.pushViewController(makeDataPrivacy(), animated: false)
        case .greenSoftware:
            tabBarController.select(.impact)
            impactNavigation.pushViewController(GreenSoftwareViewController(), animated: false)
        }
    }

    // MARK: - Factories

    private func makePlan() -> UIViewController {
        let plan = PlanViewController()
        plan.onShowCatalogue = { [weak self] in
            guard let self else { return }
            planNavigation.pushViewController(makeCatalogue(), animated: true)
        }
        // TODO: Persist started / dismissed recommendations via the plan API.
        plan.onStartHabit = { _ in }
        plan.onDismissHabit = { _ in }
        return plan
    }

    private func makeCatalogue() -> UIViewController {
        let catalogue = HabitCatalogueViewController()
        catalogue.onSelectHabit = { [weak self] _ in
            guard let self else { return }
            planNavigation.pushViewController(makeHabitDetail(), animated: true)
        }
        return catalogue
    }

    private func makeHabitDetail() -> UIViewController {
        // TODO: Load the selected habit's progress; only H01 has sample data.
        let today = (Calendar.current.component(.weekday, from: .now) + 5) % 7
        let detail = HabitDetailViewController(viewModel: HabitDetailViewModel(detail: .sample, todayIndex: today))
        detail.onCheckIn = { [weak self] in
            // Figma: checking in returns to Home.
            self?.tabBarController.select(.home)
        }
        return detail
    }

    private func makeQuickWins() -> UIViewController {
        let controller = QuickWinsViewController(viewModel: quickWins)
        controller.onOpenWG = { [weak self] in self?.tabBarController.select(.wg) }
        return controller
    }

    private func makeImpact() -> UIViewController {
        let impact = ImpactViewController { [weak self] in
            guard let self else { return (0, 0) }
            return (quickWins.doneCount, quickWins.items.count)
        }
        impact.onShowQuickWins = { [weak self] in
            guard let self else { return }
            impactNavigation.pushViewController(makeQuickWins(), animated: true)
        }
        impact.onShowDataPrivacy = { [weak self] in
            guard let self else { return }
            impactNavigation.pushViewController(makeDataPrivacy(), animated: true)
        }
        impact.onShowGreenSoftware = { [weak self] in
            self?.impactNavigation.pushViewController(GreenSoftwareViewController(), animated: true)
        }
        return impact
    }

    private func makeDataPrivacy() -> UIViewController {
        let privacy = DataPrivacyViewController(store: privacyStore)
        privacy.onExport = { [weak self, weak privacy] settings in
            guard let privacy else { return }
            self?.presentExport(of: settings, from: privacy)
        }
        privacy.onDeleteAccount = { [weak self] in
            // TODO: Call the account-deletion API before clearing local data.
            self?.privacyStore.reset()
            self?.onSignOut?()
        }
        return privacy
    }

    /// Shares the locally stored data as a JSON file.
    /// TODO: Include server-side data (plan, check-ins) once the export API exists.
    private func presentExport(of settings: PrivacySettings, from presenter: UIViewController) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("home-energy-coach-data.json")
        do {
            try encoder.encode(["privacySettings": settings]).write(to: url, options: .atomic)
        } catch {
            let alert = UIAlertController(title: String(localized: "Export failed", comment: "Export error title"),
                                          message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "OK", comment: "Alert action"), style: .default))
            presenter.present(alert, animated: true)
            return
        }
        let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = presenter.view
        presenter.present(share, animated: true)
    }
}

extension MainCoordinator: HomeViewControllerDelegate {
    func homeViewControllerDidSelectGreenWindow(_ controller: HomeViewController) {
        tabBarController.select(.greenHours)
    }

    func homeViewControllerDidSelectHabitInProgress(_ controller: HomeViewController) {
        homeNavigation.pushViewController(makeHabitDetail(), animated: true)
    }

    func homeViewControllerDidSelectNextHabit(_ controller: HomeViewController) {
        tabBarController.select(.plan)
    }
}
