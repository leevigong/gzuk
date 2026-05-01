import AppKit

enum ShapeRenderer {
    /// Build a CGPath for the given shape. Stroking/filling is done by the caller.
    static func path(for shape: Shape) -> CGPath {
        switch shape {
        case .freehand(let points, _, _):
            let path = CGMutablePath()
            guard let first = points.first else { return path }
            path.move(to: first)
            for p in points.dropFirst() {
                path.addLine(to: p)
            }
            return path
        }
    }

    /// Stroke the shape into the given context using its color and line width.
    static func draw(_ shape: Shape, in ctx: CGContext) {
        let path = path(for: shape)
        guard !path.isEmpty else { return }

        switch shape {
        case .freehand(_, let color, let lineWidth):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.addPath(path)
            ctx.strokePath()
        }
    }
}
