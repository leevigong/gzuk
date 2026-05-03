import AppKit

enum ShapeHitTester {
    /// Returns the index of the topmost (last in array) shape whose hit region
    /// contains `point`, or nil. 4pt tolerance for thin strokes.
    static func topmost(at point: CGPoint, in shapes: [Shape]) -> Int? {
        for i in shapes.indices.reversed() {
            if hits(shape: shapes[i], at: point) { return i }
        }
        return nil
    }

    private static let tolerance: CGFloat = 4

    private static func hits(shape: Shape, at point: CGPoint) -> Bool {
        switch shape {
        case .rectangle(_, _, _, let filled),
             .circle(_, _, _, let filled):
            let path = ShapeRenderer.path(for: shape)
            if filled {
                return path.contains(point)
            } else {
                return strokeHits(path: path, lineWidth: lineWidthFor(shape), point: point)
            }

        case .text:
            // Bounding box of glyph path with tolerance
            let bb = ShapeRenderer.path(for: shape).boundingBox.insetBy(
                dx: -tolerance, dy: -tolerance)
            return bb.contains(point)

        case .counter(let center, _, _):
            let radius: CGFloat = 14 + tolerance
            return hypot(point.x - center.x, point.y - center.y) <= radius

        default:
            // freehand, highlighter, line, arrow — stroke hit test
            let path = ShapeRenderer.path(for: shape)
            return strokeHits(path: path,
                              lineWidth: lineWidthFor(shape),
                              point: point)
        }
    }

    private static func strokeHits(path: CGPath,
                                   lineWidth: CGFloat,
                                   point: CGPoint) -> Bool {
        let stroked = path.copy(strokingWithWidth: max(lineWidth, 1) + tolerance * 2,
                                lineCap: .round,
                                lineJoin: .round,
                                miterLimit: 10)
        return stroked.contains(point)
    }

    private static func lineWidthFor(_ shape: Shape) -> CGFloat {
        switch shape {
        case .freehand(_, _, let w),
             .highlighter(_, _, let w),
             .line(_, _, _, let w),
             .arrow(_, _, _, let w),
             .rectangle(_, _, let w, _),
             .circle(_, _, let w, _):
            return w
        case .text, .counter:
            return 0
        }
    }
}
