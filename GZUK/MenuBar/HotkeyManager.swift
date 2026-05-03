import HotKey
import AppKit

final class HotkeyManager {
    private var hotkey: HotKey?

    /// Registers ⌃G and calls `onTrigger` when it fires.
    func register(onTrigger: @escaping () -> Void) {
        hotkey = HotKey(key: .g, modifiers: [.control])
        hotkey?.keyDownHandler = {
            onTrigger()
        }
    }

    func unregister() {
        hotkey = nil
    }
}
