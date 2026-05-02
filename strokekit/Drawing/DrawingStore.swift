import AppKit
import Observation

@Observable
final class DrawingStore {
    private(set) var shapes: [Shape] = []
    private(set) var currentTool: Tool = .pen
    private(set) var currentColor: NSColor = .systemRed
    private(set) var currentLineWidth: CGFloat = 4
    private(set) var isDrawing: Bool = false
    private(set) var isWhiteboard: Bool = false
    /// When true, the overlay window passes mouse clicks through to apps
    /// underneath while still showing existing strokes. Toolbar still works.
    private(set) var isPassthrough: Bool = false
    private(set) var nextCounterNumber: Int = 1

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    /// Snapshot of the mutable drawing state for undo/redo.
    private struct Snapshot: Equatable {
        let shapes: [Shape]
        let nextCounterNumber: Int
    }

    // In-progress freehand-style points before commit (pen/highlighter)
    private var inProgressPoints: [CGPoint] = []

    // MARK: - Mode toggle

    func toggle() {
        isDrawing.toggle()
    }

    func toggleWhiteboard() {
        isWhiteboard.toggle()
    }

    func togglePassthrough() {
        isPassthrough.toggle()
    }

    // MARK: - Tool / color / width

    func setTool(_ tool: Tool) {
        currentTool = tool
    }

    func setColor(_ color: NSColor) {
        currentColor = color
    }

    func setLineWidth(_ width: CGFloat) {
        currentLineWidth = width
    }

    // MARK: - Freehand-style (pen, highlighter)

    func beginShape(at point: CGPoint) {
        inProgressPoints = [point]
    }

    func appendPoint(_ point: CGPoint) {
        inProgressPoints.append(point)
    }

    /// Commit the in-progress polyline as a freehand or highlighter shape, based on currentTool.
    func commitShape() {
        guard !inProgressPoints.isEmpty else { return }
        let shape: Shape
        switch currentTool {
        case .highlighter:
            shape = .highlighter(points: inProgressPoints,
                                 color: currentColor,
                                 lineWidth: max(currentLineWidth * 3, 12))
        default:
            shape = .freehand(points: inProgressPoints,
                              color: currentColor,
                              lineWidth: currentLineWidth)
        }
        commitShape(shape)
        inProgressPoints = []
    }

    // MARK: - Generic commit (for line/arrow/rect/circle/text/counter)

    /// Commit a fully-formed shape (used by tools that build the shape on mouseUp).
    /// Pushes undo, clears redo, increments counter if applicable.
    func commitShape(_ shape: Shape) {
        pushUndoSnapshot()
        shapes.append(shape)
        if case .counter = shape {
            nextCounterNumber += 1
        }
        redoStack.removeAll()
    }

    // MARK: - Eraser

    func eraseShape(at index: Int) {
        guard shapes.indices.contains(index) else { return }
        pushUndoSnapshot()
        shapes.remove(at: index)
        redoStack.removeAll()
    }

    // MARK: - Undo / redo / clear

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(currentSnapshot())
        applySnapshot(previous)
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(currentSnapshot())
        applySnapshot(next)
    }

    func clear() {
        guard !shapes.isEmpty || nextCounterNumber > 1 else { return }
        pushUndoSnapshot()
        shapes = []
        nextCounterNumber = 1
        redoStack.removeAll()
    }

    // MARK: - Snapshot helpers

    private func currentSnapshot() -> Snapshot {
        Snapshot(shapes: shapes, nextCounterNumber: nextCounterNumber)
    }

    private func applySnapshot(_ s: Snapshot) {
        shapes = s.shapes
        nextCounterNumber = s.nextCounterNumber
    }

    private func pushUndoSnapshot() {
        undoStack.append(currentSnapshot())
        if undoStack.count > 100 {
            undoStack.removeFirst(undoStack.count - 100)
        }
    }
}
