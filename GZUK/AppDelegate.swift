import Cocoa
import CoreText
import Observation
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
    private let store = DrawingStore(outlineColor: {
        PreferencesStore.shared.activeOutlineColor
    })
    private let settingsController = SettingsWindowController()
    private var statusItemController: StatusItemController?
    private var hotkeyManager: HotkeyManager?
    private var overlayController: OverlayWindowController?
    private var toolbarController: ToolbarWindowController?
    private var keyMonitor: Any?
    private var flagsMonitor: Any?
    /// True while drawing mode is on only because ⌥V is held down; releasing
    /// it ends the session. A session started any other way is never ended
    /// by ⌥V.
    private var isHoldSession = false
    private var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerBundledFonts()

        // Sparkle: feed URL + EdDSA public key live in Info.plist. We use
        // EdDSA verification (not Developer ID) because the app is ad-hoc
        // signed. Auto-check fires on schedule; users can also pull-check
        // from the menubar item.
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        // Check ~3s after launch. Background (not `checkForUpdateInformation`)
        // so a waiting update actually surfaces: the silent variant only lit
        // the menubar badge, which nobody sees until they right-click, and the
        // scheduled check is 24h away. This variant stays quiet when there's
        // nothing new and honours a skipped version, so it can't nag.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.updaterController?.updater.checkForUpdatesInBackground()
        }

        statusItemController = StatusItemController(
            onToggle: { [weak self] in
                guard let self else { return }
                // Clicking the menubar icon to TURN ON drawing means
                // "start here" — discard any saved drag position so the
                // toolbar lands on the cursor's monitor. ⌃G doesn't take
                // this path, so its stored-position behavior is preserved.
                if !self.store.isDrawing {
                    ToolbarPositionStore.clear()
                }
                self.store.toggle()
            },
            onSettings: { [weak self] in self?.settingsController.show() },
            onCheckForUpdates: { [weak self] in
                self?.updaterController?.checkForUpdates(nil)
            })

        overlayController = OverlayWindowController(store: store)
        toolbarController = ToolbarWindowController(store: store) { [weak self] in
            self?.statusItemController?.buttonFrameOnScreen
        }

        hotkeyManager = HotkeyManager()
        hotkeyManager?.register(onToggle: { [weak self] in
            guard let self else { return }
            // If drawing mode is already on but we lost focus to another
            // app (gray dot state), pull focus back instead of toggling
            // off. The toolbar STAYS where the session started — moving
            // it on every reclaim would jerk the UI around when the user
            // is just briefly visiting another monitor.
            if self.store.isDrawing && !NSApp.isActive {
                self.overlayController?.reclaimFocus()
            } else {
                self.store.toggle()
            }
        }, onHoldBegan: { [weak self] in
            self?.beginHoldSession()
        }, onHoldEnded: { [weak self] in
            self?.endHoldSession()
        })

        restorePenSettings()
        observePenSettings()
        // Custom colors join the "그려적어" color palette once drawn with.
        store.onShapeCommitted = { [weak self] _ in
            guard let self else { return }
            PreferencesStore.shared.recordColorUse(
                self.store.currentColor, presets: ColorPaletteView.presetColors)
        }
        observeIsDrawing()
        observeKeepDrawingsOnExit()
        observeIsPassthrough()
        installKeyboardShortcuts()

        // Allow ⌘, from inside the canvas to open Settings.
        NotificationCenter.default.addObserver(
            forName: .GZUKSettingsRequested, object: nil, queue: .main
        ) { [weak self] _ in
            self?.settingsController.show()
        }

        // Launching the app means the user wants to draw — drop the user
        // straight into drawing mode so the toolbar pops up immediately.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self, !self.store.isDrawing else { return }
            self.store.toggle()
        }
    }

    /// Install a local key-down monitor so canvas shortcuts (⌘Z, tool letters,
    /// ⌘,) work no matter which app window currently holds key status —
    /// otherwise clicking the toolbar makes ToolbarWindow key and the canvas
    /// stops receiving keyDown.
    func applicationWillTerminate(_ notification: Notification) {
        for token in [keyMonitor, flagsMonitor].compactMap({ $0 }) {
            NSEvent.removeMonitor(token)
        }
        keyMonitor = nil
        flagsMonitor = nil
    }

    // MARK: - ⌥V hold-to-draw

    private func beginHoldSession() {
        // Already drawing (⌥G, menubar, or a key-repeat of this very press):
        // leave that session alone so letting go doesn't end it.
        guard !store.isDrawing else { return }
        isHoldSession = true
        store.toggle()
    }

    private func endHoldSession() {
        guard isHoldSession else { return }
        isHoldSession = false
        if store.isDrawing {
            store.toggle()
        }
    }

    // MARK: - SPUUpdaterDelegate

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        statusItemController?.setUpdateAvailable(true)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        statusItemController?.setUpdateAvailable(false)
    }

    /// Sparkle doesn't refire didFindValidUpdate after the user dismisses the
    /// alert, so clear the menubar badge here when the user explicitly opts
    /// out of this version (skip) or defers it (dismiss). Install causes the
    /// app to restart at the new version, which naturally clears the badge.
    func updater(_ updater: SPUUpdater, userDidMake choice: SPUUserUpdateChoice, forUpdate updateItem: SUAppcastItem, state: SPUUserUpdateState) {
        switch choice {
        case .skip, .dismiss:
            statusItemController?.setUpdateAvailable(false)
        case .install:
            break
        @unknown default:
            break
        }
    }

    private func installKeyboardShortcuts() {
        // Hardware keyCodes (US-QWERTY positions) used so shortcuts work
        // regardless of active input method (Korean IME etc).
        let zKey: UInt16 = 6
        let commaKey: UInt16 = 43
        let sKey: UInt16 = 1
        let wKey: UInt16 = 13
        let mKey: UInt16 = 46
        let oKey: UInt16 = 31
        let dKey: UInt16 = 2
        let deleteKey: UInt16 = 51

        // Letting go of ⌥ before V also ends a hold session — otherwise the
        // hotkey's release would only come with V, and a user who lifts ⌥
        // first would be left in drawing mode. We're the active app for the
        // whole hold, so a local monitor sees it.
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            if self?.isHoldSession == true, !event.modifierFlags.contains(.option) {
                self?.endHoldSession()
            }
            return event
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // Only act while drawing mode is on.
            guard self.store.isDrawing else { return event }
            // Don't steal keystrokes from a focused text field.
            if event.window?.firstResponder is NSText { return event }

            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let kc = event.keyCode

            switch (kc, mods) {
            // ⌥ variants sit alongside the standard ⌘ ones: while drawing,
            // the user's hand already rests on ⌥ for the other shortcuts, so
            // reaching for ⌘ breaks the ⌥D/⌥G/⌥Z cluster.
            case (zKey, .command), (zKey, .option):
                self.store.undo(); return nil
            case (zKey, [.command, .shift]), (zKey, [.option, .shift]):
                self.store.redo(); return nil
            case (commaKey, .command):
                self.store.requestSettings(); return nil
            case (sKey, []):
                self.store.togglePassthrough(); return nil
            case (wKey, []):
                self.store.toggleWhiteboard(); return nil
            case (mKey, []):
                self.store.toggleToolbarCollapsed(); return nil
            case (oKey, []):
                PreferencesStore.shared.toggleOutline(); return nil
            // ⌥D is the advertised one (same hand position as ⌥G); ⌥⌫ stays
            // for muscle memory from 1.0.3 and earlier.
            case (dKey, .option), (deleteKey, .option):
                self.store.clear(); return nil
            #if DEBUG
            case (sKey, [.control, .shift]):
                self.spawnStressShapes(count: 200); return nil
            #endif
            default:
                if mods.isEmpty,
                   let tool = Tool.allCases.first(where: { $0.keyCode == kc }) {
                    self.store.setTool(tool)
                    return nil
                }
                return event
            }
        }
    }

    #if DEBUG
    /// Stress test: spawn `count` random freehand strokes across the cursor's
    /// screen so we can measure draw() perf with many shapes. ⌃⇧S in DEBUG.
    private func spawnStressShapes(count: Int) {
        let bounds = (ScreenManager.screenWithCursor() ?? NSScreen.main)?.frame
                  ?? CGRect(x: 0, y: 0, width: 1600, height: 1000)
        let colors: [NSColor] = [.systemRed, .systemBlue, .systemGreen,
                                 .systemYellow, .systemPurple, .systemOrange]
        for _ in 0..<count {
            let originX = CGFloat.random(in: bounds.minX...bounds.maxX - 200)
            let originY = CGFloat.random(in: bounds.minY...bounds.maxY - 200)
            let pointCount = Int.random(in: 20...60)
            var pts: [CGPoint] = []
            var cursor = CGPoint(x: originX, y: originY)
            for _ in 0..<pointCount {
                cursor.x += CGFloat.random(in: -8...8)
                cursor.y += CGFloat.random(in: -8...8)
                pts.append(cursor)
            }
            store.commitShape(.freehand(points: pts,
                                        color: colors.randomElement()!,
                                        lineWidth: CGFloat.random(in: 2...6)))
        }
        NSLog("GZUK: spawned \(count) stress-test shapes (total now: \(store.shapes.count))")
    }
    #endif

    private func observeIsDrawing() {
        withObservationTracking {
            _ = store.isDrawing
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.handleIsDrawingChanged()
                self?.observeIsDrawing()
            }
        }
    }

    // MARK: - Pen color / width persistence

    private func restorePenSettings() {
        let prefs = PreferencesStore.shared
        if let color = prefs.drawingColor { store.setColor(color) }
        if let width = prefs.drawingLineWidth { store.setLineWidth(width) }
    }

    /// Save color/width as they change. Kept here rather than in DrawingStore
    /// so the store stays free of UserDefaults (tests build bare stores).
    /// The tool is deliberately not saved: starting a session on the eraser
    /// or counter would be more confusing than always starting on the pen.
    private func observePenSettings() {
        withObservationTracking {
            _ = store.currentColor
            _ = store.currentLineWidth
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                let prefs = PreferencesStore.shared
                prefs.setDrawingColor(self.store.currentColor)
                prefs.setDrawingLineWidth(self.store.currentLineWidth)
                self.observePenSettings()
            }
        }
    }

    /// Turning "keep marks after exit" off while marks are lingering should
    /// clear them off the screen right away, not at the next session.
    private func observeKeepDrawingsOnExit() {
        withObservationTracking {
            _ = PreferencesStore.shared.keepDrawingsOnExit
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                if !PreferencesStore.shared.keepDrawingsOnExit {
                    self.overlayController?.removeLingeringMarks()
                }
                self.observeKeepDrawingsOnExit()
            }
        }
    }

    private func observeIsPassthrough() {
        withObservationTracking {
            _ = store.isPassthrough
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                let on = self?.store.isPassthrough ?? false
                self?.overlayController?.setPassthrough(on)
                self?.statusItemController?.setPassthrough(on)
                self?.observeIsPassthrough()
            }
        }
    }

    private func registerBundledFonts() {
        guard let url = Bundle.main.url(forResource: "GowunDodum-Regular", withExtension: "ttf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    /// Called by macOS when the user "re-opens" the app (e.g. clicks it in
    /// Spotlight while it's already running). Drop them straight into
    /// drawing mode so the toolbar appears instead of doing nothing.
    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool {
        if !store.isDrawing {
            store.toggle()
        }
        return true
    }

    private func handleIsDrawingChanged() {
        statusItemController?.setActive(store.isDrawing)
        if store.isDrawing {
            overlayController?.show()
            toolbarController?.show()
        } else {
            // Toolbar first: it can become key, so it must be off screen
            // before the overlay hands activation back to the user's app.
            // Ended by ⌥G / menubar mid-hold: the ⌥V release that follows
            // must not count as a new toggle.
            isHoldSession = false
            toolbarController?.hide()
            overlayController?.hide(
                keepVisible: PreferencesStore.shared.keepDrawingsOnExit)
        }
    }
}
