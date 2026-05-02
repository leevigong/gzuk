import SwiftUI
import AppKit

struct DragHandleView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { _DragHandleNSView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class _DragHandleNSView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }
}
