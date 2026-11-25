import UIKit

/// Figma `v4 O2 Hot water` — plan setup step 2 of 6.
final class HotWaterViewController: PlanSetupStepViewController {
    private let viewModel: HotWaterViewModel
    private let systemOptions: OptionCardGroupView
    private let showerChips: ChipGroupView

    init(viewModel: HotWaterViewModel) {
        self.viewModel = viewModel
        systemOptions = OptionCardGroupView(
            options: HotWaterSystem.allCases.map { ($0.title, $0.subtitle) },
            selectedIndex: viewModel.draft.hotWater.flatMap { HotWaterSystem.allCases.firstIndex(of: $0) }
        )
        showerChips = ChipGroupView(
            options: ShowerDuration.allCases.map(\.title),
            selectedIndex: viewModel.draft.showerDuration.flatMap { ShowerDuration.allCases.firstIndex(of: $0) }
        )
        super.init()
    }

    override var currentDraft: PlanSetupDraft { viewModel.draft }
    override var canContinue: Bool { viewModel.canContinue }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStep(
            HotWaterViewModel.step,
            question: String(localized: "How is your water heated?", comment: "Setup step 2 question"),
            personalises: String(localized: "hot-water habits, e.g. H09 shorter showers", comment: "What the hot-water answers personalise"),
            blocks: [
                systemOptions,
                LabeledSectionView(title: String(localized: "Your usual shower", comment: "Setup section"), content: showerChips),
            ]
        )

        systemOptions.onSelectionChange = { [weak self] index in
            self?.viewModel.setHotWater(HotWaterSystem.allCases[index])
            self?.updateContinueButton()
        }
        showerChips.onSelectionChange = { [weak self] index in
            self?.viewModel.setShowerDuration(ShowerDuration.allCases[index])
            self?.updateContinueButton()
        }
    }
}
