import XCTest
import AppKit
@testable import GZUK

final class ShapeHitTesterTests: XCTestCase {
    func test_returnsNilForEmpty() {
        XCTAssertNil(ShapeHitTester.topmost(at: CGPoint(x: 50, y: 50), in: []))
    }

    func test_hitsRectangleWhenInside() {
        let r = Shape.rectangle(rect: CGRect(x: 0, y: 0, width: 100, height: 100),
                                color: .red, lineWidth: 3, filled: true)
        let idx = ShapeHitTester.topmost(at: CGPoint(x: 50, y: 50), in: [r])
        XCTAssertEqual(idx, 0)
    }

    func test_missesRectangleWhenOutside() {
        let r = Shape.rectangle(rect: CGRect(x: 0, y: 0, width: 100, height: 100),
                                color: .red, lineWidth: 3, filled: true)
        XCTAssertNil(ShapeHitTester.topmost(at: CGPoint(x: 200, y: 200), in: [r]))
    }

    func test_hitsLineWithinTolerance() {
        let l = Shape.line(from: .zero, to: CGPoint(x: 100, y: 0),
                           color: .red, lineWidth: 1)
        // 3pt off the line — within 4pt tolerance
        XCTAssertEqual(ShapeHitTester.topmost(at: CGPoint(x: 50, y: 3), in: [l]), 0)
    }

    func test_missesLineOutsideTolerance() {
        let l = Shape.line(from: .zero, to: CGPoint(x: 100, y: 0),
                           color: .red, lineWidth: 1)
        XCTAssertNil(ShapeHitTester.topmost(at: CGPoint(x: 50, y: 20), in: [l]))
    }

    func test_returnsTopmostWhenStacked() {
        let bottom = Shape.rectangle(rect: CGRect(x: 0, y: 0, width: 100, height: 100),
                                     color: .red, lineWidth: 3, filled: true)
        let top = Shape.rectangle(rect: CGRect(x: 25, y: 25, width: 50, height: 50),
                                  color: .blue, lineWidth: 3, filled: true)
        let idx = ShapeHitTester.topmost(at: CGPoint(x: 50, y: 50),
                                         in: [bottom, top])
        XCTAssertEqual(idx, 1)
    }
}
