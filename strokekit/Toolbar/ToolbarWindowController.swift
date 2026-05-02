import AppKit
import SwiftUI

final class ToolbarWindowController {
    private let store: DrawingStore
    private let anchorProvider: () -> NSRect?
    private var window: ToolbarWindow?

    init(store: DrawingStore,
         anchorProvider: @escaping () -> NSRect? = { nil }) {
        self.store = store
        self.anchorProvider = anchorProvider
    }

    func show() {
        guard window == nil else { return }

        let hosting = NSHostingView(rootView: ToolbarView(store: store))
        let size = hosting.fittingSize
        let win = ToolbarWindow(contentSize: size)
        win.contentView = hosting

        let origin = ToolbarPositionStore.load()
            ?? defaultOrigin(for: size)
        win.setFrameOrigin(origin)
        win.orderFront(nil)
        self.window = win
    }

    func hide() {
        if let w = window { ToolbarPositionStore.save(w.frame.origin) }
        window?.orderOut(nil)
        window = nil
    }

    /// Default position: just below the menu bar status item if available,
    /// otherwise top-center of the cursor's screen.
    private func defaultOrigin(for size: CGSize) -> CGPoint {
        if let anchor = anchorProvider() {
            // 4pt gap below the status item button
            return CGPoint(x: anchor.midX - size.width / 2,
                           y: anchor.minY - size.height - 4)
        }
        guard let screen = ScreenManager.screenWithCursor() else {
            return CGPoint(x: 100, y: 100)
        }
        let f = screen.frame
        return CGPoint(x: f.midX - size.width / 2,
                       y: f.maxY - size.height - 40)
    }
}
