import UIKit

/// Figma `v4 05 Habit catalogue` — all habits, filterable by family and searchable.
final class HabitCatalogueViewController: FormScreenViewController {
    /// Called when a habit with a detail screen is tapped.
    var onSelectHabit: ((Habit) -> Void)?
    /// Habits that have a detail screen (currently in progress).
    var habitsWithDetail: Set<String> = ["H01"]

    private let viewModel: HabitCatalogueViewModel
    private var categoryTiles: [HabitCategory: StatTileView] = [:]
    private let searchField = FormTextField(
        title: String(localized: "Search", comment: "Catalogue search field"),
        placeholder: String(localized: "Try \"shower\" or \"laundry\"", comment: "Catalogue search placeholder")
    )
    private let listContainer = UIView.stack([])

    init(viewModel: HabitCatalogueViewModel = HabitCatalogueViewModel()) {
        self.viewModel = viewModel
        super.init(navigationTitle: String(localized: "Habit catalogue", comment: "Catalogue nav title"))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tiles = HabitCategory.allCases.map { category -> UIView in
            let tile = StatTileView(value: "\(viewModel.count(of: category))", title: category.title,
                                    subtitle: category.mechanism, isInteractive: true)
            tile.accessibilityHint = String(localized: "Filters the list", comment: "Category tile hint")
            tile.addAction(UIAction { [weak self] _ in self?.toggleFilter(category) }, for: .touchUpInside)
            categoryTiles[category] = tile
            return tile
        }

        searchField.textField.returnKeyType = .search
        searchField.textField.autocorrectionType = .no
        searchField.textField.clearButtonMode = .whileEditing
        searchField.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.query = searchField.text
            renderList()
        }, for: .editingChanged)

        setContent([
            HeadlineView(
                title: viewModel.title,
                subtitle: String(localized: "Everything a renter can change without touching the building.", comment: "Catalogue subtitle")
            ),
            UIView.stack(tiles, axis: .horizontal, spacing: 8, distribution: .fillEqually),
            searchField,
            listContainer,
        ])
        renderList()
    }

    private func toggleFilter(_ category: HabitCategory) {
        viewModel.category = viewModel.category == category ? nil : category
        for (tileCategory, tile) in categoryTiles {
            tile.isSelected = tileCategory == viewModel.category
        }
        renderList()
    }

    private func renderList() {
        listContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let habits = viewModel.visibleHabits
        guard !habits.isEmpty else {
            let empty = StyledLabel.make(String(localized: "No habits match your search.", comment: "Catalogue empty state"),
                                         style: .body, color: AppColor.ink2)
            empty.textAlignment = .center
            listContainer.addArrangedSubview(empty)
            return
        }

        let rows = habits.map { habit -> UIView in
            let trailing: UIView? = switch viewModel.status(of: habit) {
            case .inPlan: TagView(text: String(localized: "In plan", comment: "Habit status"), textColor: AppColor.green, backgroundColor: AppColor.greenSoft)
            case .next: TagView(text: String(localized: "Next", comment: "Habit status"), backgroundColor: AppColor.lime)
            case nil: nil
            }
            let content = HabitRowContentView(code: habit.code, title: habit.title, subtitle: habit.categoryLine, trailing: trailing)
            let isTappable = habitsWithDetail.contains(habit.code)
            let row = ListRow(content: content, isTappable: isTappable)
            if isTappable {
                row.accessibilityLabel = content.accessibilityLabel
                row.addAction(UIAction { [weak self] _ in self?.onSelectHabit?(habit) }, for: .touchUpInside)
            }
            return row
        }
        listContainer.addArrangedSubview(DividedListCard(rows: rows))
    }
}
