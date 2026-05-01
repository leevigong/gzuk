import XCTest
import AppKit
@testable import strokekit

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

    // helper
    private func addOneShape() {
        store.beginShape(at: .zero)
        store.appendPoint(CGPoint(x: 1, y: 1))
        store.commitShape()
    }
}
