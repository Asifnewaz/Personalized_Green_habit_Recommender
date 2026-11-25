import UIKit

@MainActor
protocol HomeViewControllerDelegate: AnyObject {
    func homeViewControllerDidSelectGreenWindow(_ controller: HomeViewController)
    func homeViewControllerDidSelectHabitInProgress(_ controller: HomeViewController)
    func homeViewControllerDidSelectNextHabit(_ controller: HomeViewController)
}

/// Figma `v4 01 Home`.
final class HomeViewController: FormScreenViewController {
    weak var delegate: HomeViewControllerDelegate?

    private let viewModel: HomeViewModel
    private let weeklyCard: WeeklySummaryCardView
    private var habitCard: HabitProgressCardView?
    private var hasPlayedDataAnimations = false

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        weeklyCard = WeeklySummaryCardView(viewModel: viewModel)
        super.init(navigationTitle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var blocks: [UIView] = [
            GreetingHeaderView(date: viewModel.dateText, greeting: viewModel.greeting, initial: viewModel.avatarInitial),
            weeklyCard,
        ]

        if let title = viewModel.greenWindowTitle, let subtitle = viewModel.greenWindowSubtitle {
            let card = GreenWindowCardView(title: title, subtitle: subtitle)
            card.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                delegate?.homeViewControllerDidSelectGreenWindow(self)
            }, for: .touchUpInside)
            blocks.append(card)
        }

        if let habit = viewModel.dashboard.habitInProgress,
           let status = viewModel.habitStatusText, let typical = viewModel.habitTypicalText {
            let card = HabitProgressCardView(habit: habit, status: status, typical: typical)
            card.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                delegate?.homeViewControllerDidSelectHabitInProgress(self)
            }, for: .touchUpInside)
            habitCard = card
            blocks.append(card)
        }

        if let next = viewModel.dashboard.nextHabit, let title = viewModel.nextHabitTitle {
            let card = NextHabitCardView(title: title, reason: next.reason)
            card.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                delegate?.homeViewControllerDidSelectNextHabit(self)
            }, for: .touchUpInside)
            blocks.append(card)
        }

        setContent(blocks)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasPlayedDataAnimations else { return }
        hasPlayedDataAnimations = true
        // Figma timeline: bars rise from ~0.4s, habit progress fills from ~0.6s.
        weeklyCard.bars.animateRise(delay: 0.1)
        habitCard?.progressBar.animateFill(delay: 0.3)
    }
}
