import UIKit

/// Staggered "fade + rise" entrance animation, as specified by the Figma motion timeline.
///
/// Each step fades a view in from `alpha = 0` and eases its transform back to identity.
/// When Reduce Motion is enabled, the transform is skipped and only a short cross-fade runs.
@MainActor
enum EntranceAnimation {
    struct Step {
        let view: UIView
        let delay: TimeInterval
        let fadeDuration: TimeInterval
        let transformDuration: TimeInterval
        let initialTransform: CGAffineTransform

        /// Fade in while rising by `offset` points (Figma: translateY 8 → 0).
        static func rise(
            _ view: UIView,
            delay: TimeInterval,
            duration: TimeInterval = 0.35,
            offset: CGFloat = 8
        ) -> Step {
            Step(view: view, delay: delay, fadeDuration: duration, transformDuration: duration,
                 initialTransform: CGAffineTransform(translationX: 0, y: offset))
        }

        /// Fade in while scaling up from `scale` (Figma: scale 0.96 → 1).
        static func grow(
            _ view: UIView,
            delay: TimeInterval = 0,
            fadeDuration: TimeInterval = 0.5,
            scaleDuration: TimeInterval = 0.6,
            from scale: CGFloat = 0.96
        ) -> Step {
            Step(view: view, delay: delay, fadeDuration: fadeDuration, transformDuration: scaleDuration,
                 initialTransform: CGAffineTransform(scaleX: scale, y: scale))
        }
    }

    /// Figma's standard screen entrance: each block rises in turn, 50ms apart, starting at 50ms.
    static func cascade(_ views: [UIView], start: TimeInterval = 0.05, interval: TimeInterval = 0.05) -> [Step] {
        views.enumerated().map { index, view in
            .rise(view, delay: start + Double(index) * interval)
        }
    }

    /// Puts every view in its pre-animation state. Call before the views become visible.
    static func prepare(_ steps: [Step]) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        for step in steps {
            step.view.alpha = 0
            step.view.transform = reduceMotion ? .identity : step.initialTransform
        }
    }

    /// Animates every view to its final state.
    static func play(_ steps: [Step]) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        for step in steps {
            if reduceMotion {
                UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction]) {
                    step.view.alpha = 1
                }
                continue
            }
            UIView.animate(withDuration: step.fadeDuration, delay: step.delay,
                           options: [.curveEaseOut, .allowUserInteraction]) {
                step.view.alpha = 1
            }
            UIView.animate(withDuration: step.transformDuration, delay: step.delay,
                           options: [.curveEaseOut, .allowUserInteraction]) {
                step.view.transform = .identity
            }
        }
    }
}
