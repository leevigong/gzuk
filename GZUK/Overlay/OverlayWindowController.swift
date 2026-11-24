import AppKit

final class OverlayWindowController {
    private let store: DrawingStore
    /// One overlay window per physical display, all sharing the same store
    /// so a single canvas spans every monitor — strokes drawn on any screen
    /// commit to the same shape list and render across all of them.
    private var windows: [CGDirectDisplayID: OverlayWindow] = [:]
    private var screenChangeObserver: NSObjectProtocol?
    /// Whoever was frontmost right before we stole activation. GZUK is an
    /// LSUIElement app, so ordering our overlays out doesn't hand focus back
    /// on its own — without this the user has to click their window before
    /// typing again.
    private var previousApp: NSRunningApplication?
    /// False while the overlays are only displaying marks after drawing mode
    /// ended (`hide(keepVisible: true)`): every window then ignores the mouse
    /// so clicks reach the user's app, and nothing may take key status.
    private var isInteractive = false

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
        if windows.isEmpty {
            let screens = NSScreen.screens
            guard !screens.isEmpty else {
                NSLog("GZUK: no screens available; aborting overlay")
                return
            }
            for screen in screens {
                spawnWindow(on: screen)
            }
        }

        // Either freshly spawned, or left on screen as a click-through
        // display by `hide(keepVisible: true)` — make them drawable again.
        isInteractive = true
        for win in windows.values {
            win.ignoresMouseEvents = store.isPassthrough
        }
        rememberFrontmostApp()
        NSApp.activate(ignoringOtherApps: true)
        keyCursorScreenWindow()
    }

    /// Toggle pass-through (cursor) mode on every overlay simultaneously so
    /// behavior is uniform across monitors.
    func setPassthrough(_ on: Bool) {
        guard isInteractive else { return }
        for win in windows.values {
            win.ignoresMouseEvents = on
        }
    }

    /// Bring our app to the foreground and re-key the cursor's screen window
    /// so the local key monitor and canvas keystrokes resume. Used when the
    /// user fires the global toggle hotkey while drawing is already on but
    /// another app stole focus (cursor passthrough).
    func reclaimFocus() {
        guard isInteractive, !windows.isEmpty else { return }
        // The app we're taking focus from now is the one to give it back to
        // on exit — not whoever was frontmost when the session started.
        rememberFrontmostApp()
        NSApp.activate(ignoringOtherApps: true)
        keyCursorScreenWindow()
    }

    /// End the drawing session. With `keepVisible` the marks stay on screen
    /// as a click-through layer (nothing to show → windows go away as usual);
    /// otherwise the overlays are removed. Either way store.shapes is kept and
    /// comes back on the next show().
    func hide(keepVisible: Bool = false) {
        isInteractive = false
        if keepVisible && !store.shapes.isEmpty {
            for win in windows.values {
                win.ignoresMouseEvents = true
            }
        } else {
            removeWindows()
        }
        restorePreviousApp()
    }

    /// Drop a click-through display left by `hide(keepVisible: true)` — e.g.
    /// when the user turns the setting off. No-op during a drawing session.
    func removeLingeringMarks() {
        guard !isInteractive else { return }
        removeWindows()
    }

    private func removeWindows() {
        for win in windows.values {
            win.orderOut(nil)
        }
        windows.removeAll()
    }

    private func rememberFrontmostApp() {
        guard let front = NSWorkspace.shared.frontmostApplication,
              front.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return }
        previousApp = front
    }

    /// Hand activation back to the app the user was working in. Skipped when
    /// we aren't the active app anyway (the user already moved on — pulling
    /// focus to a third app would be worse than doing nothing).
    private func restorePreviousApp() {
        let app = previousApp
        previousApp = nil
        guard NSApp.isActive else { return }
        // Settings is still on screen (the toolbar can't become main, and
        // overlays — even ones left showing marks — don't count). Pushing it
        // behind the user's app would be worse.
        guard !NSApp.windows.contains(where: {
            $0.isVisible && $0.canBecomeMain && !($0 is OverlayWindow)
        }) else { return }
        if let app, !app.isTerminated {
            app.activate()
        } else {
            // No target left (quit in the meantime) — at least step aside so
            // we're not holding activation with nothing on screen.
            NSApp.hide(nil)
        }
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
        if isInteractive, !windows.values.contains(where: { $0.isKeyWindow }) {
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
        win.ignoresMouseEvents = isInteractive ? store.isPassthrough : true
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
