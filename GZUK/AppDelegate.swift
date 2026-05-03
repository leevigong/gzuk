import Cocoa
import CoreText
import Observation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = DrawingStore()
    private let settingsController = SettingsWindowController()
    private var statusItemController: StatusItemController?
    private var hotkeyManager: HotkeyManager?
    private var overlayController: OverlayWindowController?
    private var toolbarController: ToolbarWindowController?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerBundledFonts()

        statusItemController = StatusItemController(
            onToggle: { [weak self] in self?.store.toggle() },
            onSettings: { [weak self] in self?.settingsController.show() })

        overlayController = OverlayWindowController(store: store)
        toolbarController = ToolbarWindowController(store: store) { [weak self] in
            self?.statusItemController?.buttonFrameOnScreen
        }

        hotkeyManager = HotkeyManager()
        hotkeyManager?.register { [weak self] in
            guard let self else { return }
            // If drawing mode is already on but we lost focus to another app
            // (gray dot state), pull focus back instead of toggling off.
            // Otherwise behave as a normal toggle.
            if self.store.isDrawing && !NSApp.isActive {
                self.overlayController?.reclaimFocus()
            } else {
                self.store.toggle()
            }
        }

        observeIsDrawing()
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
        if let token = keyMonitor {
            NSEvent.removeMonitor(token)
            keyMonitor = nil
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
        let deleteKey: UInt16 = 51

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // Only act while drawing mode is on.
            guard self.store.isDrawing else { return event }
            // Don't steal keystrokes from a focused text field.
            if event.window?.firstResponder is NSText { return event }

            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let kc = event.keyCode

            switch (kc, mods) {
            case (zKey, .command):
                self.store.undo(); return nil
            case (zKey, [.command, .shift]):
                self.store.redo(); return nil
            case (commaKey, .command):
                self.store.requestSettings(); return nil
            case (sKey, []):
                self.store.togglePassthrough(); return nil
            case (wKey, []):
                self.store.toggleWhiteboard(); return nil
            case (mKey, []):
                self.store.toggleToolbarCollapsed(); return nil
            case (deleteKey, .command):
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
            overlayController?.hide()
            toolbarController?.hide()
        }
    }
}
