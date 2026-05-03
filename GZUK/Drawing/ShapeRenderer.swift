import AppKit
import CoreText

enum ShapeRenderer {
    /// Build a CGPath for the given shape. Stroking/filling is done by the caller
    /// (or in `draw(_:in:)`).
    static func path(for shape: Shape) -> CGPath {
        switch shape {
        case .freehand(let points, _, _):
            return polyline(points: points)

        case .highlighter(let points, _, _):
            return polyline(points: points)

        case .line(let from, let to, _, _):
            let p = CGMutablePath()
            p.move(to: from); p.addLine(to: to)
            return p

        case .arrow(let from, let to, _, let lineWidth):
            return arrowPath(from: from, to: to, lineWidth: lineWidth)

        case .rectangle(let rect, _, _, _):
            return CGPath(rect: rect, transform: nil)

        case .circle(let rect, _, _, _):
            return CGPath(ellipseIn: rect, transform: nil)

        case .text(let origin, let string, let font, _, let maxWidth):
            return textPath(string: string, font: font, origin: origin,
                            maxWidth: maxWidth)

        case .counter(let center, _, _, let lineWidth):
            return counterPath(center: center, lineWidth: lineWidth)
        }
    }

    /// Stroke / fill the shape into the given context using its color/width.
    static func draw(_ shape: Shape, in ctx: CGContext) {
        switch shape {
        case .freehand(_, let color, let lineWidth):
            strokePath(path(for: shape), in: ctx, color: color, lineWidth: lineWidth)

        case .highlighter(_, let color, let lineWidth):
            // Highlighter = wider stroke at lower alpha
            let translucent = color.withAlphaComponent(0.35)
            strokePath(path(for: shape), in: ctx, color: translucent,
                       lineWidth: lineWidth, blendMode: .multiply)

        case .line(_, _, let color, let lineWidth),
             .arrow(_, _, let color, let lineWidth):
            strokePath(path(for: shape), in: ctx, color: color, lineWidth: lineWidth)

        case .rectangle(_, let color, let lineWidth, let filled),
             .circle(_, let color, let lineWidth, let filled):
            if filled {
                ctx.setFillColor(color.cgColor)
                ctx.addPath(path(for: shape))
                ctx.fillPath()
            } else {
                strokePath(path(for: shape), in: ctx, color: color, lineWidth: lineWidth)
            }

        case .text(_, _, _, let color, _):
            ctx.setFillColor(color.cgColor)
            ctx.addPath(path(for: shape))
            ctx.fillPath()

        case .counter(let center, let number, let color, let lineWidth):
            // Filled circle + number text on top. Both scale with the
            // current line-width slider so the badge matches stroke weight.
            let radius = counterRadius(lineWidth: lineWidth)
            let rect = CGRect(x: center.x - radius, y: center.y - radius,
                              width: radius * 2, height: radius * 2)
            ctx.setFillColor(color.cgColor)
            ctx.addPath(CGPath(ellipseIn: rect, transform: nil))
            ctx.fillPath()

            // Number in white, centered
            let font = NSFont.boldSystemFont(ofSize: counterFontSize(lineWidth: lineWidth))
            let numberPath = textPath(string: "\(number)",
                                      font: font,
                                      origin: .zero)
            let bb = numberPath.boundingBox
            let translated = CGMutablePath()
            translated.addPath(numberPath,
                               transform: CGAffineTransform(
                                   translationX: center.x - bb.midX,
                                   y: center.y - bb.midY))
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.addPath(translated)
            ctx.fillPath()
        }
    }

    // MARK: - Helpers

    private static func polyline(points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        return path
    }

    private static func arrowPath(from: CGPoint,
                                  to: CGPoint,
                                  lineWidth: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: from); path.addLine(to: to)

        // Arrowhead — two segments at ±30° from the line, length scales with lineWidth
        let dx = to.x - from.x
        let dy = to.y - from.y
        let angle = atan2(dy, dx)
        let headLength = max(10, lineWidth * 4)
        let headAngle: CGFloat = .pi / 6   // 30°

        let leftAngle = angle + .pi - headAngle
        let rightAngle = angle + .pi + headAngle
        let left = CGPoint(x: to.x + cos(leftAngle) * headLength,
                           y: to.y + sin(leftAngle) * headLength)
        let right = CGPoint(x: to.x + cos(rightAngle) * headLength,
                            y: to.y + sin(rightAngle) * headLength)
        path.move(to: to); path.addLine(to: left)
        path.move(to: to); path.addLine(to: right)
        return path
    }

    private static func textPath(string: String,
                                 font: NSFont,
                                 origin: CGPoint,
                                 maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGPath {
        guard !string.isEmpty else { return CGMutablePath() }
        let attr = NSAttributedString(string: string, attributes: [.font: font])
        let combined = CGMutablePath()

        // Use a typesetter to wrap the string into lines no wider than `maxWidth`.
        let typesetter = CTTypesetterCreateWithAttributedString(attr)
        let total = attr.length
        var charIndex = 0
        var lineIndex = 0
        let lineHeight = font.ascender - font.descender + font.leading

        while charIndex < total {
            let take = CTTypesetterSuggestLineBreak(typesetter, charIndex, Double(maxWidth))
            let line = CTTypesetterCreateLine(typesetter, CFRange(location: charIndex, length: take))
            // Each line's baseline drops by `lineHeight` from the first.
            let lineBaselineY = origin.y - CGFloat(lineIndex) * lineHeight
            let runs = CTLineGetGlyphRuns(line) as! [CTRun]
            for run in runs {
                let count = CTRunGetGlyphCount(run)
                var glyphs = [CGGlyph](repeating: 0, count: count)
                var positions = [CGPoint](repeating: .zero, count: count)
                CTRunGetGlyphs(run, CFRange(), &glyphs)
                CTRunGetPositions(run, CFRange(), &positions)
                let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
                for i in 0 ..< count {
                    if let g = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) {
                        let t = CGAffineTransform(translationX: origin.x + positions[i].x,
                                                  y: lineBaselineY + positions[i].y)
                        combined.addPath(g, transform: t)
                    }
                }
            }
            charIndex += take
            lineIndex += 1
        }
        return combined
    }

    private static func counterPath(center: CGPoint, lineWidth: CGFloat) -> CGPath {
        let radius = counterRadius(lineWidth: lineWidth)
        let rect = CGRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
        return CGPath(ellipseIn: rect, transform: nil)
    }

    /// Counter circle radius scales with the line-width slider so the badge
    /// visually matches stroke weight (default lineWidth=4 keeps the legacy
    /// 14pt radius). Same factor used by ShapeHitTester for hit detection.
    static func counterRadius(lineWidth: CGFloat) -> CGFloat {
        max(8, lineWidth * 3.5)
    }

    static func counterFontSize(lineWidth: CGFloat) -> CGFloat {
        max(10, lineWidth * 4)
    }

    private static func strokePath(_ path: CGPath,
                                   in ctx: CGContext,
                                   color: NSColor,
                                   lineWidth: CGFloat,
                                   blendMode: CGBlendMode = .normal) {
        guard !path.isEmpty else { return }
        ctx.saveGState()
        ctx.setBlendMode(blendMode)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
    }
}
