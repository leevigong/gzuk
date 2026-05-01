import Cocoa
import Observation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = DrawingStore()
    private var statusItemController: StatusItemController?
    private var hotkeyManager: HotkeyManager?
    private var overlayController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController { [weak self] in
            self?.store.toggle()
        }

        overlayController = OverlayWindowController(store: store)

        hotkeyManager = HotkeyManager()
        hotkeyManager?.register { [weak self] in
            self?.store.toggle()
        }

        observeIsDrawing()
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

    private func handleIsDrawingChanged() {
        if store.isDrawing {
            overlayController?.show()
        } else {
            overlayController?.hide()
        }
    }
}
