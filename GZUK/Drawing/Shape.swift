import AppKit

enum Shape: Equatable {
    case freehand(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    case highlighter(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    case line(from: CGPoint, to: CGPoint, color: NSColor, lineWidth: CGFloat)
    case arrow(from: CGPoint, to: CGPoint, color: NSColor, lineWidth: CGFloat)
    case rectangle(rect: CGRect, color: NSColor, lineWidth: CGFloat, filled: Bool)
    case circle(rect: CGRect, color: NSColor, lineWidth: CGFloat, filled: Bool)
    case text(origin: CGPoint, string: String, font: NSFont, color: NSColor, maxWidth: CGFloat)
    case counter(center: CGPoint, number: Int, color: NSColor, lineWidth: CGFloat)
}
