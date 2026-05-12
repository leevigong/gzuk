import AppKit
import HotKey

/// Registers ⌥G as a global hotkey via Carbon RegisterEventHotKey (no
/// Accessibility permission required).
final class HotkeyManager {
    private var hotkey: HotKey?

    func register(onTrigger: @escaping () -> Void) {
        hotkey = HotKey(key: .g, modifiers: [.option])
        hotkey?.keyDownHandler = onTrigger
    }

    func unregister() {
        hotkey = nil
    }
}
