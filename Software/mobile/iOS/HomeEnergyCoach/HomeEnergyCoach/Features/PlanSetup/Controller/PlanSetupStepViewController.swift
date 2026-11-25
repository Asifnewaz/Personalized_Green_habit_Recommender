import UIKit

/// Shared chrome for setup steps O1–O6: progress header, question, "Personalises"
/// note, step-specific blocks, and a Continue button enabled only when the answers are valid.
class PlanSetupStepViewController: FormScreenViewController {
    /// Called with the updated answers when the user continues.
    var onContinue: ((PlanSetupDraft) -> Void)?

    let continueButton: AppButton

    init(continueTitle: String = String(localized: "Continue", comment: "Setup primary action")) {
        continueButton = AppButton(kind: .primary, title: continueTitle)
        super.init(navigationTitle: String(localized: "Set up your plan", comment: "Plan setup nav title"))
    }

    /// The answers to hand on when continuing. Subclasses return their view model's draft.
    var currentDraft: PlanSetupDraft { fatalError("Subclasses must override currentDraft") }

    /// Whether the current answers allow continuing. Subclasses override.
    var canContinue: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        continueButton.addAction(UIAction { [weak self] _ in
            guard let self, canContinue else { return }
            view.endEditing(true)
            onContinue?(currentDraft)
        }, for: .primaryActionTriggered)
    }

    /// Installs the standard step layout around `blocks`.
    func setStep(_ step: Int, question: String, personalises: String, blocks: [UIView]) {
        setContent(
            [
                StepProgressHeaderView(step: step),
                HeadlineView(title: question),
                PersonalisesNoteView(text: personalises),
            ] + blocks,
            actions: [continueButton]
        )
        updateContinueButton()
    }

    /// Call after any answer changes.
    func updateContinueButton() {
        continueButton.isEnabled = canContinue
    }
}
