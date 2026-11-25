import UIKit

/// Color tokens mirrored from the Figma "v4" variable collection.
///
/// Keep names aligned with the Figma variable names so design and code stay
/// easy to cross-reference (e.g. `ink-2` → `ink2`).
enum AppColor {
    /// `ink` — primary text and icons.
    static let ink = UIColor(hex: 0x1B4332)
    /// `ink-2` — secondary / body text.
    static let ink2 = UIColor(hex: 0x4F6F62)
    /// `brand` — primary actions and active indicators.
    static let brand = UIColor(hex: 0x40916C)
    /// `ink-3` — placeholders, hints and inactive outlines.
    static let ink3 = UIColor(hex: 0x93A89D)
    /// `green` — accent text and brand mark tile.
    static let green = UIColor(hex: 0x40916C)
    /// `on-ink` — content placed on top of `brand` / `ink` fills.
    static let onInk = UIColor.white
    /// `on-ink-2` — secondary content on top of `brand` fills.
    static let onInk2 = UIColor(hex: 0xD8F3DC)
    /// `green-soft` — soft highlight surfaces (green-window card, positive trend tags).
    static let greenSoft = UIColor(hex: 0x95D5B2)
    /// `orange` — high-CO₂ hours and destructive actions.
    static let orange = UIColor(hex: 0xE76F51)
    /// `lime` — highlight tags (e.g. "Personalises").
    static let lime = UIColor(hex: 0xFFCB42)
    /// `card` — elevated surfaces such as pills and cards.
    static let card = UIColor.white
    /// `bg` — screen background.
    static let background = UIColor.white
    /// `line` — dividers and inactive indicators.
    static let line = UIColor(hex: 0xEDE3CB)
    /// Neutral fill shown behind illustrations while they load.
    static let illustrationBackground = UIColor(hex: 0xF4F4F2)
}

extension UIColor {
    /// Creates a color from a 24-bit RGB hex value, e.g. `0x40916C`.
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
