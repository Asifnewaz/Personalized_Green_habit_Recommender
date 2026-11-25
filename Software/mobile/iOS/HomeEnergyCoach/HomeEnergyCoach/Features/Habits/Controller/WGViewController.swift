import UIKit

/// Figma `v4 07 WG` — flatmates, the monthly challenge and the WG agreement.
final class WGViewController: FormScreenViewController {
    private let viewModel: WGViewModel
    private let contributionBar: ContributionBarView

    init(viewModel: WGViewModel) {
        self.viewModel = viewModel
        contributionBar = ContributionBarView(
            fractions: viewModel.contributionFractions,
            colors: viewModel.overview.members.map { Self.accentColor($0.avatarColor) }
        )
        super.init(navigationTitle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setContent([makeHeader(), makeChallengeCard(), makeAgreementCard()])
    }

    // MARK: - Sections

    private func makeHeader() -> UIView {
        let head = UIView.stack([
            StyledLabel.section(viewModel.header),
            HeadlineView(title: String(localized: "Your WG", comment: "WG title")),
        ], spacing: 8)

        let avatars = UIView.stack([], axis: .horizontal, spacing: -8)
        for member in viewModel.overview.members {
            avatars.addArrangedSubview(AvatarView(initial: member.initial, size: 36,
                                                  fill: Self.avatarColor(member.avatarColor), ringColor: AppColor.background))
        }
        avatars.isAccessibilityElement = true
        avatars.accessibilityLabel = viewModel.overview.members.map(\.name).formatted(.list(type: .and))

        return UIView.stack([head, avatars], axis: .horizontal, spacing: 12, alignment: .bottom)
    }

    private func makeChallengeCard() -> UIView {
        let overview = viewModel.overview
        let progress = UIView.stack([
            StyledLabel.make("\(overview.total)", style: .stat, color: AppColor.onInk, lines: 1),
            StyledLabel.make("/ \(overview.goal)", style: .headline, color: AppColor.onInk2, lines: 1),
            UIView(),
        ], axis: .horizontal, spacing: 6, alignment: .firstBaseline)

        let legend = UIView.stack(zip(overview.members, overview.contributions).map { member, count in
            let dot = UIView()
            dot.backgroundColor = Self.accentColor(member.avatarColor)
            dot.layer.cornerRadius = 4
            NSLayoutConstraint.activate([dot.widthAnchor.constraint(equalToConstant: 8), dot.heightAnchor.constraint(equalToConstant: 8)])
            return UIView.stack([dot, StyledLabel.make("\(member.name) \(count)", style: .caption, color: AppColor.onInk2, lines: 1)],
                                axis: .horizontal, spacing: 6, alignment: .center)
        } + [UIView()], axis: .horizontal, spacing: 14, alignment: .center)

        let card = CardView(content: UIView.stack([
            StyledLabel.section(viewModel.challengeHeader, color: AppColor.onInk2),
            StyledLabel.make(overview.challengeTitle, style: .h2, color: AppColor.onInk),
            progress, contributionBar, legend,
        ], spacing: 12), backgroundColor: AppColor.brand)
        card.isAccessibilityElement = true
        let breakdown = zip(overview.members, overview.contributions).map { "\($0.name) \($1)" }.joined(separator: ", ")
        card.accessibilityLabel = "\(viewModel.challengeHeader). \(overview.challengeTitle): \(overview.total) of \(overview.goal). \(breakdown)"
        return card
    }

    private func makeAgreementCard() -> UIView {
        let overview = viewModel.overview
        let header = UIView.stack([
            StyledLabel.make(String(localized: "WG agreement", comment: "WG agreement title"), style: .h2, lines: 1),
            UIView(),
            TagView.code(overview.agreementCode),
        ], axis: .horizontal, alignment: .center)

        let rules = overview.rules.map { CheckBulletRow(text: $0.text, trailingCode: $0.code) as UIView }

        var signatures: [UIView] = [StyledLabel.section(String(localized: "Signed", comment: "WG agreement signatures"))]
        for member in overview.members {
            let signed = overview.signedBy.contains(member.name)
            signatures.append(AvatarView(initial: member.initial, size: 28,
                                         fill: signed ? Self.avatarColor(member.avatarColor) : AppColor.background,
                                         dashedBorder: signed ? nil : AppColor.ink3))
        }
        signatures.append(StyledLabel.make(viewModel.signatureStatus, style: .caption, color: AppColor.ink2))
        let signatureRow = UIView.stack(signatures, axis: .horizontal, spacing: 8, alignment: .center)
        signatureRow.isAccessibilityElement = true
        signatureRow.accessibilityLabel = viewModel.signatureStatus

        return CardView(content: UIView.stack([header] + rules + [signatureRow], spacing: 12))
    }

    // MARK: - Colors

    private static func avatarColor(_ color: MemberColor) -> UIColor {
        switch color {
        case .greenSoft: AppColor.greenSoft
        case .lime: AppColor.lime
        case .card: AppColor.card
        }
    }

    /// Figma uses `green`, `lime` and `on-ink` for each member's share of the challenge.
    private static func accentColor(_ color: MemberColor) -> UIColor {
        switch color {
        case .greenSoft: AppColor.green
        case .lime: AppColor.lime
        case .card: AppColor.onInk
        }
    }
}

/// Circular initial avatar with an optional ring (overlap stacks) or dashed outline (pending).
final class AvatarView: UIView {
    private let dashedBorder: UIColor?
    private let dashLayer = CAShapeLayer()

    init(initial: String, size: CGFloat, fill: UIColor, ringColor: UIColor? = nil, dashedBorder: UIColor? = nil) {
        self.dashedBorder = dashedBorder
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = fill
        layer.cornerRadius = size / 2
        if let ringColor {
            layer.borderColor = ringColor.cgColor
            layer.borderWidth = 2
        }
        if let dashedBorder {
            dashLayer.strokeColor = dashedBorder.cgColor
            dashLayer.fillColor = nil
            dashLayer.lineWidth = 1
            dashLayer.lineDashPattern = [3, 2]
            layer.addSublayer(dashLayer)
        }
        let label = StyledLabel.make(initial, style: .label, lines: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        if dashedBorder != nil {
            dashLayer.frame = bounds
            dashLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5)).cgPath
        }
    }
}

/// Stacked progress bar: one segment per flatmate on a translucent track (10pt, 3pt gaps).
final class ContributionBarView: UIView {
    private let fractions: [Double]
    private let segments: [UIView]

    init(fractions: [Double], colors: [UIColor]) {
        self.fractions = fractions
        self.segments = colors.map { color in
            let view = UIView()
            view.backgroundColor = color
            return view
        }
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white.withAlphaComponent(0.14)
        layer.cornerRadius = 5
        clipsToBounds = true
        segments.forEach(addSubview)
        heightAnchor.constraint(equalToConstant: 10).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        var x: CGFloat = 0
        for (segment, fraction) in zip(segments, fractions) {
            let width = (bounds.width * fraction).rounded()
            segment.frame = CGRect(x: x, y: 0, width: width, height: bounds.height)
            x += width + (width > 0 ? 3 : 0)
        }
    }
}
