import UIKit

/// Figma `v4 O6 Your focus` — plan setup step 6 of 6.
final class YourFocusViewController: PlanSetupStepViewController {
    private let viewModel: YourFocusViewModel
    private let focusOptions: OptionCardGroupView
    private let nudgePicker: SegmentedChoiceView
    private let shareRow: ToggleRowView

    init(viewModel: YourFocusViewModel) {
        self.viewModel = viewModel
        let focuses = CoachFocus.allCases
        focusOptions = OptionCardGroupView(
            options: focuses.map { ($0.title, $0.subtitle) },
            selectedIndices: Set(viewModel.draft.focusAreas.compactMap { focuses.firstIndex(of: $0) }),
            allowsMultipleSelection: true
        )
        nudgePicker = SegmentedChoiceView(
            options: NudgeFrequency.allCases.map(\.title),
            selectedIndex: NudgeFrequency.allCases.firstIndex(of: viewModel.draft.nudgeFrequency)
        )
        shareRow = ToggleRowView(
            title: String(localized: "Improve recommendations", comment: "Setup toggle"),
            subtitle: String(localized: "Share check-ins anonymously with the R models", comment: "Setup toggle detail"),
            isOn: viewModel.draft.sharesCheckInsAnonymously
        )
        super.init(continueTitle: String(localized: "Build my plan", comment: "Final setup action"))
    }

    override var currentDraft: PlanSetupDraft { viewModel.draft }
    override var canContinue: Bool { viewModel.canContinue }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStep(
            YourFocusViewModel.step,
            question: String(localized: "What should your coach focus on?", comment: "Setup step 6 question"),
            personalises: String(localized: "how habits are ranked and how often you're nudged", comment: "What the focus answers personalise"),
            blocks: [
                focusOptions,
                LabeledSectionView(title: String(localized: "Nudges per week", comment: "Setup section"), content: nudgePicker),
                shareRow,
            ]
        )

        focusOptions.onSelectionChange = { [weak self] index in
            self?.viewModel.toggle(CoachFocus.allCases[index])
            self?.updateContinueButton()
        }
        nudgePicker.onSelectionChange = { [weak self] index in
            self?.viewModel.setNudgeFrequency(NudgeFrequency.allCases[index])
        }
        shareRow.toggle.addAction(UIAction { [weak self] action in
            guard let self, let toggle = action.sender as? UISwitch else { return }
            viewModel.setSharesCheckIns(toggle.isOn)
        }, for: .valueChanged)
    }
}
