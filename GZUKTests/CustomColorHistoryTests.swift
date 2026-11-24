import XCTest
import AppKit
@testable import GZUK

final class CustomColorHistoryTests: XCTestCase {
    private let presets: [NSColor] = [.systemRed, .black]
    private func rgb(_ r: Double, _ g: Double, _ b: Double) -> NSColor {
        NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    func test_firstCustomColor_becomesCurrentAndIsSaved() {
        var h = CustomColorHistory()
        let changed = h.recordUse(of: rgb(0.5, 1, 0.9), presets: presets)
        XCTAssertTrue(changed.current && changed.saved)
        XCTAssertEqual(h, CustomColorHistory(current: rgb(0.5, 1, 0.9),
                                             saved: [rgb(0.5, 1, 0.9)]))
    }

    func test_newCustomColor_goesToFrontOfSaved() {
        var h = CustomColorHistory(current: rgb(0.5, 1, 0.9), saved: [rgb(0.5, 1, 0.9)])
        h.recordUse(of: rgb(0.6, 0.3, 1), presets: presets)
        XCTAssertEqual(h, CustomColorHistory(current: rgb(0.6, 0.3, 1),
                                             saved: [rgb(0.6, 0.3, 1), rgb(0.5, 1, 0.9)]))
    }

    func test_presets_areIgnored() {
        var h = CustomColorHistory(current: rgb(0.5, 1, 0.9))
        let changed = h.recordUse(of: .systemRed, presets: presets)
        XCTAssertFalse(changed.current || changed.saved)
        XCTAssertEqual(h, CustomColorHistory(current: rgb(0.5, 1, 0.9)))
    }

    func test_reusingSavedColor_keepsPaletteOrder() {
        var h = CustomColorHistory(current: rgb(1, 0, 1), saved: [rgb(1, 0, 1), rgb(0, 1, 1)])
        let changed = h.recordUse(of: rgb(0, 1, 1), presets: presets)
        XCTAssertTrue(changed.current)
        XCTAssertFalse(changed.saved)
        XCTAssertEqual(h, CustomColorHistory(current: rgb(0, 1, 1),
                                             saved: [rgb(1, 0, 1), rgb(0, 1, 1)]))
    }

    func test_saved_isCapped_oldestDropped() {
        var h = CustomColorHistory()
        let n = CustomColorHistory.maxSaved + 2
        for i in 1...n {
            h.recordUse(of: rgb(Double(i) / 100, 0.5, 0.5), presets: presets)
        }
        XCTAssertEqual(h.saved.count, CustomColorHistory.maxSaved)
        XCTAssertTrue(CustomColorHistory.same(h.saved.first!, rgb(Double(n) / 100, 0.5, 0.5)))
        XCTAssertTrue(CustomColorHistory.same(h.saved.last!, rgb(0.03, 0.5, 0.5)))
    }

    func test_sameColor_ignoresColorSpace() {
        let deviceRGB = NSColor(deviceRed: 1, green: 1, blue: 1, alpha: 1)
        XCTAssertTrue(CustomColorHistory.same(.white, deviceRGB.usingColorSpace(.sRGB)!))
    }

    func test_store_reportsCommittedShapes() {
        let store = DrawingStore()
        var count = 0
        store.onShapeCommitted = { _ in count += 1 }
        store.commitShape(.line(from: .zero, to: CGPoint(x: 9, y: 9), color: .red, lineWidth: 2))
        store.undo()
        store.redo()
        XCTAssertEqual(count, 1)
    }
}
