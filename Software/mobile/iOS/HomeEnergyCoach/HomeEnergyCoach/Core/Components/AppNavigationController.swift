import UIKit

/// Navigation controller for screens that draw their own `v4/Nav` header.
///
/// UIKit disables the edge-swipe back gesture when the navigation bar is hidden;
/// this controller re-enables it whenever there is something to go back to.
final class AppNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.tintColor = AppColor.ink
        interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
