import AppKit

indirect enum Shape: Equatable {
    case freehand(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    case highlighter(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    case line(from: CGPoint, to: CGPoint, color: NSColor, lineWidth: CGFloat)
    case arrow(from: CGPoint, to: CGPoint, color: NSColor, lineWidth: CGFloat)
    case rectangle(rect: CGRect, color: NSColor, lineWidth: CGFloat, filled: Bool)
    case circle(rect: CGRect, color: NSColor, lineWidth: CGFloat, filled: Bool)
    case text(origin: CGPoint, string: String, font: NSFont, color: NSColor, maxWidth: CGFloat)
    case counter(center: CGPoint, number: Int, color: NSColor, lineWidth: CGFloat)
    /// `base` drawn on top of a contrasting border in `color`, so marks stay
    /// legible over busy or same-colored backgrounds. The border is baked in
    /// at commit time: changing the setting later doesn't repaint old marks.
    case outlined(base: Shape, color: NSColor)

    /// The shape without any border wrapper — for code that only cares about
    /// geometry (hit testing, type checks).
    var base: Shape {
        if case .outlined(let inner, _) = self { return inner.base }
        return self
    }
}
