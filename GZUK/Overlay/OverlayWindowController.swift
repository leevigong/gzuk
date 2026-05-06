import AppKit

final class OverlayWindowController {
    private let store: DrawingStore
    /// One overlay window per physical display, all sharing the same store
    /// so a single canvas spans every monitor — strokes drawn on any screen
    /// commit to the same shape list and render across all of them.
    private var windows: [CGDirectDisplayID: OverlayWindow] = [:]
    private var screenChangeObserver: NSObjectProtocol?

    init(store: DrawingStore) {
        self.store = store
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }

    deinit {
        if let obs = screenChangeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    /// Spawn one overlay per connected screen. The cursor's screen gets
    /// keyed so keyboard shortcuts (⌘Z, tool letters, ⌘,) route there;
    /// clicks on any other monitor's overlay still work via
    /// `acceptsFirstMouse` and naturally promote that window to key.
    func show() {
        guard windows.isEmpty else { return }
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            NSLog("GZUK: no screens available; aborting overlay")
            return
        }

        for screen in screens {
            spawnWindow(on: screen)
        }

        NSApp.activate(ignoringOtherApps: true)
        keyCursorScreenWindow()
    }

    /// Toggle pass-through (cursor) mode on every overlay simultaneously so
    /// behavior is uniform across monitors.
    func setPassthrough(_ on: Bool) {
        for win in windows.values {
            win.ignoresMouseEvents = on
        }
    }

    /// Bring our app to the foreground and re-key the cursor's screen window
    /// so the local key monitor and canvas keystrokes resume.
    func reclaimFocus() {
        guard !windows.isEmpty else { return }
        NSApp.activate(ignoringOtherApps: true)
        keyCursorScreenWindow()
    }

    func hide() {
        for win in windows.values {
            win.orderOut(nil)
        }
        windows.removeAll()
        // Note: store.shapes is preserved — restored on next show()
    }

    /// Reconcile overlay windows with the currently connected displays:
    /// resize windows that stayed, drop windows for displays that left,
    /// and spawn windows for displays that just appeared. Keeps the
    /// common one-monitor-change case flicker-free instead of tearing
    /// down every window.
    private func handleScreenChange() {
        guard !windows.isEmpty else { return }
        let currentIDs = Set(NSScreen.screens.map { $0.displayID })
        for id in Array(windows.keys) where !currentIDs.contains(id) {
            windows[id]?.orderOut(nil)
            windows.removeValue(forKey: id)
        }
        for screen in NSScreen.screens {
            let id = screen.displayID
            if let win = windows[id] {
                win.setFrame(Self.overlayFrame(on: screen), display: true)
            } else {
                spawnWindow(on: screen)
            }
        }
        if windows.isEmpty {
            return
        }
        if !windows.values.contains(where: { $0.isKeyWindow }) {
            keyCursorScreenWindow()
        }
    }

    private func spawnWindow(on screen: NSScreen) {
        let frame = Self.overlayFrame(on: screen)
        let win = OverlayWindow(screenFrame: frame)
        let canvas = DrawingCanvasView(
            store: store,
            frame: CGRect(origin: .zero, size: frame.size))
        canvas.autoresizingMask = [.width, .height]
        win.contentView = canvas
        win.makeFirstResponder(canvas)
        win.ignoresMouseEvents = store.isPassthrough
        win.orderFront(nil)
        windows[screen.displayID] = win
    }

    private func keyCursorScreenWindow() {
        if let cursorScreen = ScreenManager.screenWithCursor(),
           let win = windows[cursorScreen.displayID] {
            win.makeKeyAndOrderFront(nil)
        } else {
            windows.values.first?.makeKeyAndOrderFront(nil)
        }
    }

    /// Cover the screen but exclude the menu bar so whiteboard fill and
    /// clicks don't sit on top of system menus. The Dock area is kept
    /// inside the frame because users may want to draw down there. On
    /// secondary displays without a menu bar, `menuBarHeight` is 0 so
    /// the window covers the full screen.
    private static func overlayFrame(on screen: NSScreen) -> CGRect {
        let full = screen.frame
        let menuBarHeight = full.maxY - screen.visibleFrame.maxY
        return CGRect(x: full.minX, y: full.minY,
                      width: full.width,
                      height: full.height - menuBarHeight)
    }
}
