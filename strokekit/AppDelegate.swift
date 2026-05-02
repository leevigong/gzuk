import Cocoa
import Observation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = DrawingStore()
    private var statusItemController: StatusItemController?
    private var hotkeyManager: HotkeyManager?
    private var overlayController: OverlayWindowController?
    private var toolbarController: ToolbarWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController { [weak self] in
            self?.store.toggle()
        }

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
