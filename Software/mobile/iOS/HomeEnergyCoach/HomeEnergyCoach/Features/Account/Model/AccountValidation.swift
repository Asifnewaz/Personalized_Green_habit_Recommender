import Foundation

/// Lightweight client-side checks for account forms. The server remains the source of truth.
enum EmailValidator {
    static func isValid(_ email: String) -> Bool {
        let pattern = #/[^@\s]+@[^@\s]+\.[^@\s]{2,}/#
        return email.trimmingCharacters(in: .whitespaces).wholeMatch(of: pattern) != nil
    }
}

/// Password strength shown under the Create-account password field (4-segment meter).
enum PasswordStrength: Int, Comparable, CaseIterable {
    case empty
    case weak
    case fair
    case strong
    case veryStrong

    /// Minimum length required to create an account.
    static let minimumLength = 8

    static func evaluate(_ password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .empty }
        var score = 0
        if password.count >= minimumLength { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.contains(where: \.isLowercase), password.contains(where: \.isUppercase) { score += 1 }
        if password.contains(where: { $0.isNumber || !($0.isLetter || $0.isNumber) }) { score += 1 }
        return PasswordStrength(rawValue: max(1, score)) ?? .weak
    }

    /// Number of filled meter segments (0–4).
    var filledSegments: Int { rawValue }

    var title: String {
        switch self {
        case .empty: ""
        case .weak: String(localized: "Weak", comment: "Password strength")
        case .fair: String(localized: "Fair", comment: "Password strength")
        case .strong: String(localized: "Strong", comment: "Password strength")
        case .veryStrong: String(localized: "Very strong", comment: "Password strength")
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
