import UIKit

/// Figma `v4 09 Data & privacy` — what each input is used for, privacy switches, export and deletion.
final class DataPrivacyViewController: FormScreenViewController {
    var onExport: ((PrivacySettings) -> Void)?
    /// Called after the user confirms account deletion.
    var onDeleteAccount: (() -> Void)?

    private let store: PrivacySettingsStoring

    init(store: PrivacySettingsStoring) {
        self.store = store
        super.init(navigationTitle: String(localized: "Data & privacy", comment: "Privacy nav title"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let exportButton = AppButton(kind: .ghost, title: String(localized: "Export data", comment: "Privacy action"))
        let deleteButton = AppButton(kind: .destructiveGhost, title: String(localized: "Delete account", comment: "Privacy action"))
        exportButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            onExport?(store.settings)
        }, for: .primaryActionTriggered)
        deleteButton.addAction(UIAction { [weak self] _ in self?.confirmDeletion() }, for: .primaryActionTriggered)

        setContent([
            HeadlineView(
                title: String(localized: "What your data does", comment: "Privacy title"),
                subtitle: String(localized: "Every input has one job. Nothing else is collected.", comment: "Privacy subtitle")
            ),
            makeUsageCard(),
            makeSwitchesCard(),
            UIView.stack([exportButton, deleteButton], axis: .horizontal, spacing: 8, distribution: .fillEqually),
        ])
    }

    private func makeUsageCard() -> UIView {
        let usages: [(input: String, use: String, source: String)] = [
            (String(localized: "Quiz answers", comment: "Data input"), String(localized: "Baseline and user type", comment: "Data use"),
             String(localized: "R · k-means clustering", comment: "Data method")),
            (String(localized: "Check-ins", comment: "Data input"), String(localized: "Next-habit ranking, habit pairs", comment: "Data use"),
             String(localized: "R · recommenderlab, arules", comment: "Data method")),
            (String(localized: "Public SMARD data", comment: "Data input"), String(localized: "Green Hours forecast", comment: "Data use"),
             String(localized: "R · time-series forecast", comment: "Data method")),
        ]
        var rows: [UIView] = usages.map { usage in
            let line = Self.mappingLine(usage.input, inputColor: AppColor.ink, icon: .iconChevronRightTiny, usage.use, useColor: AppColor.green)
            let stack = UIView.stack([line, StyledLabel.section(usage.source)], spacing: 4)
            stack.isAccessibilityElement = true
            stack.accessibilityLabel = "\(usage.input): \(usage.use). \(usage.source)"
            return ListRow(content: stack)
        }
        let never = Self.mappingLine(String(localized: "Never collected", comment: "Data input"), inputColor: AppColor.brand, icon: .iconClose,
                                     String(localized: "Location, contacts, microphone", comment: "Data never collected"), useColor: AppColor.ink2)
        never.isAccessibilityElement = true
        never.accessibilityLabel = String(localized: "Never collected: location, contacts, microphone", comment: "Data never collected")
        rows.append(ListRow(content: never))
        return DividedListCard(rows: rows, verticalInset: 6)
    }

    private static func mappingLine(_ input: String, inputColor: UIColor, icon: ImageResource, _ use: String, useColor: UIColor) -> UIView {
        let inputLabel = StyledLabel.make(input, style: .bodyStrong, color: inputColor, lines: 1)
        inputLabel.setContentHuggingPriority(.required, for: .horizontal)
        inputLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let arrow = UIImageView(image: UIImage(resource: icon))
        arrow.setContentHuggingPriority(.required, for: .horizontal)
        arrow.setContentCompressionResistancePriority(.required, for: .horizontal)
        let useLabel = StyledLabel.make(use, style: .bodyStrong, color: useColor)
        return UIView.stack([inputLabel, arrow, useLabel], axis: .horizontal, spacing: 8, alignment: .center)
    }

    private func makeSwitchesCard() -> UIView {
        let settings = store.settings
        let switches: [(String, KeyPath<PrivacySettings, Bool>, WritableKeyPath<PrivacySettings, Bool>)] = [
            (String(localized: "Share progress with my WG", comment: "Privacy switch"), \.shareProgressWithWG, \.shareProgressWithWG),
            (String(localized: "Improve recommendations anonymously", comment: "Privacy switch"), \.improveRecommendations, \.improveRecommendations),
            (String(localized: "Reminders", comment: "Privacy switch"), \.reminders, \.reminders),
        ]
        let rows = switches.map { title, readPath, writePath -> UIView in
            let row = ToggleRowView(title: title, isOn: settings[keyPath: readPath], titleStyle: .bodyStrong)
            row.toggle.addAction(UIAction { [weak self] action in
                guard let self, let toggle = action.sender as? UISwitch else { return }
                var updated = store.settings
                updated[keyPath: writePath] = toggle.isOn
                store.settings = updated
            }, for: .valueChanged)
            return ListRow(content: row)
        }
        return DividedListCard(rows: rows)
    }

    private func confirmDeletion() {
        let alert = UIAlertController(
            title: String(localized: "Delete your account?", comment: "Delete account confirmation title"),
            message: String(localized: "Your plan, check-ins and settings will be removed. This can't be undone.", comment: "Delete account confirmation message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "Cancel", comment: "Alert action"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Delete", comment: "Alert action"), style: .destructive) { [weak self] _ in
            self?.onDeleteAccount?()
        })
        present(alert, animated: true)
    }
}
