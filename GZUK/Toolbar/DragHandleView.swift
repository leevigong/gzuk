import SwiftUI
import AppKit

struct DragHandleView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { _DragHandleNSView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    /// Moves the toolbar window by hand instead of calling
    /// `NSWindow.performDrag(with:)`. performDrag hands the move to the window
    /// server, which pins the window's top edge below the menu bar and never
    /// consults our `constrainFrameRect` override — so the toolbar could not
    /// be parked over the menubar. Repositioning with `setFrameOrigin`
    /// ourselves does go through that override, so it can.
    private final class _DragHandleNSView: NSView {
        /// Cursor position minus window origin, captured on mouseDown so the
        /// grabbed point stays under the pointer for the whole drag.
        private var grabOffset: CGSize?
        /// Distinguishes a real drag from a plain click on the toolbar
        /// background, which shouldn't count as the user repositioning it.
        private var didDrag = false

        override func mouseDown(with event: NSEvent) {
            guard let win = window else { return }
            let mouse = NSEvent.mouseLocation
            grabOffset = CGSize(width: mouse.x - win.frame.origin.x,
                                height: mouse.y - win.frame.origin.y)
            didDrag = false
        }

        override func mouseDragged(with event: NSEvent) {
            guard let win = window, let offset = grabOffset else { return }
            didDrag = true
            let mouse = NSEvent.mouseLocation
            win.setFrameOrigin(CGPoint(x: mouse.x - offset.width,
                                       y: mouse.y - offset.height))
            // Re-check every frame so the toolbar rises above the menu bar
            // the moment it touches it, instead of sliding under it.
            (win as? ToolbarWindow)?.updateLevelForMenuBarOverlap()
        }

        override func mouseUp(with event: NSEvent) {
            defer { grabOffset = nil; didDrag = false }
            guard didDrag, let toolbar = window as? ToolbarWindow else { return }
            toolbar.userHasRepositioned = true
            toolbar.updateLevelForMenuBarOverlap()
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }
}
