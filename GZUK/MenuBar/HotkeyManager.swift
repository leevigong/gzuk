import AppKit
import HotKey

/// Global hotkeys via Carbon RegisterEventHotKey (no Accessibility
/// permission required):
/// - ⌥G toggles drawing mode.
/// - ⌥V turns drawing on only while held (Carbon reports the release too).
final class HotkeyManager {
    private var toggleHotkey: HotKey?
    private var holdHotkey: HotKey?

    func register(onToggle: @escaping () -> Void,
                  onHoldBegan: @escaping () -> Void,
                  onHoldEnded: @escaping () -> Void) {
        toggleHotkey = HotKey(key: .g, modifiers: [.option])
        toggleHotkey?.keyDownHandler = onToggle

        holdHotkey = HotKey(key: .v, modifiers: [.option])
        holdHotkey?.keyDownHandler = onHoldBegan
        holdHotkey?.keyUpHandler = onHoldEnded
    }

    func unregister() {
        toggleHotkey = nil
        holdHotkey = nil
    }
}
