# strokekit v0.5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand v0.1 (pen-only MVP) to feature parity with Bandicam/Annotate's drawing tools, plus a floating toolbar with color palette and line-width selector.

**Spec reference:** `docs/superpowers/specs/2026-04-30-strokekit-design.md`

**Builds on:** `docs/superpowers/plans/2026-04-30-strokekit-v0.1.md` (must be at v0.1.0 tag)

---

## v0.5 scope

**In scope:**
- 8 new tools: highlighter, line, arrow, rectangle (stroke + fill), circle (stroke + fill), text, counter, eraser
- Floating toolbar (`NSPanel` at `.popUpMenu` level), draggable, persists position
- Color palette: 8 presets (red/orange/yellow/green/blue/purple/white/black) + "More…" → `NSColorPanel`
- Line width selector: 4 presets (2pt / 4pt / 6pt / 10pt) shown as dot icons
- Whiteboard mode toggle (white background, fills overlay)
- Per-tool mouse handling and live preview while drawing
- Object-based eraser (delete whole shape on click; undoable)
- Drawing store grows: mutable `currentColor`, `currentLineWidth`, `currentTool`, `isWhiteboard`, `nextCounterNumber`

**Out of scope (deferred to v1.0):**
- Settings UI / `PreferencesStore`
- Dropdown toolbar mode (`NSPopover`) — v0.5 ships floating only
- First-run welcome popover
- Customizable hotkey
- Per-tool keyboard shortcuts (P, R, etc.)
- Custom whiteboard color (just white in v0.5)
- Recent colors history
- Homebrew distribution

---

## File Structure

Files added or significantly modified in this plan:

```
strokekit/
├── strokekit/
│   ├── Drawing/
│   │   ├── Shape.swift                       (MODIFIED — add 7 cases)
│   │   ├── ShapeRenderer.swift               (MODIFIED — render all cases)
│   │   ├── Tool.swift                        (MODIFIED — add 8 cases)
│   │   ├── DrawingStore.swift                (MODIFIED — color/width/tool mutation, counter, whiteboard, eraser)
│   │   └── ShapeHitTester.swift              (NEW — for eraser)
│   ├── Overlay/
│   │   ├── DrawingCanvasView.swift           (MODIFIED — per-tool mouse, preview, text editing, hit-test for eraser)
│   │   └── OverlayWindow.swift               (MODIFIED — whiteboard background)
│   ├── Toolbar/                              (NEW)
│   │   ├── ToolbarWindow.swift               (NEW — NSPanel subclass)
│   │   ├── ToolbarWindowController.swift     (NEW — show/hide, position memory)
│   │   ├── ToolbarView.swift                 (NEW — SwiftUI root)
│   │   ├── ToolButton.swift                  (NEW — SwiftUI tool button)
│   │   ├── ColorPaletteView.swift            (NEW — SwiftUI 8 swatches + More)
│   │   ├── LineWidthPickerView.swift         (NEW — SwiftUI 4 dots)
│   │   ├── WhiteboardToggleView.swift        (NEW — SwiftUI toggle button)
│   │   └── DragHandleView.swift              (NEW — NSViewRepresentable for window drag)
│   ├── Utils/
│   │   └── ToolbarPositionStore.swift        (NEW — UserDefaults wrapper for last position)
│   └── AppDelegate.swift                     (MODIFIED — wire ToolbarWindowController)
├── strokekitTests/
│   ├── ShapeRendererTests.swift              (MODIFIED — tests per shape type)
│   ├── DrawingStoreTests.swift               (MODIFIED — tool/color/width/counter/eraser/whiteboard)
│   └── ShapeHitTesterTests.swift             (NEW)
```

**TDD applies to:** `Shape`, `ShapeRenderer`, `DrawingStore`, `ShapeHitTester` — pure logic.

**Manual QA only:** all `Toolbar/*` files, `DrawingCanvasView` mouse/preview behavior, `OverlayWindow` whiteboard.

---

## Phase 1 — Data model expansion

Tasks 1–6 expand the model so every tool has a representable shape, a renderer, and store mutators. No UI yet.

---

## Task 1: Expand `Tool` enum

**Files:**
- Modify: `strokekit/Drawing/Tool.swift`

- [ ] **Step 1: Replace contents**

```swift
import Foundation

enum Tool: String, CaseIterable, Identifiable {
    case pen
    case highlighter
    case line
    case arrow
    case rectangle
    case circle
    case text
    case counter
    case eraser

    var id: String { rawValue }

    /// SF Symbol used in the toolbar.
    var symbolName: String {
        switch self {
        case .pen:         return "pencil.tip"
        case .highlighter: return "highlighter"
        case .line:        return "line.diagonal"
        case .arrow:       return "arrow.up.right"
        case .rectangle:   return "rectangle"
        case .circle:      return "circle"
        case .text:        return "textformat"
        case .counter:     return "1.circle"
        case .eraser:      return "eraser"
        }
    }
}
```

- [ ] **Step 2: Build**

`⌘B`. Must succeed.

- [ ] **Step 3: Commit**

```bash
git add strokekit/Drawing/Tool.swift
git commit -m "feat(drawing): expand Tool enum to 9 cases with symbols"
```

---

## Task 2: Expand `Shape` enum (TDD)

