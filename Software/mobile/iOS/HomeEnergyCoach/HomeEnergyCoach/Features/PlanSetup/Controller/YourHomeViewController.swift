import UIKit

/// Figma `v4 O1 Your home` — plan setup step 1 of 6.
final class YourHomeViewController: PlanSetupStepViewController {
    private let viewModel: YourHomeViewModel
    private let householdCard: HouseholdSizeCardView
    private let flatSizeChips: ChipGroupView
    private let postcodeField = FormTextField(
        title: String(localized: "Postcode", comment: "Setup field"),
        placeholder: String(localized: "e.g. 60311", comment: "Postcode placeholder")
    )
    private let kWhField = FormTextField(
        title: String(localized: "Yearly kWh from your bill (optional)", comment: "Setup field"),
        placeholder: String(localized: "e.g. 2,100 kWh", comment: "Yearly kWh placeholder")
    )

    init(viewModel: YourHomeViewModel) {
        self.viewModel = viewModel
        householdCard = HouseholdSizeCardView(value: viewModel.draft.householdSize, range: PlanSetupDraft.householdSizeRange)
        flatSizeChips = ChipGroupView(
            options: FlatSize.allCases.map(\.title),
            selectedIndex: viewModel.draft.flatSize.flatMap { FlatSize.allCases.firstIndex(of: $0) }
        )
        super.init()
    }

    override var currentDraft: PlanSetupDraft { viewModel.draft }
    override var canContinue: Bool { viewModel.canContinue }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureFields()
        setStep(
            YourHomeViewModel.step,
            question: String(localized: "How many people live in your WG?", comment: "Setup step 1 question"),
            personalises: String(localized: "your baseline, compared with similar WGs", comment: "What the household answers personalise"),
            blocks: [
                householdCard,
                LabeledSectionView(title: String(localized: "Flat size", comment: "Setup section"), content: flatSizeChips),
                postcodeField,
                kWhField,
            ]
        )
        bindActions()
    }

    private func configureFields() {
        postcodeField.text = viewModel.draft.postcode
        postcodeField.textField.keyboardType = .numberPad
        postcodeField.textField.textContentType = .postalCode

        kWhField.text = viewModel.yearlyKWhText
        kWhField.textField.keyboardType = .numberPad
    }

    private func bindActions() {
        householdCard.stepper.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.setHouseholdSize(householdCard.stepper.value)
            householdCard.setCount(viewModel.draft.householdSize)
        }, for: .valueChanged)

        flatSizeChips.onSelectionChange = { [weak self] index in
            self?.viewModel.setFlatSize(FlatSize.allCases[index])
            self?.updateContinueButton()
        }

        postcodeField.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.setPostcode(postcodeField.text)
            if postcodeField.text != viewModel.draft.postcode { postcodeField.text = viewModel.draft.postcode }
            updateContinueButton()
        }, for: .editingChanged)

        kWhField.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.setYearlyKWh(kWhField.text)
            if kWhField.text != viewModel.yearlyKWhText { kWhField.text = viewModel.yearlyKWhText }
        }, for: .editingChanged)
    }
}
