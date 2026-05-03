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
            self?.store.toggle()
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
    }

    /// Install a local key-down monitor so canvas shortcuts (⌘Z, tool letters,
    /// ⌘,) work no matter which app window currently holds key status —
    /// otherwise clicking the toolbar makes ToolbarWindow key and the canvas
    /// stops receiving keyDown.
    private func installKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // Only act while drawing mode is on.
            guard self.store.isDrawing else { return event }
            // Don't steal keystrokes from a focused text field.
            if event.window?.firstResponder is NSText { return event }

            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let chars = event.charactersIgnoringModifiers ?? ""

            switch (chars, mods) {
            case ("z", .command):
                self.store.undo(); return nil
            case ("z", [.command, .shift]):
                self.store.redo(); return nil
            case (",", .command):
                self.store.requestSettings(); return nil
            default:
                if mods.isEmpty,
                   let ch = chars.first,
                   let tool = Tool.allCases.first(where: { $0.hotkey == ch }) {
                    self.store.setTool(tool)
                    return nil
                }
                return event
            }
        }
    }

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
                self?.overlayController?.setPassthrough(self?.store.isPassthrough ?? false)
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

    private func handleIsDrawingChanged() {
        if store.isDrawing {
            overlayController?.show()
            toolbarController?.show()
        } else {
            overlayController?.hide()
            toolbarController?.hide()
        }
    }
}
