import UIKit

/// Figma `v4 O5 Your week` — plan setup step 5 of 6.
final class YourWeekViewController: PlanSetupStepViewController {
    private let viewModel: YourWeekViewModel
    private let availabilityGrid: AvailabilityGridView
    private let delayTimerRow: ToggleRowView

    init(viewModel: YourWeekViewModel) {
        self.viewModel = viewModel
        availabilityGrid = AvailabilityGridView(selection: viewModel.draft.homeSlots)
        delayTimerRow = ToggleRowView(
            title: String(localized: "Washer has a delay timer", comment: "Setup toggle"),
            subtitle: String(localized: "Lets us suggest starting it while you sleep", comment: "Setup toggle detail"),
            isOn: viewModel.draft.washerHasDelayTimer
        )
        super.init()
    }

    override var currentDraft: PlanSetupDraft { viewModel.draft }
    override var canContinue: Bool { viewModel.canContinue }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStep(
            YourWeekViewModel.step,
            question: String(localized: "When are you usually home?", comment: "Setup step 5 question"),
            personalises: String(localized: "when Green Hours prompts reach you", comment: "What the availability answers personalise"),
            blocks: [availabilityGrid, delayTimerRow]
        )
        delayTimerRow.isHidden = !viewModel.asksAboutDelayTimer

        availabilityGrid.onChange = { [weak self] slots in
            self?.viewModel.setHomeSlots(slots)
            self?.updateContinueButton()
        }
        delayTimerRow.toggle.addAction(UIAction { [weak self] action in
            guard let self, let toggle = action.sender as? UISwitch else { return }
            viewModel.setWasherHasDelayTimer(toggle.isOn)
        }, for: .valueChanged)
    }
}