**Files:**
- Modify: `strokekit/Drawing/Shape.swift`
- (No new tests yet — Shape is just a data type; ShapeRenderer tests cover its behavior in Task 3.)

- [ ] **Step 1: Replace contents**

```swift
import AppKit

enum Shape: Equatable {
    case freehand(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    case highlighter(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    case line(from: CGPoint, to: CGPoint, color: NSColor, lineWidth: CGFloat)
    case arrow(from: CGPoint, to: CGPoint, color: NSColor, lineWidth: CGFloat)
    case rectangle(rect: CGRect, color: NSColor, lineWidth: CGFloat, filled: Bool)
    case circle(rect: CGRect, color: NSColor, lineWidth: CGFloat, filled: Bool)
    case text(origin: CGPoint, string: String, font: NSFont, color: NSColor)
    case counter(center: CGPoint, number: Int, color: NSColor)
}
```

- [ ] **Step 2: Build**

`⌘B`. Existing code (canvas, store) breaks because `switch shape` is no longer exhaustive. **Don't fix yet** — Task 4 (ShapeRenderer) and Task 5 (DrawingStore) cover the new cases. For now, add a temporary `default: break` to any failing `switch` (we'll remove them in those tasks).

Actually — to keep the build green between commits, add the `default: break` right now:

- In `ShapeRenderer.swift`, the switch in `draw(_:in:)` and the switch in `path(for:)` — add `default: break` and `default: return CGMutablePath()` respectively. (These are temporary; Task 3 properly handles all cases.)
- Run `⌘B`. Must succeed.

- [ ] **Step 3: Commit**

```bash
git add strokekit/Drawing/Shape.swift strokekit/Drawing/ShapeRenderer.swift
git commit -m "feat(drawing): expand Shape enum to 8 cases (renderer stubs follow)"
```

---

## Task 3: Expand `ShapeRenderer` (TDD)

**Files:**
- Modify: `strokekit/Drawing/ShapeRenderer.swift`
- Modify: `strokekitTests/ShapeRendererTests.swift`

For each new shape, write a small test that asserts its `path(for:)` produces the expected `boundingBox`. Stroke/fill correctness is verified by manual QA (visual). Counter and text use Core Text glyphs — test that the path is non-empty.

- [ ] **Step 1: Add failing tests**

Append to `strokekitTests/ShapeRendererTests.swift`:

```swift
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
    // Arrow path = line + 2 head segments. Bounding box should encompass head points,
    // which extend slightly past `to` perpendicular to the line.
    let shape = Shape.arrow(from: CGPoint(x: 0, y: 0),
                            to: CGPoint(x: 100, y: 0),
                            color: .red, lineWidth: 3)
    let bb = ShapeRenderer.path(for: shape).boundingBox
    XCTAssertEqual(bb.minX, 0, accuracy: 0.01)
    XCTAssertEqual(bb.maxX, 100, accuracy: 0.01)
    XCTAssertGreaterThan(bb.height, 0)  // head extends above + below the line
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
                           color: .black)
    XCTAssertFalse(ShapeRenderer.path(for: shape).isEmpty)
}

func test_counter_pathIsNonEmpty() {
    let shape = Shape.counter(center: CGPoint(x: 100, y: 100),
                              number: 1,
                              color: .red)
    XCTAssertFalse(ShapeRenderer.path(for: shape).isEmpty)
}
```

- [ ] **Step 2: Run — verify failures**

`⌘U`. New tests fail (returning empty path due to the temporary `default` from Task 2).

- [ ] **Step 3: Implement all renderers**

Replace `strokekit/Drawing/ShapeRenderer.swift`:

```swift
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

        case .text(let origin, let string, let font, _):
            return textPath(string: string, font: font, origin: origin)

        case .counter(let center, let number, _):
            return counterPath(center: center, number: number)
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

        case .text(_, _, _, let color):
            ctx.setFillColor(color.cgColor)
            ctx.addPath(path(for: shape))
            ctx.fillPath()

        case .counter(let center, let number, let color):
            // Filled circle + number text on top
            let radius: CGFloat = 14
            let rect = CGRect(x: center.x - radius, y: center.y - radius,
                              width: radius * 2, height: radius * 2)
            ctx.setFillColor(color.cgColor)
            ctx.addPath(CGPath(ellipseIn: rect, transform: nil))
            ctx.fillPath()

            // Number in white, centered
            let font = NSFont.boldSystemFont(ofSize: 16)
            let textPathFor = textPath(string: "\(number)",
                                       font: font,
                                       origin: .zero)
            // Re-center the text path
            let bb = textPathFor.boundingBox
            let translated = CGMutablePath()
            translated.addPath(textPathFor,
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
                                 origin: CGPoint) -> CGPath {
        guard !string.isEmpty else { return CGMutablePath() }
        let attr = NSAttributedString(string: string, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attr)
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        let combined = CGMutablePath()
        for run in runs {
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(), &glyphs)
            CTRunGetPositions(run, CFRange(), &positions)
            let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
            for i in 0 ..< count {
                if let g = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) {
                    var t = CGAffineTransform(translationX: origin.x + positions[i].x,
                                              y: origin.y + positions[i].y)
                    combined.addPath(g, transform: t)
                }
            }
        }
        return combined
    }

    private static func counterPath(center: CGPoint, number: Int) -> CGPath {
        let radius: CGFloat = 14
        let rect = CGRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
        return CGPath(ellipseIn: rect, transform: nil)
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
```

