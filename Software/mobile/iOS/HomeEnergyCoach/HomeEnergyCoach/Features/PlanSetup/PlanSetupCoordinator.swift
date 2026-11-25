import UIKit

/// Drives plan setup (Figma `v4 O1–O7`), carrying answers from step to step.
@MainActor
final class PlanSetupCoordinator {
    enum Step: CaseIterable {
        case yourHome, hotWater, heating, appliances, yourWeek, yourFocus, plan
    }

    /// Called when the user taps "Start my plan" on the summary.
    var onFinish: ((PlanSetupDraft, PlanSummary) -> Void)?

    private let navigationController: UINavigationController
    private let recommender: PlanRecommending
    private(set) var draft = PlanSetupDraft()

    init(navigationController: UINavigationController, recommender: PlanRecommending = StubPlanRecommender()) {
        self.navigationController = navigationController
        self.recommender = recommender
    }

    func start(animated: Bool = true) {
        navigationController.pushViewController(makeViewController(for: .yourHome), animated: animated)
    }

    /// Screens for every step up to and including `step` (debug deep links).
    func viewControllers(through step: Step) -> [UIViewController] {
        let steps = Step.allCases
        guard let last = steps.firstIndex(of: step) else { return [] }
        return steps[...last].map(makeViewController(for:))
    }

    func makeViewController(for step: Step) -> UIViewController {
        let controller: UIViewController
        switch step {
        case .yourHome: controller = YourHomeViewController(viewModel: YourHomeViewModel(draft: draft))
        case .hotWater: controller = HotWaterViewController(viewModel: HotWaterViewModel(draft: draft))
        case .heating: controller = HeatingViewController(viewModel: HeatingViewModel(draft: draft))
        case .appliances: controller = AppliancesViewController(viewModel: AppliancesViewModel(draft: draft))
        case .yourWeek: controller = YourWeekViewController(viewModel: YourWeekViewModel(draft: draft))
        case .yourFocus: controller = YourFocusViewController(viewModel: YourFocusViewModel(draft: draft))
        case .plan:
            let plan = recommender.makePlan(from: draft)
            let summary = YourPlanViewController(plan: plan)
            summary.onStart = { [weak self] in
                guard let self else { return }
                onFinish?(draft, plan)
            }
            return summary
        }

        if let stepController = controller as? PlanSetupStepViewController {
            stepController.onContinue = { [weak self] draft in
                self?.advance(from: step, with: draft)
            }
        }
        return controller
    }

    private func advance(from step: Step, with draft: PlanSetupDraft) {
        self.draft = draft
        let steps = Step.allCases
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else { return }
        navigationController.pushViewController(makeViewController(for: steps[index + 1]), animated: true)
    }
}
