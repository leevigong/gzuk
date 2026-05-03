import AppKit

final class OverlayWindowController {
    private let store: DrawingStore
    private var window: OverlayWindow?
    private var canvas: DrawingCanvasView?
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

    func show() {
        guard window == nil else { return }
        guard let screen = ScreenManager.screenWithCursor() else {
            NSLog("GZUK: no screen contains cursor; aborting overlay")
            return
        }

        // Exclude the menu bar so whiteboard fill and clicks don't cover it.
        // We keep the Dock area (only trim the top), since users may want to
        // draw down there.
        let full = screen.frame
        let menuBarHeight = full.maxY - screen.visibleFrame.maxY
        let overlayFrame = CGRect(x: full.minX, y: full.minY,
                                  width: full.width,
                                  height: full.height - menuBarHeight)

        let win = OverlayWindow(screenFrame: overlayFrame)
        let canvas = DrawingCanvasView(store: store,
                                       frame: CGRect(origin: .zero, size: overlayFrame.size))
        canvas.autoresizingMask = [.width, .height]
        win.contentView = canvas
        win.makeFirstResponder(canvas)

        // Bring the app to the foreground so the overlay actually receives
        // keystrokes — otherwise the previously-active app keeps the focus
        // and tool shortcuts go to it instead of our local monitor.
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        win.ignoresMouseEvents = store.isPassthrough

        self.window = win
        self.canvas = canvas
    }

    /// Toggle whether the overlay window passes mouse events through to apps below.
    func setPassthrough(_ on: Bool) {
        window?.ignoresMouseEvents = on
    }

    /// Bring our app to the foreground and make the overlay key so the
    /// local key monitor receives keystrokes again. Used when the user
    /// presses ⌃G while drawing mode is already on but another app stole
    /// focus (cursor passthrough).
    func reclaimFocus() {
        guard let win = window else { return }
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        canvas = nil
        // Note: store.shapes is preserved — restored on next show()
    }

    /// Re-anchor the overlay when monitors are connected/disconnected or
    /// resolutions change. Picks the screen with the cursor; if none, falls
    /// back to the main screen so we never leave the window stranded on a
    /// disconnected display.
    private func handleScreenChange() {
        guard let win = window else { return }
        let screen = ScreenManager.screenWithCursor()
                  ?? NSScreen.main
                  ?? NSScreen.screens.first
        guard let screen else {
            hide()
            return
        }
        let full = screen.frame
        let menuBarHeight = full.maxY - screen.visibleFrame.maxY
        let newFrame = CGRect(x: full.minX, y: full.minY,
                              width: full.width,
                              height: full.height - menuBarHeight)
        win.setFrame(newFrame, display: true)
    }
}
