import AppKit

final class OverlayWindowController {
    private let store: DrawingStore
    private var window: OverlayWindow?
    private var canvas: DrawingCanvasView?

    init(store: DrawingStore) {
        self.store = store
    }

    func show() {
        guard window == nil else { return }
        guard let screen = ScreenManager.screenWithCursor() else {
            NSLog("strokekit: no screen contains cursor; aborting overlay")
            return
        }

        let win = OverlayWindow(screenFrame: screen.frame)
        let canvas = DrawingCanvasView(store: store,
                                       frame: CGRect(origin: .zero, size: screen.frame.size))
        canvas.autoresizingMask = [.width, .height]
        win.contentView = canvas
        win.makeFirstResponder(canvas)
        win.makeKeyAndOrderFront(nil)

        self.window = win
        self.canvas = canvas
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        canvas = nil
        // Note: store.shapes is preserved — restored on next show()
    }
}