- [ ] **Step 4: Run — verify all tests pass**

`⌘U`. Both old and new tests pass.

- [ ] **Step 5: Commit**

```bash
git add strokekit/Drawing/ShapeRenderer.swift strokekitTests/ShapeRendererTests.swift
git commit -m "feat(drawing): render highlighter/line/arrow/rect/circle/text/counter"
```

---

## Task 4: Add `ShapeHitTester` (TDD)

**Files:**
- Create: `strokekit/Drawing/ShapeHitTester.swift`
- Create: `strokekitTests/ShapeHitTesterTests.swift`

For the eraser. Given a click point and a list of shapes, return the **topmost** (last-drawn) shape whose hit region contains the click. Tolerance for thin strokes: 4pt.

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
import AppKit
@testable import strokekit

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
```

- [ ] **Step 2: Run — verify failures**

`⌘U`. Fail with `Cannot find 'ShapeHitTester' in scope`.

- [ ] **Step 3: Implement**

Create `strokekit/Drawing/ShapeHitTester.swift`:

```swift
import AppKit

enum ShapeHitTester {
    /// Returns the index of the topmost (last in array) shape whose hit region
    /// contains `point`, or nil. 4pt tolerance for thin strokes.
    static func topmost(at point: CGPoint, in shapes: [Shape]) -> Int? {
        for i in shapes.indices.reversed() {
            if hits(shape: shapes[i], at: point) { return i }
        }
        return nil
    }

    private static let tolerance: CGFloat = 4

    private static func hits(shape: Shape, at point: CGPoint) -> Bool {
        switch shape {
        case .rectangle(_, _, _, let filled),
             .circle(_, _, _, let filled):
            let path = ShapeRenderer.path(for: shape)
            if filled {
                return path.contains(point)
            } else {
                return strokeHits(path: path, lineWidth: lineWidthFor(shape), point: point)
            }

        case .text:
            // Bounding box of glyph path with tolerance
            let bb = ShapeRenderer.path(for: shape).boundingBox.insetBy(
                dx: -tolerance, dy: -tolerance)
            return bb.contains(point)

        case .counter(let center, _, _):
            let radius: CGFloat = 14 + tolerance
            return hypot(point.x - center.x, point.y - center.y) <= radius

        default:
            // freehand, highlighter, line, arrow — stroke hit test
            let path = ShapeRenderer.path(for: shape)
            return strokeHits(path: path,
                              lineWidth: lineWidthFor(shape),
                              point: point)
        }
    }

    private static func strokeHits(path: CGPath,
                                   lineWidth: CGFloat,
                                   point: CGPoint) -> Bool {
        let stroked = path.copy(strokingWithWidth: max(lineWidth, 1) + tolerance * 2,
                                lineCap: .round,
                                lineJoin: .round,
                                miterLimit: 10)
        return stroked.contains(point)
    }

    private static func lineWidthFor(_ shape: Shape) -> CGFloat {
        switch shape {
        case .freehand(_, _, let w),
             .highlighter(_, _, let w),
             .line(_, _, _, let w),
             .arrow(_, _, _, let w),
             .rectangle(_, _, let w, _),
             .circle(_, _, let w, _):
            return w
        case .text, .counter:
            return 0
        }
    }
}
```

- [ ] **Step 4: Run — verify pass**

`⌘U`. All hit tester tests pass.

- [ ] **Step 5: Commit**

```bash
git add strokekit/Drawing/ShapeHitTester.swift strokekitTests/ShapeHitTesterTests.swift
git commit -m "feat(drawing): add ShapeHitTester for object-based eraser"
```

---

## Task 5: Expand `DrawingStore` (TDD)

**Files:**
- Modify: `strokekit/Drawing/DrawingStore.swift`
- Modify: `strokekitTests/DrawingStoreTests.swift`

Add: mutable `currentTool` / `currentColor` / `currentLineWidth`, `isWhiteboard`, `nextCounterNumber`. Add: `commitNonFreehand(_:)` for line/arrow/rect/circle/text/counter, `eraseShape(at:)`, `setColor`, `setLineWidth`, `setTool`, `toggleWhiteboard`.

- [ ] **Step 1: Add failing tests**

Append to `strokekitTests/DrawingStoreTests.swift`:

```swift
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
                          number: store.nextCounterNumber, color: .red)
    store.commitShape(c)
    XCTAssertEqual(store.nextCounterNumber, 2)
}

func test_counter_undoDecrements() {
    let c = Shape.counter(center: .zero,
                          number: store.nextCounterNumber, color: .red)
    store.commitShape(c)
    XCTAssertEqual(store.nextCounterNumber, 2)
    store.undo()
    XCTAssertEqual(store.nextCounterNumber, 1)
}

