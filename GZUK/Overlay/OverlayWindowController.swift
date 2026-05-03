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
        win.makeKeyAndOrderFront(nil)
        win.ignoresMouseEvents = store.isPassthrough

        self.window = win
        self.canvas = canvas
    }

    /// Toggle whether the overlay window passes mouse events through to apps below.
    func setPassthrough(_ on: Bool) {
        window?.ignoresMouseEvents = on
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        canvas = nil
        // Note: store.shapes is preserved — restored on next show()
    }
}
