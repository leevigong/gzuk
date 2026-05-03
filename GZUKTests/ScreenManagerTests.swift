import XCTest
import AppKit
@testable import GZUK

final class ScreenManagerTests: XCTestCase {
    func test_returnsScreenContainingMouse() {
        let screenA = MockScreen(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        let screenB = MockScreen(frame: CGRect(x: 1000, y: 0, width: 1200, height: 900))

        let result = ScreenManager.screen(at: CGPoint(x: 1500, y: 100),
                                          in: [screenA, screenB])

        XCTAssertTrue(result === screenB)
    }

    func test_returnsNilWhenMouseOnNoScreen() {
        let screen = MockScreen(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))

        let result = ScreenManager.screen(at: CGPoint(x: 5000, y: 5000),
                                          in: [screen])

        XCTAssertNil(result)
    }
}

// Test double — only the `frame` property is used by ScreenManager
private final class MockScreen: ScreenLike {
    let frame: CGRect
    init(frame: CGRect) { self.frame = frame }
}
