import AppKit
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show() {
        // LSUIElement apps don't reliably bring up a regular NSWindow until
        // the activation policy is .regular. Switch on the way in, present
        // the window, then immediately switch back to .accessory so macOS
        // doesn't paint the menubar status item with the "active app"
        // highlighted background.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let win = window {
            win.title = currentTitle
            win.makeKeyAndOrderFront(nil)
            win.orderFrontRegardless()
            DispatchQueue.main.async { NSApp.setActivationPolicy(.accessory) }
            return
        }
        let host = NSHostingController(rootView: SettingsView())
        let win = NSWindow(contentViewController: host)
        win.title = currentTitle
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.delegate = self
        // Sit above the overlay so Settings is reachable while drawing, but
        // below the toolbar so the toolbar isn't hidden behind it.
        win.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        // Follow the user across Spaces — without this, Settings stays on the
        // desktop where it was first created, and opening it from another
        // desktop yanks the user back to that one. `.moveToActiveSpace` makes
        // each `orderFront` bring the window to the current space.
        win.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        win.center()
        win.makeKeyAndOrderFront(nil)
        win.orderFrontRegardless()
        self.window = win

        observeLanguage()
        DispatchQueue.main.async { NSApp.setActivationPolicy(.accessory) }
    }

    private var currentTitle: String {
        L.t("그려적어 설정", "GZUK Settings")
    }

    /// Keep the native window title in sync with the language toggle so
    /// flipping ko ⇆ en updates the chrome immediately.
    private func observeLanguage() {
        withObservationTracking {
            _ = PreferencesStore.shared.language
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.window?.title = self?.currentTitle ?? ""
                self?.observeLanguage()
            }
        }
    }

    /// Dismiss Settings — used when the user toggles drawing on so the
    /// toolbar isn't trapped behind the Settings window.
    func close() {
        window?.close()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Restore menu-bar-only mode so we don't leave a Dock icon hanging.
        NSApp.setActivationPolicy(.accessory)
    }
}
