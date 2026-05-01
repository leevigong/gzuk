import AppKit
import Observation

@Observable
final class DrawingStore {
    private(set) var shapes: [Shape] = []
    var currentTool: Tool = .pen
    private(set) var isDrawing: Bool = false

    // v0.1: fixed color and width. Plan 2 makes these mutable.
    let currentColor: NSColor = .systemRed
    let currentLineWidth: CGFloat = 3

    private var undoStack: [[Shape]] = []
    private var redoStack: [[Shape]] = []

    // In-progress freehand points before commit
    private var inProgressPoints: [CGPoint] = []

    func toggle() {
        isDrawing.toggle()
    }

    func beginShape(at point: CGPoint) {
        inProgressPoints = [point]
    }

    func appendPoint(_ point: CGPoint) {
        inProgressPoints.append(point)
    }

    func commitShape() {
        guard inProgressPoints.count >= 1 else { return }
        let shape = Shape.freehand(points: inProgressPoints,
                                   color: currentColor,
                                   lineWidth: currentLineWidth)
        pushUndoSnapshot()
        shapes.append(shape)
        redoStack.removeAll()
        inProgressPoints = []
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(shapes)
        shapes = previous
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(shapes)
        shapes = next
    }

    func clear() {
        guard !shapes.isEmpty else { return }
        pushUndoSnapshot()
        shapes = []
        redoStack.removeAll()
    }

    /// Snapshot the current shape list for undo before mutating.
    private func pushUndoSnapshot() {
        undoStack.append(shapes)
        // Keep history bounded to avoid unbounded memory in long sessions
        if undoStack.count > 100 {
            undoStack.removeFirst(undoStack.count - 100)
        }
    }
}
