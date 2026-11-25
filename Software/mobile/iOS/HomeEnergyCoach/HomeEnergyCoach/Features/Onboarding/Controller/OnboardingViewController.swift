import UIKit

@MainActor
protocol OnboardingViewControllerDelegate: AnyObject {
    func onboardingViewController(_ controller: OnboardingViewController, didFinishWith route: OnboardingViewModel.Route)
}

/// Intro carousel (Figma `v4 I1–I3 Intro`).
///
/// The header and footer are shared across pages; the illustration and copy
/// live in swipeable child pages hosted by a `UIPageViewController`.
final class OnboardingViewController: UIViewController {
    weak var delegate: OnboardingViewControllerDelegate?

    private let viewModel: OnboardingViewModel
    private let headerView = OnboardingHeaderView()
    private let footerView: OnboardingFooterView
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private lazy var pageControllers: [OnboardingPageViewController] = viewModel.pages.indices.map { index in
        OnboardingPageViewController(
            page: viewModel.pages[index],
            pageIndex: index,
            stepText: viewModel.stepText(at: index),
            stepAccessibilityLabel: viewModel.stepAccessibilityLabel(at: index)
        )
    }
    private var hasPlayedEntrance = false

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        self.footerView = OnboardingFooterView(numberOfPages: viewModel.pageCount)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setUpPageViewController()
        setUpLayout()
        setUpActions()
        render(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        guard !hasPlayedEntrance else { return }
        hasPlayedEntrance = true
        // Figma timeline: brand mark at 50ms, footer at 500ms (page content animates itself).
        let steps: [EntranceAnimation.Step] = [
            .rise(headerView.brandMarkView, delay: 0.05),
            .rise(footerView, delay: 0.5),
        ]
        EntranceAnimation.prepare(steps)
        EntranceAnimation.play(steps)
    }

    // MARK: - Setup

    private func setUpPageViewController() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([pageControllers[viewModel.currentIndex]], direction: .forward, animated: false)
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
    }

    private func setUpLayout() {
        view.addSubview(headerView)
        view.addSubview(footerView)

        let pages = pageViewController.view!
        let safeArea = view.safeAreaLayoutGuide

        // Figma places the footer 32pt above the screen edge; never let it
        // fall inside the home-indicator area on devices that have one.
        let footerBottom = footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.l)
        footerBottom.priority = .defaultHigh

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: Spacing.s),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),

            pages.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: Spacing.m),
            pages.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pages.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pages.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: -Spacing.m),

            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.m),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.m),
            footerBottom,
            footerView.bottomAnchor.constraint(lessThanOrEqualTo: safeArea.bottomAnchor),
        ])
    }

    private func setUpActions() {
        footerView.primaryButton.addAction(UIAction { [weak self] _ in self?.primaryTapped() }, for: .primaryActionTriggered)
        headerView.secondaryButton.addAction(UIAction { [weak self] _ in self?.secondaryTapped() }, for: .primaryActionTriggered)
    }

    // MARK: - Actions

    private func primaryTapped() {
        switch viewModel.primaryAction() {
        case .showPage(let index):
            view.isUserInteractionEnabled = false
            pageViewController.setViewControllers([pageControllers[index]], direction: .forward, animated: true) { [weak self] _ in
                self?.view.isUserInteractionEnabled = true
            }
            render(animated: true)
            UIAccessibility.post(notification: .screenChanged, argument: pageControllers[index].view)
        case .finish(let route):
            delegate?.onboardingViewController(self, didFinishWith: route)
        }
    }

    private func secondaryTapped() {
        delegate?.onboardingViewController(self, didFinishWith: viewModel.secondaryRoute)
    }

    // MARK: - Rendering

    private func render(animated: Bool) {
        headerView.secondaryButton.title = viewModel.secondaryButtonTitle
        footerView.update(
            currentPage: viewModel.currentIndex,
            buttonTitle: viewModel.primaryButtonTitle,
            isFinalStep: viewModel.isLastPage,
            animated: animated
        )
    }
}

// MARK: - UIPageViewControllerDataSource

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? OnboardingPageViewController, page.pageIndex > 0 else { return nil }
        return pageControllers[page.pageIndex - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? OnboardingPageViewController,
              page.pageIndex < pageControllers.count - 1 else { return nil }
        return pageControllers[page.pageIndex + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed, let page = pageViewController.viewControllers?.first as? OnboardingPageViewController else { return }
        viewModel.didShowPage(at: page.pageIndex)
        render(animated: true)
    }
}
