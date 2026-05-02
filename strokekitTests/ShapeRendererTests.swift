import XCTest
import AppKit
@testable import strokekit

final class ShapeRendererTests: XCTestCase {
    func test_freehand_pathPassesThroughAllPoints() {
        let points: [CGPoint] = [
            CGPoint(x: 10, y: 10),
            CGPoint(x: 20, y: 10),
            CGPoint(x: 20, y: 30),
        ]
        let shape = Shape.freehand(points: points, color: .red, lineWidth: 3)

        let path = ShapeRenderer.path(for: shape)

        // Bounding box must contain all points
        XCTAssertEqual(path.boundingBox, CGRect(x: 10, y: 10, width: 10, height: 20))
    }

    func test_freehand_emptyPoints_returnsEmptyPath() {
        let shape = Shape.freehand(points: [], color: .red, lineWidth: 3)
        let path = ShapeRenderer.path(for: shape)
        XCTAssertTrue(path.isEmpty)
    }

    func test_highlighter_pathPassesThroughAllPoints() {
        let shape = Shape.highlighter(points: [.zero, CGPoint(x: 50, y: 50)],
                                      color: .yellow, lineWidth: 12)
        XCTAssertEqual(ShapeRenderer.path(for: shape).boundingBox,
                       CGRect(x: 0, y: 0, width: 50, height: 50))
    }

    func test_line_pathIsTwoPoints() {
        let shape = Shape.line(from: CGPoint(x: 0, y: 0),
                               to: CGPoint(x: 100, y: 50),
                               color: .red, lineWidth: 3)
        XCTAssertEqual(ShapeRenderer.path(for: shape).boundingBox,
                       CGRect(x: 0, y: 0, width: 100, height: 50))
    }

    func test_arrow_boundingBoxIncludesHead() {
        let shape = Shape.arrow(from: CGPoint(x: 0, y: 0),
                                to: CGPoint(x: 100, y: 0),
                                color: .red, lineWidth: 3)
        let bb = ShapeRenderer.path(for: shape).boundingBox
        XCTAssertEqual(bb.minX, 0, accuracy: 0.01)
        XCTAssertEqual(bb.maxX, 100, accuracy: 0.01)
        XCTAssertGreaterThan(bb.height, 0)
    }

    func test_rectangle_pathIsTheRect() {
        let shape = Shape.rectangle(rect: CGRect(x: 10, y: 20, width: 100, height: 50),
                                    color: .blue, lineWidth: 3, filled: false)
        XCTAssertEqual(ShapeRenderer.path(for: shape).boundingBox,
                       CGRect(x: 10, y: 20, width: 100, height: 50))
    }

    func test_circle_pathIsEllipseInRect() {
        let shape = Shape.circle(rect: CGRect(x: 0, y: 0, width: 80, height: 60),
                                 color: .blue, lineWidth: 3, filled: false)
        let bb = ShapeRenderer.path(for: shape).boundingBox
        XCTAssertEqual(bb, CGRect(x: 0, y: 0, width: 80, height: 60))
    }

    func test_text_pathIsNonEmpty() {
        let shape = Shape.text(origin: .zero,
                               string: "Hi",
                               font: NSFont.systemFont(ofSize: 24),
                               color: .black,
                               maxWidth: .greatestFiniteMagnitude)
        XCTAssertFalse(ShapeRenderer.path(for: shape).isEmpty)
    }

    func test_counter_pathIsNonEmpty() {
        let shape = Shape.counter(center: CGPoint(x: 100, y: 100),
                                  number: 1,
                                  color: .red)
        XCTAssertFalse(ShapeRenderer.path(for: shape).isEmpty)
    }
}
