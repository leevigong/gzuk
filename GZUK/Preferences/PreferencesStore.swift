import AppKit
import Observation
import ServiceManagement

@Observable
final class PreferencesStore {
    static let shared = PreferencesStore()

    private(set) var launchAtLogin: Bool
    private(set) var toolbarOpacity: Double
    private(set) var language: AppLanguage

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let launchAtLogin = "GZUK.launchAtLogin"
        static let toolbarOpacity = "GZUK.toolbarOpacity"
        static let language = "GZUK.language"
    }

    private init() {
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        let stored = defaults.object(forKey: Keys.toolbarOpacity) as? Double
        self.toolbarOpacity = stored ?? 1.0
        let raw = defaults.string(forKey: Keys.language) ?? AppLanguage.defaultForSystem.rawValue
        self.language = AppLanguage(rawValue: raw) ?? .korean
        // Re-sync OS state in case user toggled it via System Settings.
        if SMAppService.mainApp.status == .enabled {
            self.launchAtLogin = true
        }
    }

    func setLaunchAtLogin(_ value: Bool) {
        launchAtLogin = value
        defaults.set(value, forKey: Keys.launchAtLogin)
        do {
            if value {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("GZUK: launch-at-login change failed: \(error)")
        }
    }

    func setToolbarOpacity(_ value: Double) {
        let clamped = min(max(value, 0.3), 1.0)
        toolbarOpacity = clamped
        defaults.set(clamped, forKey: Keys.toolbarOpacity)
    }

    func setLanguage(_ value: AppLanguage) {
        language = value
        defaults.set(value.rawValue, forKey: Keys.language)
    }
}
