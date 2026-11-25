import UIKit

/// A row of equal 4pt bars, the first `filledCount` tinted. Used for
/// setup-step progress and password strength.
final class SegmentedProgressView: UIView {
    private let segments: [UIView]
    private let filledColor: UIColor

    var filledCount: Int = 0 {
        didSet { applyState() }
    }

    init(segmentCount: Int, filledColor: UIColor = AppColor.brand, height: CGFloat = 4, spacing: CGFloat = 4) {
        self.filledColor = filledColor
        self.segments = (0..<segmentCount).map { _ in UIView() }
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: segments)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = spacing
        addSubview(stack)
        segments.forEach { $0.layer.cornerRadius = height / 2 }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.heightAnchor.constraint(equalToConstant: height),
        ])
        applyState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyState() {
        for (index, segment) in segments.enumerated() {
            segment.backgroundColor = index < filledCount ? filledColor : AppColor.line
        }
    }
}
