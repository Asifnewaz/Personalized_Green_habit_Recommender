import UIKit

/// The swipeable part of an intro page: illustration card, step label, title and body.
///
/// Content sits in a scroll view so it stays reachable on compact devices
/// and at large Dynamic Type sizes.
final class OnboardingPageContentView: UIView {
    private enum Metrics {
        static let illustrationHeight: CGFloat = 372
    }

    private let scrollView = UIScrollView()
    private let illustrationContainer = UIView()
    private let illustrationView = UIImageView()
    private let stepLabel = StyledLabel(style: .meta, color: AppColor.green, numberOfLines: 1)
    private let titleLabel = StyledLabel(style: .h1, color: AppColor.ink)
    private let messageLabel = StyledLabel(style: .body, color: AppColor.ink2)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with page: OnboardingPage, stepText: String, stepAccessibilityLabel: String) {
        illustrationView.image = UIImage(resource: page.illustration)
        illustrationView.accessibilityLabel = page.illustrationDescription
        stepLabel.content = stepText
        stepLabel.accessibilityLabel = stepAccessibilityLabel
        titleLabel.content = page.title
        messageLabel.content = page.message
    }

    /// Animation steps matching the Figma motion timeline (image, meta, title, body).
    var entranceSteps: [EntranceAnimation.Step] {
        [
            .grow(illustrationContainer),
            .rise(stepLabel, delay: 0.25),
            .rise(titleLabel, delay: 0.32),
            .rise(messageLabel, delay: 0.40),
        ]
    }

    private func setUpLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        illustrationContainer.translatesAutoresizingMaskIntoConstraints = false
        illustrationContainer.backgroundColor = AppColor.illustrationBackground
        illustrationContainer.layer.cornerRadius = CornerRadius.illustration
        illustrationContainer.layer.cornerCurve = .continuous
        illustrationContainer.clipsToBounds = true

        illustrationView.translatesAutoresizingMaskIntoConstraints = false
        illustrationView.contentMode = .scaleAspectFill
        illustrationView.clipsToBounds = true
        illustrationView.isAccessibilityElement = true
        illustrationView.accessibilityTraits = .image
        illustrationContainer.addSubview(illustrationView)

        titleLabel.accessibilityTraits = .header

        let textStack = UIStackView(arrangedSubviews: [stepLabel, titleLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = Spacing.xs
        textStack.alignment = .fill

        let contentStack = UIStackView(arrangedSubviews: [illustrationContainer, textStack])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = Spacing.m
        scrollView.addSubview(contentStack)

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: content.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Spacing.m),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Spacing.m),
            contentStack.widthAnchor.constraint(equalTo: frame.widthAnchor, constant: -2 * Spacing.m),

            illustrationContainer.heightAnchor.constraint(equalToConstant: Metrics.illustrationHeight),
            illustrationView.topAnchor.constraint(equalTo: illustrationContainer.topAnchor),
            illustrationView.bottomAnchor.constraint(equalTo: illustrationContainer.bottomAnchor),
            illustrationView.leadingAnchor.constraint(equalTo: illustrationContainer.leadingAnchor),
            illustrationView.trailingAnchor.constraint(equalTo: illustrationContainer.trailingAnchor),
        ])
    }
}
