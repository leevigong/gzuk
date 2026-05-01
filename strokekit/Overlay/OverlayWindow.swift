import AppKit

final class OverlayWindow: NSWindow {
    init(screenFrame: CGRect) {
        super.init(contentRect: screenFrame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,
                                   .stationary, .ignoresCycle]
        self.isReleasedWhenClosed = false
    }

    // Borderless windows must override these to accept key events (for ⌘Z, ⌘Q etc.)
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
