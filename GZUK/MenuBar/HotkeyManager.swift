import HotKey
import AppKit

final class HotkeyManager {
    private var hotkey: HotKey?

    /// Registers ⌘⇧⌥7 and calls `onTrigger` when it fires.
    func register(onTrigger: @escaping () -> Void) {
        hotkey = HotKey(key: .seven, modifiers: [.command, .shift, .option])
        hotkey?.keyDownHandler = {
            onTrigger()
        }
    }

    func unregister() {
        hotkey = nil
    }
}
