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
}
