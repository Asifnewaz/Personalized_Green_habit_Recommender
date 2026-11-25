import UIKit

/// Tab container for the main app using the custom `v4/Tab bar`.
///
/// The system tab bar is hidden; `additionalSafeAreaInsets` reserves room for the custom
/// bar so every tab's content (and scroll insets) stays clear of it automatically.
final class MainTabBarController: UITabBarController {
    private let appTabBar = AppTabBarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        tabBar.isHidden = true
        additionalSafeAreaInsets.bottom = AppTabBarView.contentHeight

        view.addSubview(appTabBar)
        NSLayoutConstraint.activate([
            appTabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            appTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            appTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            appTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        appTabBar.onSelect = { [weak self] tab in self?.select(tab) }
        appTabBar.select(MainTab(rawValue: selectedIndex) ?? .home)
    }

    func select(_ tab: MainTab) {
        if selectedIndex == tab.rawValue {
            // Re-tapping the active tab returns to its root, like the system tab bar.
            (selectedViewController as? UINavigationController)?.popToRootViewController(animated: true)
        }
        selectedIndex = tab.rawValue
        appTabBar.select(tab)
    }
}