func test_counter_clearResetsTo1() {
    let c = Shape.counter(center: .zero,
                          number: store.nextCounterNumber, color: .red)
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
```

- [ ] **Step 2: Run — verify failures**

`⌘U`. New tests fail (methods/properties don't exist yet).

- [ ] **Step 3: Update `DrawingStore`**

Replace `strokekit/Drawing/DrawingStore.swift`:

```swift
import AppKit
import Observation

@Observable
final class DrawingStore {
    private(set) var shapes: [Shape] = []
    private(set) var currentTool: Tool = .pen
    private(set) var currentColor: NSColor = .systemRed
    private(set) var currentLineWidth: CGFloat = 3
    private(set) var isDrawing: Bool = false
    private(set) var isWhiteboard: Bool = false
    private(set) var nextCounterNumber: Int = 1

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    /// Snapshot of the mutable drawing state for undo/redo.
    private struct Snapshot: Equatable {
        let shapes: [Shape]
        let nextCounterNumber: Int
    }

    // In-progress freehand-style points before commit (pen/highlighter)
    private var inProgressPoints: [CGPoint] = []

    // MARK: - Mode toggle

    func toggle() {
        isDrawing.toggle()
    }

    func toggleWhiteboard() {
        isWhiteboard.toggle()
    }

    // MARK: - Tool / color / width

    func setTool(_ tool: Tool) {
        currentTool = tool
    }

    func setColor(_ color: NSColor) {
        currentColor = color
    }

    func setLineWidth(_ width: CGFloat) {
        currentLineWidth = width
    }

    // MARK: - Freehand-style (pen, highlighter)

    func beginShape(at point: CGPoint) {
        inProgressPoints = [point]
    }

    func appendPoint(_ point: CGPoint) {
        inProgressPoints.append(point)
    }

    /// Commit the in-progress polyline as a freehand or highlighter shape, based on currentTool.
    func commitShape() {
        guard !inProgressPoints.isEmpty else { return }
        let shape: Shape
        switch currentTool {
        case .highlighter:
            shape = .highlighter(points: inProgressPoints,
                                 color: currentColor,
                                 lineWidth: max(currentLineWidth * 3, 12))
        default:
            shape = .freehand(points: inProgressPoints,
                              color: currentColor,
                              lineWidth: currentLineWidth)
        }
        commitShape(shape)
        inProgressPoints = []
    }

    // MARK: - Generic commit (for line/arrow/rect/circle/text/counter)

    /// Commit a fully-formed shape (used by tools that build the shape on mouseUp).
    /// Pushes undo, clears redo, increments counter if applicable.
    func commitShape(_ shape: Shape) {
        pushUndoSnapshot()
        shapes.append(shape)
        if case .counter = shape {
            nextCounterNumber += 1
        }
        redoStack.removeAll()
    }

    // MARK: - Eraser

    func eraseShape(at index: Int) {
        guard shapes.indices.contains(index) else { return }
        pushUndoSnapshot()
        shapes.remove(at: index)
        redoStack.removeAll()
    }

    // MARK: - Undo / redo / clear

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(currentSnapshot())
        applySnapshot(previous)
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(currentSnapshot())
        applySnapshot(next)
    }

    func clear() {
        guard !shapes.isEmpty || nextCounterNumber > 1 else { return }
        pushUndoSnapshot()
        shapes = []
        nextCounterNumber = 1
        redoStack.removeAll()
    }

    // MARK: - Snapshot helpers

    private func currentSnapshot() -> Snapshot {
        Snapshot(shapes: shapes, nextCounterNumber: nextCounterNumber)
    }

    private func applySnapshot(_ s: Snapshot) {
        shapes = s.shapes
        nextCounterNumber = s.nextCounterNumber
    }

    private func pushUndoSnapshot() {
        undoStack.append(currentSnapshot())
        if undoStack.count > 100 {
            undoStack.removeFirst(undoStack.count - 100)
        }
    }
}
```

- [ ] **Step 4: Run — verify pass**

`⌘U`. All tests (old + new) pass.

- [ ] **Step 5: Commit**

```bash
git add strokekit/Drawing/DrawingStore.swift strokekitTests/DrawingStoreTests.swift
git commit -m "feat(drawing): expand store with tool/color/width, counter, eraser, whiteboard"
```

---

## Task 6: Update `DrawingCanvasView` for all tools

**Files:**
- Modify: `strokekit/Overlay/DrawingCanvasView.swift`

Per-tool mouse handling. For tools that produce a single shape on `mouseUp` (line, arrow, rectangle, circle), track `dragStartPoint` and current `dragPoint`, render a preview every drag, commit on up. For text, mount an `NSTextField` on click. For counter, commit immediately on click. For eraser, hit-test on `mouseDown`.

- [ ] **Step 1: Replace contents**

```swift
import AppKit
import Observation

final class DrawingCanvasView: NSView, NSTextFieldDelegate {
    private let store: DrawingStore

    init(store: DrawingStore, frame: CGRect) {
        self.store = store
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { armObservation() }
    }

    private func armObservation() {
        withObservationTracking {
            _ = store.shapes
            _ = store.currentTool
            _ = store.currentColor
            _ = store.currentLineWidth
            _ = store.isWhiteboard
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.needsDisplay = true
                self?.armObservation()
            }
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        if store.isWhiteboard {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(bounds)
        }

        for shape in store.shapes {
            ShapeRenderer.draw(shape, in: ctx)
        }

        if let preview = makePreviewShape() {
            ShapeRenderer.draw(preview, in: ctx)
        }
    }

