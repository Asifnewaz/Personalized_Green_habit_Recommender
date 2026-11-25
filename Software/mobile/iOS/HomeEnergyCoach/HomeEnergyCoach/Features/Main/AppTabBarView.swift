import UIKit

/// The five main sections (Figma component `v4/Tab bar`).
enum MainTab: Int, CaseIterable {
    case home, plan, greenHours, wg, impact

    var title: String {
        switch self {
        case .home: String(localized: "Home", comment: "Tab title")
        case .plan: String(localized: "Plan", comment: "Tab title")
        case .greenHours: String(localized: "Green Hours", comment: "Tab title")
        case .wg: String(localized: "WG", comment: "Tab title")
        case .impact: String(localized: "Impact", comment: "Tab title")
        }
    }

    var icon: ImageResource {
        switch self {
        case .home: .iconTabHome
        case .plan: .iconTabSparkles
        case .greenHours: .iconTabZap
        case .wg: .iconTabUsers
        case .impact: .iconTabChart
        }
    }
}

/// Figma `v4/Tab bar`: top hairline, five items, a 24×3pt `brand` indicator above the active
/// item, `ink` + SemiBold label when active and `ink-3` + Regular otherwise.
final class AppTabBarView: UIView {
    /// Height of the tappable content above the home indicator.
    static let contentHeight: CGFloat = 62

    private let items: [TabItemControl]
    var onSelect: ((MainTab) -> Void)?

    init() {
        items = MainTab.allCases.map(TabItemControl.init(tab:))
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AppColor.background
        accessibilityTraits = .tabBar

        let hairline = UIView()
        hairline.translatesAutoresizingMaskIntoConstraints = false
        hairline.backgroundColor = AppColor.line
        addSubview(hairline)

        let stack = UIView.stack(items, axis: .horizontal, distribution: .fillEqually)
        addSubview(stack)

        NSLayoutConstraint.activate([
            hairline.topAnchor.constraint(equalTo: topAnchor),
            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.heightAnchor.constraint(equalToConstant: Self.contentHeight),
        ])

        for item in items {
            item.addAction(UIAction { [weak self] _ in self?.onSelect?(item.tab) }, for: .touchUpInside)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func select(_ tab: MainTab) {
        for item in items {
            item.isSelected = item.tab == tab
        }
    }
}

private final class TabItemControl: UIControl {
    let tab: MainTab
    private let indicator = UIView()
    private let iconView = UIImageView()
    private let titleLabel = StyledLabel(style: .caption, color: AppColor.ink3, numberOfLines: 1)

    override var isSelected: Bool {
        didSet { applyState() }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    init(tab: MainTab) {
        self.tab = tab
        super.init(frame: .zero)

        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.layer.cornerRadius = 1.5
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(resource: tab.icon).withRenderingMode(.alwaysTemplate)
        titleLabel.textAlignment = .center
        // "Green Hours" in SemiBold is slightly wider than a fifth of a 393pt bar.
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.content = tab.title
        [indicator, iconView, titleLabel].forEach {
            $0.isUserInteractionEnabled = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            indicator.topAnchor.constraint(equalTo: topAnchor),
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 24),
            indicator.heightAnchor.constraint(equalToConstant: 3),

            iconView.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 14),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        isAccessibilityElement = true
        accessibilityLabel = tab.title
        applyState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyState() {
        indicator.backgroundColor = isSelected ? AppColor.brand : .clear
        iconView.tintColor = isSelected ? AppColor.ink : AppColor.ink3
        titleLabel.style = isSelected ? .label : .caption
        titleLabel.styledColor = isSelected ? AppColor.ink : AppColor.ink3
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
