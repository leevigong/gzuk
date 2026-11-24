import XCTest
import AppKit
@testable import GZUK

final class OutlineTests: XCTestCase {
    private let line = Shape.line(from: .zero, to: CGPoint(x: 100, y: 0),
                                  color: .red, lineWidth: 4)

    func test_storeWithoutOutline_commitsShapeAsIs() {
        let store = DrawingStore()
        store.commitShape(line)
        XCTAssertEqual(store.shapes, [line])
    }

    func test_storeWithOutline_wrapsCommittedShape() {
        let store = DrawingStore(outlineColor: { .white })
        store.commitShape(line)
        XCTAssertEqual(store.shapes, [.outlined(base: line, color: .white)])
    }

    func test_outline_followsLiveSetting() {
        var color: NSColor? = nil
        let store = DrawingStore(outlineColor: { color })
        store.commitShape(line)
        color = .black
        store.commitShape(line)
        XCTAssertEqual(store.shapes, [line, .outlined(base: line, color: .black)])
    }

    func test_highlighter_isNeverOutlined() {
        let store = DrawingStore(outlineColor: { .white })
        let hl = Shape.highlighter(points: [.zero, CGPoint(x: 10, y: 10)],
                                   color: .yellow, lineWidth: 12)
        store.commitShape(hl)
        XCTAssertEqual(store.shapes, [hl])
    }

    func test_decorated_isIdempotent() {
        let store = DrawingStore(outlineColor: { .white })
        let once = store.decorated(line)
        XCTAssertEqual(store.decorated(once), once)
    }

    func test_outlinedCounter_stillAdvancesNumber() {
        let store = DrawingStore(outlineColor: { .white })
        store.commitShape(.counter(center: .zero, number: 1, color: .red, lineWidth: 4))
        XCTAssertEqual(store.nextCounterNumber, 2)
    }

    func test_outlined_pathAndHitTestMatchBase() {
        let wrapped = Shape.outlined(base: line, color: .white)
        XCTAssertEqual(ShapeRenderer.path(for: wrapped).boundingBox,
                       ShapeRenderer.path(for: line).boundingBox)
        XCTAssertEqual(ShapeHitTester.topmost(at: CGPoint(x: 50, y: 2), in: [wrapped]), 0)
        XCTAssertNil(ShapeHitTester.topmost(at: CGPoint(x: 50, y: 40), in: [wrapped]))
    }

    func test_outlined_drawsBorderOutsideTheStroke() {
        // A white-outlined red line on a transparent canvas: a pixel just past
        // the red stroke's edge must be painted (the rim) and white.
        let size = 40
        let ctx = CGContext(data: nil, width: size, height: size,
                            bitsPerComponent: 8, bytesPerRow: size * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let shape = Shape.outlined(
            base: .line(from: CGPoint(x: 0, y: 20), to: CGPoint(x: 40, y: 20),
                        color: .red, lineWidth: 4),
            color: .white)
        ShapeRenderer.draw(shape, in: ctx)

        let px = ctx.data!.assumingMemoryBound(to: UInt8.self)
        func rgba(x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8) {
            let i = (y * size + x) * 4
            return (px[i], px[i + 1], px[i + 2], px[i + 3])
        }
        let center = rgba(x: 20, y: 20)
        XCTAssertGreaterThan(center.0, 200); XCTAssertLessThan(center.1, 80)  // red core
        // Pixel rows 22..23 sit 2–3pt off-center: past the red half-width (2pt),
        // inside the rim (2 + 1.6pt).
        let rim = rgba(x: 20, y: 22)
        XCTAssertGreaterThan(rim.3, 200)
        XCTAssertGreaterThan(rim.1, 200)  // white, not red
        XCTAssertEqual(rgba(x: 20, y: 30).3, 0)  // clear well outside
    }
}
