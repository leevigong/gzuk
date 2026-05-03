import AppKit
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show() {
        // LSUIElement apps don't reliably bring up a regular NSWindow until
        // the activation policy is .regular. Switch on the way in, switch
        // back when the window closes.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let win = window {
            win.makeKeyAndOrderFront(nil)
            win.orderFrontRegardless()
            return
        }
        let host = NSHostingController(rootView: SettingsView())
        let win = NSWindow(contentViewController: host)
        win.title = "그려적어 설정"
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.delegate = self
        // Comfortably above the floating toolbar (popUpMenu+1) so any SwiftUI
        // re-layout in the toolbar can't accidentally end up on top.
        win.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 10)
        win.center()
        win.makeKeyAndOrderFront(nil)
        win.orderFrontRegardless()
        self.window = win
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Restore menu-bar-only mode so we don't leave a Dock icon hanging.
        NSApp.setActivationPolicy(.accessory)
    }
}