    // MARK: - Mouse state

    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?
    private var inProgressPoints: [CGPoint] = []
    private var activeTextField: NSTextField?

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)

        // Dismiss any active text editing first
        commitActiveTextField()

        switch store.currentTool {
        case .pen, .highlighter:
            inProgressPoints = [p]
            store.beginShape(at: p)

        case .line, .arrow, .rectangle, .circle:
            dragStart = p
            dragCurrent = p

        case .text:
            startTextEditing(at: p)

        case .counter:
            let counter = Shape.counter(center: p,
                                        number: store.nextCounterNumber,
                                        color: store.currentColor)
            store.commitShape(counter)

        case .eraser:
            if let idx = ShapeHitTester.topmost(at: p, in: store.shapes) {
                store.eraseShape(at: idx)
            }
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        switch store.currentTool {
        case .pen, .highlighter:
            inProgressPoints.append(p)
            store.appendPoint(p)
        case .line, .arrow, .rectangle, .circle:
            dragCurrent = p
        default:
            break
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        switch store.currentTool {
        case .pen, .highlighter:
            store.commitShape()
            inProgressPoints = []

        case .line, .arrow, .rectangle, .circle:
            if let s = makePreviewShape() {
                store.commitShape(s)
            }
            dragStart = nil
            dragCurrent = nil

        default:
            break
        }
        needsDisplay = true
    }

    /// Build the preview shape for the current drag (or in-progress freehand).
    /// Returns nil when there's nothing to preview.
    private func makePreviewShape() -> Shape? {
        switch store.currentTool {
        case .pen:
            guard !inProgressPoints.isEmpty else { return nil }
            return .freehand(points: inProgressPoints,
                             color: store.currentColor,
                             lineWidth: store.currentLineWidth)

        case .highlighter:
            guard !inProgressPoints.isEmpty else { return nil }
            return .highlighter(points: inProgressPoints,
                                color: store.currentColor,
                                lineWidth: max(store.currentLineWidth * 3, 12))

        case .line:
            guard let a = dragStart, let b = dragCurrent else { return nil }
            return .line(from: a, to: b,
                         color: store.currentColor,
                         lineWidth: store.currentLineWidth)

        case .arrow:
            guard let a = dragStart, let b = dragCurrent else { return nil }
            return .arrow(from: a, to: b,
                          color: store.currentColor,
                          lineWidth: store.currentLineWidth)

        case .rectangle:
            guard let a = dragStart, let b = dragCurrent else { return nil }
            return .rectangle(rect: rectBetween(a, b),
                              color: store.currentColor,
                              lineWidth: store.currentLineWidth,
                              filled: false)

        case .circle:
            guard let a = dragStart, let b = dragCurrent else { return nil }
            return .circle(rect: rectBetween(a, b),
                           color: store.currentColor,
                           lineWidth: store.currentLineWidth,
                           filled: false)

        case .text, .counter, .eraser:
            return nil
        }
    }

    private func rectBetween(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    // MARK: - Text editing

    private func startTextEditing(at point: CGPoint) {
        let font = NSFont.systemFont(ofSize: max(14, store.currentLineWidth * 5))
        let field = NSTextField(frame: NSRect(x: point.x, y: point.y,
                                              width: 200, height: font.pointSize + 8))
        field.font = font
        field.textColor = store.currentColor
        field.backgroundColor = .clear
        field.isBordered = false
        field.focusRingType = .none
        field.delegate = self
        field.stringValue = ""
        addSubview(field)
        window?.makeFirstResponder(field)
        activeTextField = field
    }

    private func commitActiveTextField() {
        guard let field = activeTextField else { return }
        let text = field.stringValue
        let origin = field.frame.origin
        let font = field.font ?? NSFont.systemFont(ofSize: 14)
        let color = field.textColor ?? .black
        field.removeFromSuperview()
        activeTextField = nil
        if !text.isEmpty {
            store.commitShape(.text(origin: origin,
                                    string: text,
                                    font: font,
                                    color: color))
        }
        needsDisplay = true
    }

    // NSTextFieldDelegate
    func control(_ control: NSControl,
                 textView: NSTextView,
                 doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            commitActiveTextField()
            return true
        }
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            activeTextField?.removeFromSuperview()
            activeTextField = nil
            needsDisplay = true
            return true
        }
        return false
    }

    // MARK: - Keyboard (Undo / Redo)

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        switch (event.charactersIgnoringModifiers, mods) {
        case ("z", .command):
            store.undo()
        case ("z", [.command, .shift]):
            store.redo()
        default:
            super.keyDown(with: event)
        }
    }
}
```

- [ ] **Step 2: Build**

`⌘B`. Must succeed.

- [ ] **Step 3: Commit**

```bash
git add strokekit/Overlay/DrawingCanvasView.swift
git commit -m "feat(overlay): per-tool mouse handling, live preview, text/eraser/counter"
```

---

## Phase 2 — Floating toolbar UI

Tasks 7–14 build the SwiftUI toolbar inside an `NSPanel`.

---

## Task 7: Add `ToolbarPositionStore`

**Files:**
- Create: `strokekit/Utils/ToolbarPositionStore.swift`

Tiny `UserDefaults` wrapper for last toolbar position.

- [ ] **Step 1: Create file**

```swift
import AppKit

enum ToolbarPositionStore {
    private static let key = "strokekit.toolbar.lastOrigin"

    static func save(_ origin: CGPoint) {
        let dict = ["x": origin.x, "y": origin.y]
        UserDefaults.standard.set(dict, forKey: key)
    }

