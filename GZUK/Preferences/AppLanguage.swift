import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case korean  = "ko"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .korean:  return "한국어"
        case .english: return "English"
        }
    }

    /// First-launch default — match the user's system language if it's Korean,
    /// otherwise English.
    static var defaultForSystem: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("ko") ? .korean : .english
    }
}

/// Tiny localization helper. Pick the appropriate string based on the
/// currently-selected app language. Intentionally not using
/// NSLocalizedString/.strings so we can hot-swap language at runtime
/// from the Settings UI without restarting.
enum L {
    /// Returns the Korean string when language is `.korean`, otherwise English.
    static func t(_ ko: String, _ en: String) -> String {
        PreferencesStore.shared.language == .korean ? ko : en
    }
}
