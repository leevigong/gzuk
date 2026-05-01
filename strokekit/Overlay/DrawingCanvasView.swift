import AppKit
import Observation

final class DrawingCanvasView: NSView {
    private let store: DrawingStore

    init(store: DrawingStore, frame: CGRect) {
        self.store = store
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            armObservation()
        }
    }

    /// Re-arm withObservationTracking after each fire, otherwise it only fires once.
    private func armObservation() {
        withObservationTracking {
            _ = store.shapes
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.needsDisplay = true
                self?.armObservation()
            }
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        for shape in store.shapes {
            ShapeRenderer.draw(shape, in: ctx)
        }
        // Render in-progress stroke (last point chain) so the user sees it live
        if !inProgressPoints.isEmpty {
            let preview = Shape.freehand(points: inProgressPoints,
                                         color: store.currentColor,
                                         lineWidth: store.currentLineWidth)
            ShapeRenderer.draw(preview, in: ctx)
        }
    }

    // MARK: - Mouse events

    private var inProgressPoints: [CGPoint] = []

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        inProgressPoints = [p]
        store.beginShape(at: p)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        inProgressPoints.append(p)
        store.appendPoint(p)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        store.commitShape()
        inProgressPoints = []
        // store change triggers redraw via observation
    }

    // MARK: - Keyboard (Undo/Redo)

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        switch (event.charactersIgnoringModifiers, mods) {
        case ("z", .command):
            store.undo()
        case ("z", [.command, .shift]):
            store.redo()
        default:
            super.keyDown(with: event)
        }
    }
}
