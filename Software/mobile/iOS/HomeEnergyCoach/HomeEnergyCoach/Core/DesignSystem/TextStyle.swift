import UIKit

/// Text styles mirrored from the Figma "v4" type styles.
///
/// Every style scales with Dynamic Type via `UIFontMetrics`, including its
/// line height and tracking, so custom Geist typography stays accessible.
enum TextStyle: CaseIterable {
    /// `v4/Display` — Geist ExtraBold 44/46, -4% tracking.
    case display
    /// `v4/Stat` — Geist ExtraBold 36/38, -4% tracking (big numbers).
    case stat
    /// `v4/H1` — Geist Bold 30/34, -3% tracking.
    case h1
    /// `v4/H2` — Geist Bold 22/26, -2% tracking.
    case h2
    /// `v4/Headline` — Geist SemiBold 16/22, -1% tracking.
    case headline
    /// `v4/Body` — Geist Regular 15/22, -0.5% tracking.
    case body
    /// `v4/Body strong` — Geist SemiBold 15/22, -0.5% tracking.
    case bodyStrong
    /// `v4/Caption` — Geist Regular 13/18.
    case caption
    /// `v4/Label` — Geist SemiBold 13/18.
    case label
    /// `v4/Meta` — Geist Mono Medium 11/14, +2% tracking, uppercase.
    case meta

    private struct Spec {
        let fontName: String
        let size: CGFloat
        let lineHeight: CGFloat
        /// Tracking in points at the base size.
        let tracking: CGFloat
        let fallbackWeight: UIFont.Weight
        let isMonospaced: Bool
        let dynamicTypeStyle: UIFont.TextStyle
    }

    private var spec: Spec {
        switch self {
        case .display:
            Spec(fontName: FontName.geistExtraBold, size: 44, lineHeight: 46, tracking: -1.76,
                 fallbackWeight: .heavy, isMonospaced: false, dynamicTypeStyle: .largeTitle)
        case .stat:
            Spec(fontName: FontName.geistExtraBold, size: 36, lineHeight: 38, tracking: -1.44,
                 fallbackWeight: .heavy, isMonospaced: false, dynamicTypeStyle: .largeTitle)
        case .h1:
            Spec(fontName: FontName.geistBold, size: 30, lineHeight: 34, tracking: -0.9,
                 fallbackWeight: .bold, isMonospaced: false, dynamicTypeStyle: .title1)
        case .h2:
            Spec(fontName: FontName.geistBold, size: 22, lineHeight: 26, tracking: -0.44,
                 fallbackWeight: .bold, isMonospaced: false, dynamicTypeStyle: .title2)
        case .headline:
            Spec(fontName: FontName.geistSemiBold, size: 16, lineHeight: 22, tracking: -0.16,
                 fallbackWeight: .semibold, isMonospaced: false, dynamicTypeStyle: .headline)
        case .body:
            Spec(fontName: FontName.geistRegular, size: 15, lineHeight: 22, tracking: -0.075,
                 fallbackWeight: .regular, isMonospaced: false, dynamicTypeStyle: .body)
        case .bodyStrong:
            Spec(fontName: FontName.geistSemiBold, size: 15, lineHeight: 22, tracking: -0.075,
                 fallbackWeight: .semibold, isMonospaced: false, dynamicTypeStyle: .body)
        case .caption:
            Spec(fontName: FontName.geistRegular, size: 13, lineHeight: 18, tracking: 0,
                 fallbackWeight: .regular, isMonospaced: false, dynamicTypeStyle: .footnote)
        case .label:
            Spec(fontName: FontName.geistSemiBold, size: 13, lineHeight: 18, tracking: 0,
                 fallbackWeight: .semibold, isMonospaced: false, dynamicTypeStyle: .subheadline)
        case .meta:
            Spec(fontName: FontName.geistMonoMedium, size: 11, lineHeight: 14, tracking: 0.22,
                 fallbackWeight: .medium, isMonospaced: true, dynamicTypeStyle: .caption2)
        }
    }

    /// Whether the style renders its text in uppercase (Figma text-case).
    var isUppercased: Bool { self == .meta }

    /// The Dynamic Type–scaled font for this style.
    func font(compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        let spec = spec
        let base = UIFont(name: spec.fontName, size: spec.size) ?? (
            spec.isMonospaced
                ? .monospacedSystemFont(ofSize: spec.size, weight: spec.fallbackWeight)
                : .systemFont(ofSize: spec.size, weight: spec.fallbackWeight)
        )
        return UIFontMetrics(forTextStyle: spec.dynamicTypeStyle).scaledFont(for: base, compatibleWith: traits)
    }

    /// Text attributes reproducing the Figma style (font, line height, tracking).
    func attributes(
        color: UIColor,
        alignment: NSTextAlignment = .natural,
        lineBreakMode: NSLineBreakMode = .byWordWrapping,
        compatibleWith traits: UITraitCollection? = nil
    ) -> [NSAttributedString.Key: Any] {
        let spec = spec
        let font = font(compatibleWith: traits)
        let scale = font.pointSize / spec.size
        let lineHeight = (spec.lineHeight * scale).rounded()

        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        paragraph.alignment = alignment
        paragraph.lineBreakMode = lineBreakMode

        return [
            .font: font,
            .foregroundColor: color,
            .kern: spec.tracking * scale,
            .paragraphStyle: paragraph,
            // Vertically centres glyphs inside the fixed line height.
            .baselineOffset: (lineHeight - font.lineHeight) / 4,
        ]
    }

    /// Attributes for editable text (`UITextField`), which must not carry
    /// paragraph or baseline adjustments.
    func inputAttributes(color: UIColor, compatibleWith traits: UITraitCollection? = nil) -> [NSAttributedString.Key: Any] {
        let font = font(compatibleWith: traits)
        return [
            .font: font,
            .foregroundColor: color,
            .kern: spec.tracking * (font.pointSize / spec.size),
        ]
    }

    /// Builds an attributed string in this style.
    func attributedString(
        _ string: String,
        color: UIColor,
        alignment: NSTextAlignment = .natural,
        lineBreakMode: NSLineBreakMode = .byWordWrapping,
        compatibleWith traits: UITraitCollection? = nil
    ) -> NSAttributedString {
        let text = isUppercased ? string.localizedUppercase : string
        return NSAttributedString(
            string: text,
            attributes: attributes(color: color, alignment: alignment, lineBreakMode: lineBreakMode, compatibleWith: traits)
        )
    }
}

/// PostScript names of the bundled fonts (see `UIAppFonts` in Info.plist).
private enum FontName {
    static let geistRegular = "Geist-Regular"
    static let geistSemiBold = "Geist-SemiBold"
    static let geistBold = "Geist-Bold"
    static let geistExtraBold = "Geist-ExtraBold"
    static let geistMonoMedium = "GeistMono-Medium"
}
