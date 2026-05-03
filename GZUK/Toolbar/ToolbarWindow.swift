import AppKit

/// Floating toolbar window. Use a regular NSWindow (not NSPanel) because
/// NSPanel's nonactivating behavior was preventing SwiftUI buttons from
/// receiving clicks above the OverlayWindow on macOS 26.x.
final class ToolbarWindow: NSWindow {
    init(contentSize: CGSize) {
        super.init(contentRect: NSRect(origin: .zero, size: contentSize),
                   styleMask: [.borderless, .resizable],
                   backing: .buffered,
                   defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        // Higher than OverlayWindow's .floating (3); above .popUpMenu (101)
        // to ensure clicks land here, not on the overlay.
        self.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,
                                   .stationary, .ignoresCycle]
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.isMovable = true
        // Required for SwiftUI .help() tooltips to fire on hover.
        self.acceptsMouseMovedEvents = true
    }

    // Borderless windows must override these to accept events.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
