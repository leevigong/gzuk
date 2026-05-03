import AppKit
import Observation

final class DrawingCanvasView: NSView, NSTextFieldDelegate {
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
        if window != nil { armObservation() }
    }

    private func armObservation() {
        withObservationTracking {
            _ = store.shapes
            _ = store.currentTool
            _ = store.currentColor
            _ = store.currentLineWidth
            _ = store.isWhiteboard
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

        if store.isWhiteboard {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(bounds)
        }

        for shape in store.shapes {
            ShapeRenderer.draw(shape, in: ctx)
        }

        if let preview = makePreviewShape() {
            ShapeRenderer.draw(preview, in: ctx)
        }
    }

    // MARK: - Mouse state

    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?
    private var inProgressPoints: [CGPoint] = []
    private var activeTextField: NSTextField?

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)

        // Dismiss any active text editing first
        commitActiveTextField()

        switch store.currentTool {
        case .pen, .highlighter:
            inProgressPoints = [p]
            store.beginShape(at: p)

        case .line, .arrow, .rectangle, .circle:
            dragStart = p
            dragCurrent = p

        case .text:
            // Always start a new text field. Existing text shapes are
            // immutable — to change them, erase and re-type.
            startTextEditing(at: p)

        case .counter:
            let counter = Shape.counter(center: p,
                                        number: store.nextCounterNumber,
                                        color: store.currentColor)
            store.commitShape(counter)

        case .eraser:
            if let idx = ShapeHitTester.topmost(at: p, in: store.shapes) {
                store.eraseShape(at: idx)
            }
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        switch store.currentTool {
        case .pen, .highlighter:
            inProgressPoints.append(p)
            store.appendPoint(p)
        case .line, .arrow, .rectangle, .circle:
            dragCurrent = p
        case .eraser:
            if let idx = ShapeHitTester.topmost(at: p, in: store.shapes) {
                store.eraseShape(at: idx)
            }
        default:
            break
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        switch store.currentTool {
        case .pen, .highlighter:
            store.commitShape()
            inProgressPoints = []

        case .line, .arrow, .rectangle, .circle:
            if let s = makePreviewShape() {
                store.commitShape(s)
            }
            dragStart = nil
            dragCurrent = nil

        default:
            break
        }
        needsDisplay = true
    }

    /// Build the preview shape for the current drag (or in-progress freehand).
    /// Returns nil when there's nothing to preview.
    private func makePreviewShape() -> Shape? {
        switch store.currentTool {
        case .pen:
            guard !inProgressPoints.isEmpty else { return nil }
            return .freehand(points: inProgressPoints,
                             color: store.currentColor,
                             lineWidth: store.currentLineWidth)

        case .highlighter:
            guard !inProgressPoints.isEmpty else { return nil }
            return .highlighter(points: inProgressPoints,
                                color: store.currentColor,
                                lineWidth: max(store.currentLineWidth * 3, 12))

        case .line:
            guard let a = dragStart, let b = dragCurrent else { return nil }
            return .line(from: a, to: b,
                         color: store.currentColor,
                         lineWidth: store.currentLineWidth)

        case .arrow:
            guard let a = dragStart, let b = dragCurrent else { return nil }
            return .arrow(from: a, to: b,
                          color: store.currentColor,
                          lineWidth: store.currentLineWidth)

        case .rectangle:
            guard let a = dragStart, let b = dragCurrent else { return nil }
            return .rectangle(rect: rectBetween(a, b),
                              color: store.currentColor,
                              lineWidth: store.currentLineWidth,
                              filled: false)

        case .circle:
            guard let a = dragStart, let b = dragCurrent else { return nil }
            return .circle(rect: rectBetween(a, b),
                           color: store.currentColor,
                           lineWidth: store.currentLineWidth,
                           filled: false)

        case .text, .counter, .eraser:
            return nil
        }
    }

    private func rectBetween(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    // MARK: - Text editing

    private func startTextEditing(at point: CGPoint,
                                  initialString: String = "",
                                  font: NSFont? = nil,
                                  color: NSColor? = nil) {
        let resolvedFont = font ?? NSFont.systemFont(ofSize: max(14, store.currentLineWidth * 5))
        let resolvedColor = color ?? store.currentColor
        // Cap width so text wraps before running off the right edge of the canvas.
        let maxWidth = max(120, bounds.width - point.x - 16)
        let field = NSTextField(frame: NSRect(x: point.x, y: point.y,
                                              width: min(200, maxWidth),
                                              height: resolvedFont.pointSize + 8))
        field.font = resolvedFont
        field.textColor = resolvedColor
        field.backgroundColor = .clear
        field.isBordered = false
        field.focusRingType = .none
        field.delegate = self
        field.stringValue = initialString
        // Multi-line wrapping — set on both the control and its NSTextFieldCell
        // because NSTextField's auto-wrap depends on both being configured.
        field.usesSingleLineMode = false
        field.lineBreakMode = .byCharWrapping
        field.maximumNumberOfLines = 0
        if let cell = field.cell as? NSTextFieldCell {
            cell.wraps = true
            cell.isScrollable = false
            cell.usesSingleLineMode = false
            cell.lineBreakMode = .byCharWrapping
        }
        addSubview(field)
        window?.makeFirstResponder(field)
        if !initialString.isEmpty,
           let editor = field.currentEditor() {
            editor.selectedRange = NSRange(location: initialString.count, length: 0)
        }
        activeTextField = field
    }

    private func commitActiveTextField() {
        guard let field = activeTextField else { return }
        let text = field.stringValue
        let font = field.font ?? NSFont.systemFont(ofSize: 14)
        let color = field.textColor ?? .black
        let maxWidth = field.frame.width
        // Convert NSTextField top-left frame into a baseline-anchored origin
        // so ShapeRenderer (which expects baseline) draws at the same visual
        // location the user just typed in.
        let baselineY = field.frame.maxY - field.firstBaselineOffsetFromTop
        let origin = CGPoint(x: field.frame.minX + 2, y: baselineY)
        field.removeFromSuperview()
        activeTextField = nil
        if !text.isEmpty {
            store.commitShape(.text(origin: origin,
                                    string: text,
                                    font: font,
                                    color: color,
                                    maxWidth: maxWidth))
        }
        needsDisplay = true
    }

    // NSTextFieldDelegate
    func control(_ control: NSControl,
                 textView: NSTextView,
                 doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            // Shift+Enter inserts a literal newline; plain Enter commits.
            if NSEvent.modifierFlags.contains(.shift) {
                textView.insertText("\n", replacementRange: textView.selectedRange)
                return true
            }
            commitActiveTextField()
            return true
        }
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            activeTextField?.removeFromSuperview()
            activeTextField = nil
            needsDisplay = true
            return true
        }
        return false
    }

    /// Resize the active text field as the user types so long strings aren't clipped.
    /// Width grows up to a cap (the remaining canvas width), then height grows for wrapping.
    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        // Don't touch the field while a Korean/Japanese/Chinese IME is mid-composition;
        // mutating the frame here resets the marked text and breaks the input.
        if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() {
            return
        }
        let font = field.font ?? NSFont.systemFont(ofSize: 14)
        let maxWidth = max(120, bounds.width - field.frame.minX - 16)
        let attr = NSAttributedString(string: field.stringValue,
                                      attributes: [.font: font])
        // Measure with wrapping at maxWidth so multi-line text reports its real height.
        let bounding = attr.boundingRect(
            with: NSSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading])
        let newWidth = min(maxWidth, max(60, bounding.width + 24))
        let newHeight = max(font.pointSize + 8, bounding.height + 8)
        var f = field.frame
        // Keep top-left fixed (i.e. grow downward) when height changes.
        let oldMaxY = f.maxY
        f.size.width = newWidth
        f.size.height = newHeight
        f.origin.y = oldMaxY - newHeight
        field.frame = f
    }

    // MARK: - Keyboard (Undo / Redo)

    override var acceptsFirstResponder: Bool { true }

    /// Accept the first click even when our window is not key — otherwise the
    /// click that activates the overlay (e.g. after using the toolbar) is
    /// swallowed by AppKit's "click-to-activate" behavior.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func keyDown(with event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chars = event.charactersIgnoringModifiers ?? ""
        switch (chars, mods) {
        case ("z", .command):
            store.undo()
        case ("z", [.command, .shift]):
            store.redo()
        case (",", .command):
            // Standard macOS Settings shortcut. Needed because the overlay
            // covers the screen and blocks right-clicks on the menu bar item.
            store.requestSettings()
        default:
            // Single-letter tool shortcuts (P, H, L, A, R, C, T, N, E)
            // — only when no modifier is held and no text field is editing.
            if mods.isEmpty,
               activeTextField == nil,
               let char = chars.first,
               let tool = Tool.allCases.first(where: { $0.hotkey == char }) {
                store.setTool(tool)
            } else {
                super.keyDown(with: event)
            }
        }
    }
}
