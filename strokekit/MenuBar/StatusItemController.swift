import AppKit

final class StatusItemController {
    private let statusItem: NSStatusItem
    private let onToggle: () -> Void
    private let onSettings: () -> Void

    /// Frame of the status item button in screen coordinates (or nil if unavailable).
    var buttonFrameOnScreen: NSRect? {
        statusItem.button?.window?.frame
    }

    init(onToggle: @escaping () -> Void,
         onSettings: @escaping () -> Void) {
        self.onToggle = onToggle
        self.onSettings = onSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pencil.tip",
                                   accessibilityDescription: "strokekit")
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            onToggle()
        }
    }

    @objc private func openSettings() { onSettings() }

    private func showMenu() {
        let menu = NSMenu()
        let settings = NSMenuItem(title: "Settings…",
                                  action: #selector(openSettings),
                                  keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit strokekit",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Detach so subsequent left-clicks toggle instead of opening the menu
        statusItem.menu = nil
    }
}