    static func load() -> CGPoint? {
        guard let dict = UserDefaults.standard.dictionary(forKey: key),
              let x = dict["x"] as? CGFloat,
              let y = dict["y"] as? CGFloat else { return nil }
        return CGPoint(x: x, y: y)
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add strokekit/Utils/ToolbarPositionStore.swift
git commit -m "feat(utils): add ToolbarPositionStore for floating toolbar position"
```

---

## Task 8: Create `ToolbarWindow` (NSPanel)

**Files:**
- Create: `strokekit/Toolbar/ToolbarWindow.swift`

`NSPanel` configured to float above overlay, never steal focus.

- [ ] **Step 1: Create folder + file**

In Xcode: right-click `strokekit/` → New Group → `Toolbar`. Inside, New File → Swift File → `ToolbarWindow.swift`:

```swift
import AppKit

final class ToolbarWindow: NSPanel {
    init(contentSize: CGSize) {
        super.init(contentRect: NSRect(origin: .zero, size: contentSize),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .popUpMenu
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        self.isMovableByWindowBackground = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,
                                   .stationary, .ignoresCycle]
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add strokekit/Toolbar/ToolbarWindow.swift
git commit -m "feat(toolbar): add ToolbarWindow (NSPanel) at .popUpMenu level"
```

---

## Task 9: Create `DragHandleView`

**Files:**
- Create: `strokekit/Toolbar/DragHandleView.swift`

`NSViewRepresentable` wrapping an `NSView` whose `mouseDown` / `mouseDragged` call `window?.performDrag(with:)`. SwiftUI overlays this on the toolbar's grip area.

- [ ] **Step 1: Create file**

```swift
import SwiftUI
import AppKit

struct DragHandleView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { _DragHandleNSView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class _DragHandleNSView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
        // Allow click-through to children when not dragging? No — this view IS the handle.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add strokekit/Toolbar/DragHandleView.swift
git commit -m "feat(toolbar): add DragHandleView for window drag in SwiftUI"
```

---

## Task 10: Create `ColorPaletteView`

**Files:**
- Create: `strokekit/Toolbar/ColorPaletteView.swift`

8 swatches + "More…" button that opens `NSColorPanel`.

- [ ] **Step 1: Create file**

```swift
import SwiftUI
import AppKit

struct ColorPaletteView: View {
    let store: DrawingStore

    private static let presets: [(NSColor, String)] = [
        (.systemRed, "Red"),
        (.systemOrange, "Orange"),
        (.systemYellow, "Yellow"),
        (.systemGreen, "Green"),
        (.systemBlue, "Blue"),
        (.systemPurple, "Purple"),
        (.white, "White"),
        (.black, "Black"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, item in
                let (color, name) = item
                Button {
                    store.setColor(color)
                } label: {
                    Circle()
                        .fill(Color(nsColor: color))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle().stroke(
                                isSelected(color) ? Color.accentColor : .clear,
                                lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .help(name)
            }

            Button {
                openColorPanel()
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .help("More colors…")
        }
    }

    private func isSelected(_ color: NSColor) -> Bool {
        // Compare RGB-equivalent components (NSColor equality is finicky across spaces).
        guard let a = store.currentColor.usingColorSpace(.sRGB),
              let b = color.usingColorSpace(.sRGB) else { return false }
        return abs(a.redComponent - b.redComponent) < 0.001 &&
               abs(a.greenComponent - b.greenComponent) < 0.001 &&
               abs(a.blueComponent - b.blueComponent) < 0.001
    }

    private func openColorPanel() {
        let panel = NSColorPanel.shared
        panel.color = store.currentColor
        panel.setTarget(ColorPanelTarget.shared)
        panel.setAction(#selector(ColorPanelTarget.colorChanged(_:)))
        ColorPanelTarget.shared.onChange = { store.setColor($0) }
        panel.makeKeyAndOrderFront(nil)
    }
}

/// Bridges NSColorPanel's target/action to a closure.
private final class ColorPanelTarget: NSObject {
    static let shared = ColorPanelTarget()
    var onChange: ((NSColor) -> Void)?
    @objc func colorChanged(_ panel: NSColorPanel) { onChange?(panel.color) }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add strokekit/Toolbar/ColorPaletteView.swift
git commit -m "feat(toolbar): add ColorPaletteView with 8 presets + NSColorPanel"
```

---

## Task 11: Create `LineWidthPickerView`

**Files:**
- Create: `strokekit/Toolbar/LineWidthPickerView.swift`

4 dot-icon buttons: 2pt / 4pt / 6pt / 10pt.

- [ ] **Step 1: Create file**

```swift
import SwiftUI

struct LineWidthPickerView: View {
    let store: DrawingStore
    private static let widths: [CGFloat] = [2, 4, 6, 10]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Self.widths, id: \.self) { w in
                Button {
                    store.setLineWidth(w)
                } label: {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: dotSize(for: w), height: dotSize(for: w))
                        .frame(width: 22, height: 22)   // hit-target
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(store.currentLineWidth == w
                                        ? Color.accentColor : .clear,
                                        lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .help("\(Int(w))pt")
            }
        }
    }

    private func dotSize(for w: CGFloat) -> CGFloat {
        // Map 2/4/6/10 → ~ 4/6/8/12 visual diameter
        4 + w * 0.8
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add strokekit/Toolbar/LineWidthPickerView.swift
git commit -m "feat(toolbar): add LineWidthPickerView with 4 preset widths"
```

---

## Task 12: Create `ToolButton` and `WhiteboardToggleView`

**Files:**
- Create: `strokekit/Toolbar/ToolButton.swift`
- Create: `strokekit/Toolbar/WhiteboardToggleView.swift`

- [ ] **Step 1: Create `ToolButton.swift`**

```swift
import SwiftUI

struct ToolButton: View {
    let tool: Tool
    let store: DrawingStore

    var body: some View {
        Button {
            store.setTool(tool)
        } label: {
            Image(systemName: tool.symbolName)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(store.currentTool == tool
                              ? Color.accentColor.opacity(0.25)
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tool.rawValue.capitalized)
    }
}
```

- [ ] **Step 2: Create `WhiteboardToggleView.swift`**

```swift
import SwiftUI

struct WhiteboardToggleView: View {
    let store: DrawingStore

    var body: some View {
        Button {
            store.toggleWhiteboard()
        } label: {
            Image(systemName: store.isWhiteboard
                  ? "square.fill"
                  : "square.dashed")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(store.isWhiteboard
                              ? Color.accentColor.opacity(0.25)
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help("Whiteboard")
    }
}
```

- [ ] **Step 3: Build + commit**

```bash
git add strokekit/Toolbar/ToolButton.swift strokekit/Toolbar/WhiteboardToggleView.swift
git commit -m "feat(toolbar): add ToolButton + WhiteboardToggleView"
```

---

## Task 13: Create `ToolbarView` (SwiftUI root)

**Files:**
- Create: `strokekit/Toolbar/ToolbarView.swift`

Composes the drag handle, tool row, color palette, line-width picker, whiteboard, and undo/redo.

- [ ] **Step 1: Create file**

```swift
import SwiftUI

struct ToolbarView: View {
    let store: DrawingStore

    var body: some View {
        VStack(spacing: 6) {
            DragHandleView()
                .frame(height: 6)

            HStack(spacing: 4) {
                ForEach(Tool.allCases) { tool in
                    ToolButton(tool: tool, store: store)
                }
            }

            Divider()
            ColorPaletteView(store: store)

            Divider()
            LineWidthPickerView(store: store)

            Divider()
            HStack(spacing: 6) {
                WhiteboardToggleView(store: store)
                Button { store.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                }.buttonStyle(.plain).help("Undo")
                Button { store.redo() } label: {
                    Image(systemName: "arrow.uturn.forward")
                }.buttonStyle(.plain).help("Redo")
                Button { store.clear() } label: {
                    Image(systemName: "trash")
                }.buttonStyle(.plain).help("Clear")
            }
        }
        .padding(8)
        .background(.regularMaterial)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
        )
        .frame(width: 320)
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add strokekit/Toolbar/ToolbarView.swift
git commit -m "feat(toolbar): compose ToolbarView (tools + colors + width + whiteboard + undo)"
```

---

## Task 14: Create `ToolbarWindowController`

**Files:**
- Create: `strokekit/Toolbar/ToolbarWindowController.swift`

Owns lifecycle: build window with `NSHostingView<ToolbarView>`, restore last position (or default to top-center of cursor's screen), save position on close.

- [ ] **Step 1: Create file**

```swift
import AppKit
import SwiftUI

final class ToolbarWindowController {
    private let store: DrawingStore
    private var window: ToolbarWindow?

    init(store: DrawingStore) {
        self.store = store
    }

    func show() {
        guard window == nil else { return }

        let hosting = NSHostingView(rootView: ToolbarView(store: store))
        let size = hosting.fittingSize
        let win = ToolbarWindow(contentSize: size)
        win.contentView = hosting

        let origin = ToolbarPositionStore.load()
            ?? defaultOrigin(for: size)
        win.setFrameOrigin(origin)
        win.orderFront(nil)
        self.window = win
    }

    func hide() {
        if let w = window { ToolbarPositionStore.save(w.frame.origin) }
        window?.orderOut(nil)
        window = nil
    }

    /// Top-center of the cursor's screen as a sensible first-run default.
    private func defaultOrigin(for size: CGSize) -> CGPoint {
        guard let screen = ScreenManager.screenWithCursor() else {
            return CGPoint(x: 100, y: 100)
        }
        let f = screen.frame
        return CGPoint(x: f.midX - size.width / 2,
                       y: f.maxY - size.height - 40)
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add strokekit/Toolbar/ToolbarWindowController.swift
git commit -m "feat(toolbar): add ToolbarWindowController with position memory"
```

---

## Phase 3 — Wiring + manual QA

---

## Task 15: Wire toolbar into `AppDelegate`

**Files:**
- Modify: `strokekit/AppDelegate.swift`

Add a `ToolbarWindowController`, show/hide it alongside the overlay.

- [ ] **Step 1: Modify**

In `applicationDidFinishLaunching`, after `overlayController = ...`:

```swift
toolbarController = ToolbarWindowController(store: store)
```

Add the property:

```swift
private var toolbarController: ToolbarWindowController?
```

In `handleIsDrawingChanged`:

```swift
private func handleIsDrawingChanged() {
    if store.isDrawing {
        overlayController?.show()
        toolbarController?.show()
    } else {
        overlayController?.hide()
        toolbarController?.hide()
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
git add strokekit/AppDelegate.swift
git commit -m "feat(app): wire ToolbarWindowController to drawing-mode toggle"
```

---

## Task 16: Manual QA — full v0.5 flow

- [ ] **Step 1: Build and run**

`⌘R`. App launches; ✏️ in menu bar.

- [ ] **Step 2: Verify each tool in order**

Toggle drawing mode (`⌘⇧⌥7` per current build, or whatever hotkey is wired). Toolbar should appear.

For each tool, switch to it via the toolbar then verify:

1. **Pen** — drag → red freehand line.
2. **Highlighter** — drag → wider, semi-transparent stroke. Overlapping strokes deepen color.
3. **Line** — drag → straight line preview follows cursor. Release → committed.
4. **Arrow** — drag → line with arrowhead at end point. Preview updates.
5. **Rectangle** — drag → rectangle outline preview.
6. **Circle** — drag → ellipse outline preview.
7. **Text** — click → text field appears with cursor active. Type "hello", press Enter → text committed in current color.
8. **Counter** — click 3 times in different spots → numbered circles 1, 2, 3.
9. **Eraser** — click on any drawn shape → it disappears. Click empty space → nothing happens.

- [ ] **Step 3: Verify color palette**

- Click each of the 8 swatches. Selected swatch shows accent ring. Next stroke uses that color.
- Click "More…" → `NSColorPanel` opens. Pick custom color → next stroke uses it.

- [ ] **Step 4: Verify line widths**

Draw with each of 2 / 4 / 6 / 10pt. Visible difference for pen and shapes; highlighter scales proportionally.

- [ ] **Step 5: Verify whiteboard**

Click whiteboard button → overlay fills white. Existing strokes still visible on top of white. Toggle off → returns to transparent.

- [ ] **Step 6: Verify undo / redo / clear**

Draw 3 strokes. `⌘Z` undoes last, `⇧⌘Z` redoes. Toolbar's undo/redo/trash buttons mirror keyboard. Trash clears all and resets counter to 1.

- [ ] **Step 7: Verify toolbar drag + position memory**

Drag the toolbar (top grip area) to the bottom-right corner. Toggle drawing mode off then on → toolbar re-appears at the same spot.

- [ ] **Step 8: Verify counter undo behavior**

Place 3 counters (numbered 1, 2, 3). `⌘Z` → 3 disappears, next click would be 3 again. Redo → 3 reappears.

- [ ] **Step 9: Edge cases**

- Switch tool mid-drag (rare but possible) — drag completes with the original tool.
- Click eraser on a counter → counter shape disappears (numbering of survivors is unchanged — that's the intended behavior; renumbering is out of scope for v0.5).
- Open NSColorPanel, close it, then switch tools → no crash.

If any step fails, fix before tagging.

- [ ] **Step 10: Commit any fixes**

If you patched something, commit with a `fix(...)` message referring to what failed.

---

## Task 17: Update README

**Files:**
- Modify: `README.md`

Update the feature list to v0.5.

- [ ] **Step 1: Replace the "v0.1 features" section**

```markdown
## v0.5 features

- Menu bar app — no Dock icon
- `⌘⇧⌥7` (configurable in v1.0) to toggle drawing mode anywhere
- 9 tools: pen, highlighter, line, arrow, rectangle, circle, text, counter, eraser
- 8-color palette + custom picker
- 4 line widths (2/4/6/10pt)
- Whiteboard mode (toggle to draw on a white canvas)
- Floating toolbar — drag to reposition; position remembered
- Undo / redo / clear all (`⌘Z` / `⇧⌘Z` / toolbar trash)
- Object-based eraser (click a shape to remove it)
- Drawings persist across drawing-mode toggles
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README to v0.5 feature set"
```

---

## Task 18: Tag v0.5.0

- [ ] **Step 1: Verify all tests pass**

`⌘U`. All `DrawingStoreTests`, `ShapeRendererTests`, `ShapeHitTesterTests`, `ScreenManagerTests` pass.

- [ ] **Step 2: Clean build**

`⇧⌘K` then `⌘B`. No errors, ideally no warnings.

- [ ] **Step 3: Tag**

```bash
git tag -a v0.5.0 -m "v0.5.0: full Bandicam-parity tool set + floating toolbar

- 9 tools: pen, highlighter, line, arrow, rectangle, circle, text, counter, eraser
- Color palette: 8 presets + NSColorPanel
- Line width: 4 presets
- Whiteboard mode
- Floating toolbar (NSPanel) with position memory
- Object-based eraser
- Counter with undo-aware numbering

Plan 2 of 3 from docs/superpowers/plans/2026-05-01-strokekit-v0.5.md complete."
```

- [ ] **Step 4: Verify**

```bash
git tag --list
# v0.1.0, v0.5.0
```

---

## Done

v0.5 brings strokekit to feature parity with Bandicam/Annotate's drawing tools.

**Plan 3 (`2026-XX-XX-strokekit-v1.0.md`)** will add:
- `PreferencesStore` + Settings UI (SwiftUI)
- Toolbar mode picker: floating vs dropdown (`NSPopover`)
- First-run welcome popover
- Customizable global hotkey
- Per-tool keyboard shortcuts (P / H / L / A / R / C / T / N / E)
- `Info.plist` polish, app icon, About panel
- Code signing + notarization
- Personal Homebrew tap (`leevigong/homebrew-strokekit`)
- Submit PR to `homebrew/homebrew-cask`
