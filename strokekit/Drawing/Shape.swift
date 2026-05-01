import AppKit

enum Shape: Equatable {
    case freehand(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    // More cases added in Plan 2
}
