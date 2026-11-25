import UIKit

/// Figma `v4 O4 Appliances` — plan setup step 4 of 6.
final class AppliancesViewController: PlanSetupStepViewController {
    private enum Row: Int {
        case laundry, dishwasher
    }

    private let viewModel: AppliancesViewModel
    private let applianceChips: ChipGroupView
    private let usageCard: StepperRowsCardView

    init(viewModel: AppliancesViewModel) {
        self.viewModel = viewModel
        let all = Appliance.allCases
        applianceChips = ChipGroupView(
            options: all.map { ChipOption(title: $0.title, icon: $0.icon) },
            selectedIndices: Set(viewModel.draft.appliances.compactMap { all.firstIndex(of: $0) }),
            allowsMultipleSelection: true
        )
        usageCard = StepperRowsCardView(rows: [
            .init(title: String(localized: "Laundry loads per week", comment: "Appliance usage question"),
                  value: viewModel.draft.laundryLoadsPerWeek, range: PlanSetupDraft.weeklyRunsRange),
            .init(title: String(localized: "Dishwasher runs per week", comment: "Appliance usage question"),
                  value: viewModel.draft.dishwasherRunsPerWeek, range: PlanSetupDraft.weeklyRunsRange),
        ])
        super.init()
    }

    override var currentDraft: PlanSetupDraft { viewModel.draft }
    override var canContinue: Bool { viewModel.canContinue }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStep(
            AppliancesViewModel.step,
            question: String(localized: "Which appliances do you have?", comment: "Setup step 4 question"),
            personalises: String(localized: "timing habits H01–H04 in green hours", comment: "What the appliance answers personalise"),
            blocks: [applianceChips, usageCard]
        )
        updateUsageRows(animated: false)

        applianceChips.onSelectionChange = { [weak self] index in
            self?.viewModel.toggle(Appliance.allCases[index])
            self?.updateUsageRows(animated: true)
        }

        usageCard.steppers[Row.laundry.rawValue].addAction(UIAction { [weak self] action in
            guard let self, let stepper = action.sender as? StepperView else { return }
            viewModel.setLaundryLoads(stepper.value)
        }, for: .valueChanged)

        usageCard.steppers[Row.dishwasher.rawValue].addAction(UIAction { [weak self] action in
            guard let self, let stepper = action.sender as? StepperView else { return }
            viewModel.setDishwasherRuns(stepper.value)
        }, for: .valueChanged)
    }

    /// Only ask about appliances the WG actually owns.
    private func updateUsageRows(animated: Bool) {
        var visible: Set<Int> = []
        if viewModel.asksLaundryLoads { visible.insert(Row.laundry.rawValue) }
        if viewModel.asksDishwasherRuns { visible.insert(Row.dishwasher.rawValue) }

        let update = { self.usageCard.setVisibleRows(visible) }
        guard animated, !UIAccessibility.isReduceMotionEnabled else { return update() }
        UIView.animate(withDuration: 0.25) {
            update()
            self.view.layoutIfNeeded()
        }
    }
}
