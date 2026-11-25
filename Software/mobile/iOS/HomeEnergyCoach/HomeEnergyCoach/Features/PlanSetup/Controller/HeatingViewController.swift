import UIKit

/// Figma `v4 O3 Heating` — plan setup step 3 of 6.
final class HeatingViewController: PlanSetupStepViewController {
    private let viewModel: HeatingViewModel
    private let systemOptions: OptionCardGroupView

    init(viewModel: HeatingViewModel) {
        self.viewModel = viewModel
        systemOptions = OptionCardGroupView(
            options: HeatingSystem.allCases.map { ($0.title, $0.subtitle) },
            selectedIndex: viewModel.draft.heating.flatMap { HeatingSystem.allCases.firstIndex(of: $0) }
        )
        super.init()
    }

    override var currentDraft: PlanSetupDraft { viewModel.draft }
    override var canContinue: Bool { viewModel.canContinue }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStep(
            HeatingViewModel.step,
            question: String(localized: "How is your flat heated?", comment: "Setup step 3 question"),
            personalises: String(localized: "heating habits H05–H08, your biggest lever", comment: "What the heating answer personalises"),
            blocks: [
                systemOptions,
                StatCalloutView(
                    stat: String(localized: "2/3", comment: "Share of household energy used for heating"),
                    caption: String(
                        localized: "of a German household's energy goes to heating. That's why heating habits come first.",
                        comment: "Heating share explanation"
                    )
                ),
            ]
        )

        systemOptions.onSelectionChange = { [weak self] index in
            self?.viewModel.setHeating(HeatingSystem.allCases[index])
            self?.updateContinueButton()
        }
    }
}
