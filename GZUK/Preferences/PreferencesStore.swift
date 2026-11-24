import AppKit
import Observation
import ServiceManagement

@Observable
final class PreferencesStore {
    static let shared = PreferencesStore()

    private(set) var launchAtLogin: Bool
    private(set) var toolbarOpacity: Double
    private(set) var language: AppLanguage
    /// Leave marks on screen (click-through) after ⌥G turns drawing off,
    /// instead of hiding them until the next session.
    private(set) var keepDrawingsOnExit: Bool
    private(set) var outlineEnabled: Bool
    private(set) var outlineColor: NSColor

    /// Pen color / width from the last session, restored at launch so marks
    /// don't snap back to red 4pt after every relaunch or update. nil until
    /// the user has changed them once.
    private(set) var drawingColor: NSColor?
    private(set) var drawingLineWidth: CGFloat?
    /// The rainbow swatch's color: last custom color drawn with. The rest of
    /// the history lives in the "그려적어" color palette (ColorListStore).
    private(set) var customColor: NSColor?

    /// The border new shapes get, or nil when the option is off.
    var activeOutlineColor: NSColor? { outlineEnabled ? outlineColor : nil }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let launchAtLogin = "GZUK.launchAtLogin"
        static let toolbarOpacity = "GZUK.toolbarOpacity"
        static let language = "GZUK.language"
        static let keepDrawingsOnExit = "GZUK.keepDrawingsOnExit"
        static let outlineEnabled = "GZUK.outlineEnabled"
        static let outlineColor = "GZUK.outlineColor"
        static let drawingColor = "GZUK.drawingColor"
        static let drawingLineWidth = "GZUK.drawingLineWidth"
        static let customColor = "GZUK.customColor"
    }

    private init() {
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        let stored = defaults.object(forKey: Keys.toolbarOpacity) as? Double
        self.toolbarOpacity = stored ?? 1.0
        let raw = defaults.string(forKey: Keys.language) ?? AppLanguage.defaultForSystem.rawValue
        self.language = AppLanguage(rawValue: raw) ?? .korean
        self.keepDrawingsOnExit = defaults.bool(forKey: Keys.keepDrawingsOnExit)
        self.outlineEnabled = defaults.bool(forKey: Keys.outlineEnabled)
        self.outlineColor = Self.loadColor(defaults, Keys.outlineColor) ?? .white
        self.drawingColor = Self.loadColor(defaults, Keys.drawingColor)
        self.customColor = Self.loadColor(defaults, Keys.customColor)
        let width = defaults.double(forKey: Keys.drawingLineWidth)
        self.drawingLineWidth = width > 0 ? CGFloat(width) : nil
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

    func setKeepDrawingsOnExit(_ value: Bool) {
        keepDrawingsOnExit = value
        defaults.set(value, forKey: Keys.keepDrawingsOnExit)
    }

    func setOutlineEnabled(_ value: Bool) {
        outlineEnabled = value
        defaults.set(value, forKey: Keys.outlineEnabled)
    }

    func setOutlineColor(_ value: NSColor) {
        outlineColor = saveColor(value, Keys.outlineColor)
    }

    func setDrawingColor(_ value: NSColor) {
        drawingColor = saveColor(value, Keys.drawingColor)
    }

    func setDrawingLineWidth(_ value: CGFloat) {
        drawingLineWidth = value
        defaults.set(Double(value), forKey: Keys.drawingLineWidth)
    }

    /// Feed every committed shape's color through the history; writes only
    /// what actually changed (most strokes are presets / repeats).
    func recordColorUse(_ color: NSColor, presets: [NSColor]) {
        var history = CustomColorHistory(current: customColor,
                                         saved: ColorListStore.load())
        let changed = history.recordUse(of: color, presets: presets)
        if changed.current, let current = history.current {
            customColor = saveColor(current, Keys.customColor)
        }
        if changed.saved {
            ColorListStore.save(history.saved)
        }
    }

    /// Store as sRGB components so the value round-trips; catalog or pattern
    /// colors from the picker have no RGB components of their own.
    private func saveColor(_ value: NSColor, _ key: String) -> NSColor {
        let rgb = value.usingColorSpace(.sRGB) ?? .white
        defaults.set(Self.rgba(rgb), forKey: key)
        return rgb
    }

    private static func rgba(_ color: NSColor) -> [Double] {
        let rgb = color.usingColorSpace(.sRGB) ?? .white
        return [rgb.redComponent, rgb.greenComponent,
                rgb.blueComponent, rgb.alphaComponent].map(Double.init)
    }

    private static func loadColor(_ defaults: UserDefaults, _ key: String) -> NSColor? {
        (defaults.array(forKey: key) as? [Double]).flatMap(color(fromRGBA:))
    }

    private static func color(fromRGBA c: [Double]) -> NSColor? {
        guard c.count == 4 else { return nil }
        return NSColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: c[3])
    }
}
