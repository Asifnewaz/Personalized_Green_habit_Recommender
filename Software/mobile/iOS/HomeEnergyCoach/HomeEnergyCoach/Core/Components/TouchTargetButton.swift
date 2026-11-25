import UIKit

/// Base button whose hit area is expanded to at least 44×44pt (HIG minimum),
/// so visually small controls stay easy to tap.
class TouchTargetButton: UIButton {
    var minimumHitSize: CGFloat = 44

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let dx = max(0, minimumHitSize - bounds.width) / 2
        let dy = max(0, minimumHitSize - bounds.height) / 2
        return bounds.insetBy(dx: -dx, dy: -dy).contains(point)
    }
}
