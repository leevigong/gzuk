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
        // Sit at the same level as the Settings window (both .floating + 1)
        // so whichever was clicked most recently floats to the top — Settings
        // doesn't trap the toolbar, and bringing Settings forward doesn't
        // trap Settings behind the toolbar. Still ABOVE OverlayWindow
        // (.floating = 3) and BELOW .popUpMenu (101) so menubar popups win.
        self.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,
                                   .stationary, .ignoresCycle]
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.isMovable = true
        // Required for SwiftUI .help() tooltips to fire on hover.
        self.acceptsMouseMovedEvents = true

        // Keep the level in sync with where the user parks the toolbar.
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification, object: self, queue: .main
        ) { [weak self] _ in
            self?.updateLevelForMenuBarOverlap()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Set once the user drags the toolbar (or a dragged position is restored
    /// from a previous session). Tells the controller not to yank it back
    /// under the menubar icon on collapse/expand.
    var userHasRepositioned = false

    /// Default level: above the overlay, below menubar popups, and at the
    /// same level as Settings so neither traps the other.
    private static let restingLevel =
        NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
    /// Above `.mainMenu` (24) so a toolbar parked in the menubar strip is
    /// actually visible, still below `.popUpMenu` (101) so open menus win.
    private static let aboveMenuBarLevel = NSWindow.Level.statusBar

    /// AppKit's default pins a dragged window's top edge below the menu bar.
    /// Return the rect untouched so the toolbar can be parked over the
    /// menubar. The window can't be lost off-screen this way: `performDrag`
    /// keeps the grabbed point under the cursor, which stays on a display.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    /// Only float above the menu bar while the toolbar actually overlaps it.
    /// Staying at `.statusBar` permanently would cover other apps' menus even
    /// when the toolbar sits nowhere near them.
    func updateLevelForMenuBarOverlap() {
        guard let screen = screen ?? NSScreen.main else { return }
        let stripHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let strip = NSRect(x: screen.frame.minX, y: screen.visibleFrame.maxY,
                           width: screen.frame.width, height: stripHeight)
        let target = (stripHeight > 0 && frame.intersects(strip))
            ? Self.aboveMenuBarLevel
            : Self.restingLevel
        if level != target { level = target }
    }

    // Borderless windows must override these to accept events.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
