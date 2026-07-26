import XCTest
import AppKit
@testable import GZUK

final class DrawingStoreTests: XCTestCase {
    var store: DrawingStore!

    override func setUp() {
        super.setUp()
        store = DrawingStore()
    }

    func test_initialState() {
        XCTAssertTrue(store.shapes.isEmpty)
        XCTAssertEqual(store.currentTool, .pen)
        XCTAssertFalse(store.isDrawing)
    }

    func test_toggle_flipsIsDrawing() {
        XCTAssertFalse(store.isDrawing)
        store.toggle()
        XCTAssertTrue(store.isDrawing)
        store.toggle()
        XCTAssertFalse(store.isDrawing)
    }

    func test_drawingAFreehand_addsAShape() {
        store.beginShape(at: CGPoint(x: 0, y: 0))
        store.appendPoint(CGPoint(x: 10, y: 10))
        store.appendPoint(CGPoint(x: 20, y: 0))
        store.commitShape()

        XCTAssertEqual(store.shapes.count, 1)
        if case .freehand(let points, _, _) = store.shapes[0] {
            XCTAssertEqual(points, [CGPoint(x: 0, y: 0),
                                    CGPoint(x: 10, y: 10),
                                    CGPoint(x: 20, y: 0)])
        } else {
            XCTFail("expected freehand")
        }
    }

    func test_undo_removesLastShape() {
        addOneShape()
        addOneShape()
        XCTAssertEqual(store.shapes.count, 2)

        store.undo()
        XCTAssertEqual(store.shapes.count, 1)
    }

    func test_redo_restoresUndoneShape() {
        addOneShape()
        store.undo()
        XCTAssertEqual(store.shapes.count, 0)

        store.redo()
        XCTAssertEqual(store.shapes.count, 1)
    }

    func test_commitShape_clearsRedoStack() {
        addOneShape()
        store.undo()
        addOneShape()       // new draw clears redo

        store.redo()        // should be a no-op
        XCTAssertEqual(store.shapes.count, 1)
    }

    func test_clear_emptiesShapesAndIsUndoable() {
        addOneShape()
        addOneShape()
        store.clear()
        XCTAssertTrue(store.shapes.isEmpty)

        store.undo()
        XCTAssertEqual(store.shapes.count, 2)
    }

    func test_setTool_updatesCurrentTool() {
        store.setTool(.rectangle)
        XCTAssertEqual(store.currentTool, .rectangle)
    }

    func test_setColor_updatesCurrentColor() {
        store.setColor(.systemBlue)
        XCTAssertEqual(store.currentColor, .systemBlue)
    }

    func test_setLineWidth_updatesCurrentLineWidth() {
        store.setLineWidth(10)
        XCTAssertEqual(store.currentLineWidth, 10)
    }

    func test_commitNonFreehand_addsShape() {
        let rect = Shape.rectangle(rect: CGRect(x: 0, y: 0, width: 50, height: 50),
                                   color: .red, lineWidth: 3, filled: false)
        store.commitShape(rect)
        XCTAssertEqual(store.shapes.count, 1)
        XCTAssertEqual(store.shapes[0], rect)
    }

    func test_commitNonFreehand_isUndoable() {
        let line = Shape.line(from: .zero, to: CGPoint(x: 100, y: 0),
                              color: .red, lineWidth: 3)
        store.commitShape(line)
        store.undo()
        XCTAssertTrue(store.shapes.isEmpty)
    }

    func test_eraseShape_removesByIndex() {
        let a = Shape.rectangle(rect: CGRect(x: 0, y: 0, width: 50, height: 50),
                                color: .red, lineWidth: 3, filled: true)
        let b = Shape.line(from: .zero, to: CGPoint(x: 10, y: 10),
                           color: .blue, lineWidth: 3)
        store.commitShape(a)
        store.commitShape(b)

        store.eraseShape(at: 0)
        XCTAssertEqual(store.shapes, [b])
    }

    func test_eraseShape_isUndoable() {
        let a = Shape.rectangle(rect: CGRect(x: 0, y: 0, width: 50, height: 50),
                                color: .red, lineWidth: 3, filled: true)
        store.commitShape(a)
        store.eraseShape(at: 0)
        store.undo()
        XCTAssertEqual(store.shapes, [a])
    }

    func test_counter_startsAt1AndIncrementsOnCommit() {
        XCTAssertEqual(store.nextCounterNumber, 1)
        let c = Shape.counter(center: CGPoint(x: 10, y: 10),
                              number: store.nextCounterNumber, color: .red, lineWidth: 4)
        store.commitShape(c)
        XCTAssertEqual(store.nextCounterNumber, 2)
    }

    func test_counter_undoDecrements() {
        let c = Shape.counter(center: .zero,
                              number: store.nextCounterNumber, color: .red, lineWidth: 4)
        store.commitShape(c)
        XCTAssertEqual(store.nextCounterNumber, 2)
        store.undo()
        XCTAssertEqual(store.nextCounterNumber, 1)
    }

    func test_counter_clearResetsTo1() {
        let c = Shape.counter(center: .zero,
                              number: store.nextCounterNumber, color: .red, lineWidth: 4)
        store.commitShape(c)
        store.commitShape(c)
        store.clear()
        XCTAssertEqual(store.nextCounterNumber, 1)
    }

    func test_whiteboard_togglesAndStartsOff() {
        XCTAssertFalse(store.isWhiteboard)
        store.toggleWhiteboard()
        XCTAssertTrue(store.isWhiteboard)
        store.toggleWhiteboard()
        XCTAssertFalse(store.isWhiteboard)
    }

    // helper
    private func addOneShape() {
        store.beginShape(at: .zero)
        store.appendPoint(CGPoint(x: 1, y: 1))
        store.commitShape()
    }
}
