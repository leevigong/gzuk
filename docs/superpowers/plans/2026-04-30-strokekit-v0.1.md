# strokekit v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the smallest working version of strokekit — a macOS menu bar app where pressing `⌘⇧D` shows a transparent overlay on the screen with the mouse cursor; the user can draw red freehand pen strokes; pressing `⌘⇧D` again hides the overlay; re-toggling restores the drawings.

**Architecture:** Swift menu bar app (`LSUIElement = true`). Hybrid SwiftUI + AppKit: AppKit for window/canvas (`NSWindow`, `NSView` + `CGContext`), no SwiftUI in v0.1 (toolbar comes in Plan 2). Single `@Observable` `DrawingStore` is the source of truth; the AppKit canvas observes via `withObservationTracking` with re-arming pattern.

**Tech Stack:** Swift 5.9+, AppKit, Observation framework, [`soffes/HotKey`](https://github.com/soffes/HotKey) Swift Package, Xcode 15+, macOS 14+ target.

**Spec reference:** `docs/superpowers/specs/2026-04-30-strokekit-design.md`

**v0.1 scope (subset of full spec):**
- Pen tool only (no other tools)
- Fixed red color, fixed 3pt width
- ⌘⇧D global hotkey + menu bar icon click both toggle drawing mode
- Drawings restored across toggles (in-memory)
- Undo/Redo with `⌘Z` / `⇧⌘Z`
- Single-monitor; cursor's screen at activation time
- No floating toolbar yet (overlay just captures input directly)
- No settings, no whiteboard, no other tools

---

## File Structure

Files created in this plan, with single responsibility each:

```
strokekit/
├── strokekit.xcodeproj/                    (created by Xcode)
├── strokekit/
│   ├── AppDelegate.swift                   (wires status item + hotkey + overlay)
│   ├── Info.plist                          (LSUIElement = true)
│   ├── MenuBar/
│   │   ├── StatusItemController.swift      (NSStatusItem + menu)
│   │   └── HotkeyManager.swift             (HotKey wrapper)
│   ├── Overlay/
│   │   ├── OverlayWindow.swift             (NSWindow subclass: transparent, floating)
│   │   ├── OverlayWindowController.swift   (show/hide overlay on active screen)
│   │   └── DrawingCanvasView.swift         (NSView: mouse + draw)
│   ├── Drawing/
│   │   ├── DrawingStore.swift              (@Observable single source of truth)
│   │   ├── Tool.swift                      (enum: .pen)
│   │   ├── Shape.swift                     (enum: .freehand only)
│   │   └── ShapeRenderer.swift             (Shape → CGContext drawing)
│   └── Utils/
│       └── ScreenManager.swift             (which NSScreen has the cursor)
├── strokekitTests/
│   ├── DrawingStoreTests.swift
│   ├── ShapeRendererTests.swift
│   └── ScreenManagerTests.swift
├── README.md
├── LICENSE                                 (MIT)
└── .gitignore                              (Xcode standard)
```

**TDD applies to:** `Tool`, `Shape`, `ShapeRenderer`, `DrawingStore`, `ScreenManager` — pure logic, easy to test in isolation.

**Manual QA only:** `OverlayWindow`, `DrawingCanvasView`, `StatusItemController`, `HotkeyManager` — tightly coupled to AppKit windowing; testing via XCUITest is overkill for v0.1.

---

## Task 1: Create Xcode project + add HotKey package

**Files:**
- Create: `strokekit.xcodeproj/` (via Xcode UI)
- Modify: `strokekit/Info.plist`

The `.gitignore` is already created in the repo root.

This is the only manual-Xcode-UI task. Everything afterward is code.

- [ ] **Step 1: Create the project in Xcode**

Open Xcode → File → New → Project. **Critically: pick the macOS tab at the top, NOT iOS.** Select **App** → Next.

- Product Name: `strokekit`
- Team: (your dev team or None)
- Organization Identifier: `com.leevigong`
- Bundle Identifier: auto-fills to `com.leevigong.strokekit`
- Interface: **Storyboard** (not SwiftUI — current Xcode replaced "AppKit App Delegate" with "Storyboard")
- Language: **Swift**
- Testing System: **XCTest for Unit and UI Tests**
- Storage: **None**
- Host in CloudKit: off

Save inside `~/dev/gzuk/`. **Important:** when Xcode asks "Source Control: Create Git repository on my Mac" — **uncheck it** (we already have a git repo). When Xcode prompts about nesting (it might create `strokekit/strokekit/...`), use the file move steps in Step 1b below to flatten.

- [ ] **Step 1b: Verify and flatten if needed**

After saving, you should see this layout (ideal):
```
~/dev/gzuk/
├── .git/
├── docs/
├── strokekit.xcodeproj/
├── strokekit/
│   ├── AppDelegate.swift, Info.plist, etc.
└── strokekitTests/, strokekitUITests/
```

If Xcode nested everything one level deeper (`~/dev/gzuk/strokekit/strokekit.xcodeproj`), close Xcode and run from terminal:
```bash
cd ~/dev/gzuk
mv strokekit _xcode_tmp && mv _xcode_tmp/* . && rmdir _xcode_tmp
```

- [ ] **Step 2: Verify it's a macOS project, not iOS**

Open Xcode. Click strokekit (project) → strokekit (target) → General. Confirm:
- **Supported Destinations** must contain **Mac** (not iPhone/iPad/Vision)
- **Minimum Deployments** must say **macOS** with version (not iOS)

If you see iOS instead, you picked the wrong template. Close Xcode, delete everything except `.git/`, `docs/`, `.gitignore`, and start over from Step 1 picking the **macOS** category.

- [ ] **Step 3: Set deployment target to macOS 14**

Project navigator → strokekit (project) → strokekit (target) → General → Minimum Deployments → macOS **14.0**.

- [ ] **Step 4: Make it a menu-bar-only app (no Dock icon)**

Open `strokekit/Info.plist`. Click the `+` next to the last row to add a row:
- Key: `Application is agent (UIElement)`
- Type: `Boolean`
- Value: `YES`

(In raw XML this is `<key>LSUIElement</key><true/>`.)

Also delete from Info.plist if present:
- `Main storyboard file base name` (key: `NSMainStoryboardFile`)

In the target's General tab, set **Main Interface** to empty (delete `Main`).

Delete these files (Move to Trash) from the project navigator:
- `Main.storyboard`
- `ViewController.swift`
- `SceneDelegate.swift` (if present)

- [ ] **Step 5: Replace AppDelegate with a minimal stub**

Open `strokekit/AppDelegate.swift` and replace its contents with:

```swift
import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Wiring happens in Task 12
        NSLog("strokekit launched")
    }
}
```

- [ ] **Step 6: Add HotKey Swift Package**

In Xcode: File → Add Package Dependencies → enter URL:
```
https://github.com/soffes/HotKey
```
Dependency Rule: **Up to Next Major Version**, starting from `0.2.0`.
Add to target: **strokekit**.

- [ ] **Step 7: Build and run**

Press `⌘R` in Xcode. The app should build, launch, and **NOT show a window or Dock icon**. Check Console.app for the `strokekit launched` log message to confirm it's running.

- [ ] **Step 8: Commit**

```bash
cd ~/dev/gzuk
git add .
git commit -m "chore: scaffold macOS menu-bar-only Xcode project + add HotKey package"
```

---

## Task 2: Create `Tool` enum

**Files:**
- Create: `strokekit/Drawing/Tool.swift`

No test — it's a single-case enum for v0.1; tests come when more cases are added in Plan 2.

- [ ] **Step 1: Create the file**

In Xcode: right-click `strokekit/` group → New Group → name it `Drawing`. Then right-click `Drawing` → New File → Swift File → name `Tool.swift`. Replace contents with:

```swift
import Foundation

enum Tool: String, CaseIterable {
    case pen
    // More cases added in Plan 2 (highlighter, line, arrow, rectangle, circle, text, counter, eraser)
}
```

- [ ] **Step 2: Build to verify it compiles**

`⌘B`. Should succeed with no errors.

- [ ] **Step 3: Commit**

```bash
git add strokekit/Drawing/Tool.swift
git commit -m "feat(drawing): add Tool enum with .pen case"
```

---

## Task 3: Create `Shape` enum

**Files:**
- Create: `strokekit/Drawing/Shape.swift`

- [ ] **Step 1: Create the file**

Right-click `Drawing` group → New File → Swift File → name `Shape.swift`:

```swift
import AppKit

enum Shape: Equatable {
    case freehand(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    // More cases added in Plan 2
}
```

`Equatable` lets us assert shape equality in tests.

- [ ] **Step 2: Build**

`⌘B`. Must succeed.

- [ ] **Step 3: Commit**

```bash
git add strokekit/Drawing/Shape.swift
git commit -m "feat(drawing): add Shape enum with .freehand case"
```

---

## Task 4: Create `ShapeRenderer` (TDD)

**Files:**
- Create: `strokekit/Drawing/ShapeRenderer.swift`
- Test: `strokekitTests/ShapeRendererTests.swift`

`ShapeRenderer` converts a `Shape` to a `CGPath` we can stroke. Testing the path's bounding box is a quick way to verify geometry without rendering pixels.

- [ ] **Step 1: Write the failing test**

Create `strokekitTests/ShapeRendererTests.swift`:

```swift
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
```

- [ ] **Step 2: Run test — verify it fails**

In Xcode: `⌘U`. Expected failure: `Cannot find 'ShapeRenderer' in scope`.

- [ ] **Step 3: Implement `ShapeRenderer`**

Create `strokekit/Drawing/ShapeRenderer.swift`:

```swift
import AppKit

enum ShapeRenderer {
    /// Build a CGPath for the given shape. Stroking/filling is done by the caller.
    static func path(for shape: Shape) -> CGPath {
        switch shape {
        case .freehand(let points, _, _):
            let path = CGMutablePath()
            guard let first = points.first else { return path }
            path.move(to: first)
            for p in points.dropFirst() {
                path.addLine(to: p)
            }
            return path
        }
    }

    /// Stroke the shape into the given context using its color and line width.
    static func draw(_ shape: Shape, in ctx: CGContext) {
        let path = path(for: shape)
        guard !path.isEmpty else { return }

        switch shape {
        case .freehand(_, let color, let lineWidth):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.addPath(path)
            ctx.strokePath()
        }
    }
}
```

- [ ] **Step 4: Run test — verify it passes**

`⌘U`. Both tests pass.

- [ ] **Step 5: Commit**

```bash
git add strokekit/Drawing/ShapeRenderer.swift strokekitTests/ShapeRendererTests.swift
git commit -m "feat(drawing): add ShapeRenderer with freehand path + draw"
```

---

## Task 5: Create `DrawingStore` (TDD)

**Files:**
- Create: `strokekit/Drawing/DrawingStore.swift`
- Test: `strokekitTests/DrawingStoreTests.swift`

`DrawingStore` is the app's brain: it owns `shapes`, `currentTool`, `isDrawing`, undo/redo stacks, and exposes mutation methods. It uses `@Observable`.

- [ ] **Step 1: Write failing tests**

Create `strokekitTests/DrawingStoreTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests — verify they fail**

`⌘U`. All 7 fail with `Cannot find 'DrawingStore' in scope`.

- [ ] **Step 3: Implement `DrawingStore`**

Create `strokekit/Drawing/DrawingStore.swift`:

```swift
import AppKit
import Observation

@Observable
final class DrawingStore {
    private(set) var shapes: [Shape] = []
    var currentTool: Tool = .pen
    private(set) var isDrawing: Bool = false

    // v0.1: fixed color and width. Plan 2 makes these mutable.
    let currentColor: NSColor = .systemRed
    let currentLineWidth: CGFloat = 3

    private var undoStack: [[Shape]] = []
    private var redoStack: [[Shape]] = []

    // In-progress freehand points before commit
    private var inProgressPoints: [CGPoint] = []

    func toggle() {
        isDrawing.toggle()
    }

    func beginShape(at point: CGPoint) {
        inProgressPoints = [point]
    }

    func appendPoint(_ point: CGPoint) {
        inProgressPoints.append(point)
    }

    func commitShape() {
        guard inProgressPoints.count >= 1 else { return }
        let shape = Shape.freehand(points: inProgressPoints,
                                   color: currentColor,
                                   lineWidth: currentLineWidth)
        pushUndoSnapshot()
        shapes.append(shape)
        redoStack.removeAll()
        inProgressPoints = []
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(shapes)
        shapes = previous
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(shapes)
        shapes = next
    }

    func clear() {
        guard !shapes.isEmpty else { return }
        pushUndoSnapshot()
        shapes = []
        redoStack.removeAll()
    }

    /// Snapshot the current shape list for undo before mutating.
    private func pushUndoSnapshot() {
        undoStack.append(shapes)
        // Keep history bounded to avoid unbounded memory in long sessions
        if undoStack.count > 100 {
            undoStack.removeFirst(undoStack.count - 100)
        }
    }
}
```

- [ ] **Step 4: Run tests — verify they pass**

`⌘U`. All 7 pass.

- [ ] **Step 5: Commit**

```bash
git add strokekit/Drawing/DrawingStore.swift strokekitTests/DrawingStoreTests.swift
git commit -m "feat(drawing): add @Observable DrawingStore with undo/redo"
```

---

## Task 6: Create `ScreenManager` (TDD)

**Files:**
- Create: `strokekit/Utils/ScreenManager.swift`
- Test: `strokekitTests/ScreenManagerTests.swift`

`ScreenManager` answers "which `NSScreen` contains the mouse cursor right now?" We test by injecting a mock screen list and a mock mouse location.

- [ ] **Step 1: Write failing tests**

Create `strokekitTests/ScreenManagerTests.swift`:

```swift
import XCTest
import AppKit
@testable import strokekit

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
```

- [ ] **Step 2: Run tests — verify they fail**

`⌘U`. Fail: `Cannot find 'ScreenManager' / 'ScreenLike' in scope`.

- [ ] **Step 3: Implement `ScreenManager`**

Create `strokekit/Utils/ScreenManager.swift` (right-click strokekit → New Group → `Utils` first):

```swift
import AppKit

/// Minimal protocol exposing only what ScreenManager needs from NSScreen,
/// so we can inject mocks in tests.
protocol ScreenLike: AnyObject {
    var frame: CGRect { get }
}

extension NSScreen: ScreenLike {}

enum ScreenManager {
    /// Returns the screen whose frame contains the given point, or nil.
    static func screen(at point: CGPoint, in screens: [ScreenLike]) -> ScreenLike? {
        screens.first { $0.frame.contains(point) }
    }

    /// Convenience: real NSScreen.screens + current mouse location.
    static func screenWithCursor() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) }
    }
}
```

- [ ] **Step 4: Run tests — verify they pass**

`⌘U`. Both pass.

- [ ] **Step 5: Commit**

```bash
git add strokekit/Utils/ScreenManager.swift strokekitTests/ScreenManagerTests.swift
git commit -m "feat(utils): add ScreenManager to find screen under cursor"
```

---

## Task 7: Create `OverlayWindow`

**Files:**
- Create: `strokekit/Overlay/OverlayWindow.swift`

A `NSWindow` subclass set up as a transparent, click-through-disabled, floating overlay.

- [ ] **Step 1: Create the file**

Right-click `strokekit/` → New Group → `Overlay`. Inside, New File → Swift File → `OverlayWindow.swift`:

```swift
import AppKit

final class OverlayWindow: NSWindow {
    init(screenFrame: CGRect) {
        super.init(contentRect: screenFrame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,
                                   .stationary, .ignoresCycle]
        self.isReleasedWhenClosed = false
    }

    // Borderless windows must override these to accept key events (for ⌘Z, ⌘Q etc.)
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
```

- [ ] **Step 2: Build**

`⌘B`. Must succeed.

- [ ] **Step 3: Commit**

```bash
git add strokekit/Overlay/OverlayWindow.swift
git commit -m "feat(overlay): add transparent borderless OverlayWindow"
```

---

## Task 8: Create `DrawingCanvasView`

**Files:**
- Create: `strokekit/Overlay/DrawingCanvasView.swift`

The `NSView` that captures mouse and paints shapes. Observes the store via `withObservationTracking` and re-arms after each fire.

- [ ] **Step 1: Create the file**

Inside `Overlay/`, New File → Swift File → `DrawingCanvasView.swift`:

```swift
import AppKit
import Observation

final class DrawingCanvasView: NSView {
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
        if window != nil {
            armObservation()
        }
    }

    /// Re-arm withObservationTracking after each fire, otherwise it only fires once.
    private func armObservation() {
        withObservationTracking {
            _ = store.shapes
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
        for shape in store.shapes {
            ShapeRenderer.draw(shape, in: ctx)
        }
        // Render in-progress stroke (last point chain) so the user sees it live
        if !inProgressPoints.isEmpty {
            let preview = Shape.freehand(points: inProgressPoints,
                                         color: store.currentColor,
                                         lineWidth: store.currentLineWidth)
            ShapeRenderer.draw(preview, in: ctx)
        }
    }

    // MARK: - Mouse events

    private var inProgressPoints: [CGPoint] = []

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        inProgressPoints = [p]
        store.beginShape(at: p)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        inProgressPoints.append(p)
        store.appendPoint(p)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        store.commitShape()
        inProgressPoints = []
        // store change triggers redraw via observation
    }

    // MARK: - Keyboard (Undo/Redo)

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
git commit -m "feat(overlay): add DrawingCanvasView with mouse + observation"
```

---

## Task 9: Create `OverlayWindowController`

**Files:**
- Create: `strokekit/Overlay/OverlayWindowController.swift`

Owns the lifecycle: creates window + canvas on `show()`, closes on `hide()`. Picks the screen with the cursor.

- [ ] **Step 1: Create the file**

Inside `Overlay/`, New File → Swift File → `OverlayWindowController.swift`:

```swift
import AppKit

final class OverlayWindowController {
    private let store: DrawingStore
    private var window: OverlayWindow?
    private var canvas: DrawingCanvasView?

    init(store: DrawingStore) {
        self.store = store
    }

    func show() {
        guard window == nil else { return }
        guard let screen = ScreenManager.screenWithCursor() else {
            NSLog("strokekit: no screen contains cursor; aborting overlay")
            return
        }

        let win = OverlayWindow(screenFrame: screen.frame)
        let canvas = DrawingCanvasView(store: store,
                                       frame: CGRect(origin: .zero, size: screen.frame.size))
        canvas.autoresizingMask = [.width, .height]
        win.contentView = canvas
        win.makeFirstResponder(canvas)
        win.makeKeyAndOrderFront(nil)

        self.window = win
        self.canvas = canvas
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        canvas = nil
        // Note: store.shapes is preserved — restored on next show()
    }
}
```

- [ ] **Step 2: Build**

`⌘B`. Must succeed.

- [ ] **Step 3: Commit**

```bash
git add strokekit/Overlay/OverlayWindowController.swift
git commit -m "feat(overlay): add OverlayWindowController managing show/hide"
```

---

## Task 10: Create `StatusItemController`

**Files:**
- Create: `strokekit/MenuBar/StatusItemController.swift`

The menu bar ✏️ icon. Left-click toggles drawing; right-click opens a small menu with Quit.

- [ ] **Step 1: Create the file**

Right-click `strokekit/` → New Group → `MenuBar`. Inside, New File → Swift File → `StatusItemController.swift`:

```swift
import AppKit

final class StatusItemController {
    private let statusItem: NSStatusItem
    private let onToggle: () -> Void

    init(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pencil.tip",
                                   accessibilityDescription: "strokekit")
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            onToggle()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit strokekit",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Detach so subsequent left-clicks toggle instead of opening the menu
        statusItem.menu = nil
    }
}
```

- [ ] **Step 2: Build**

`⌘B`. Must succeed.

- [ ] **Step 3: Commit**

```bash
git add strokekit/MenuBar/StatusItemController.swift
git commit -m "feat(menubar): add StatusItemController with toggle + quit menu"
```

---

## Task 11: Create `HotkeyManager`

**Files:**
- Create: `strokekit/MenuBar/HotkeyManager.swift`

A thin wrapper around `HotKey`. Registers `⌘⇧D` and calls a callback.

- [ ] **Step 1: Create the file**

Inside `MenuBar/`, New File → Swift File → `HotkeyManager.swift`:

```swift
import HotKey
import AppKit

final class HotkeyManager {
    private var hotkey: HotKey?

    /// Registers ⌘⇧D and calls `onTrigger` when it fires.
    func register(onTrigger: @escaping () -> Void) {
        hotkey = HotKey(key: .d, modifiers: [.command, .shift])
        hotkey?.keyDownHandler = {
            onTrigger()
        }
    }

    func unregister() {
        hotkey = nil
    }
}
```

- [ ] **Step 2: Build**

`⌘B`. Must succeed (HotKey package added in Task 1).

- [ ] **Step 3: Commit**

```bash
git add strokekit/MenuBar/HotkeyManager.swift
git commit -m "feat(menubar): add HotkeyManager wrapping HotKey for ⌘⇧D"
```

---

## Task 12: Wire everything in `AppDelegate`

**Files:**
- Modify: `strokekit/AppDelegate.swift`

Now the app delegate constructs the store and the three controllers, and wires status item + hotkey to the store, and the store's `isDrawing` to the overlay controller.

- [ ] **Step 1: Replace AppDelegate**

Open `strokekit/AppDelegate.swift` and replace contents:

```swift
import Cocoa
import Observation

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = DrawingStore()
    private var statusItemController: StatusItemController?
    private var hotkeyManager: HotkeyManager?
    private var overlayController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlayController = OverlayWindowController(store: store)

        statusItemController = StatusItemController { [weak self] in
            self?.store.toggle()
        }

        hotkeyManager = HotkeyManager()
        hotkeyManager?.register { [weak self] in
            self?.store.toggle()
        }

        // Observe store.isDrawing → show/hide overlay
        observeIsDrawing()
    }

    private func observeIsDrawing() {
        withObservationTracking {
            _ = store.isDrawing
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.handleIsDrawingChanged()
                self?.observeIsDrawing()    // re-arm
            }
        }
    }

    private func handleIsDrawingChanged() {
        if store.isDrawing {
            overlayController?.show()
        } else {
            overlayController?.hide()
        }
    }
}
```

- [ ] **Step 2: Build and run**

`⌘R`. App launches, ✏️ appears in menu bar.

- [ ] **Step 3: Manual QA — full flow**

Verify in this order; if any step fails, debug before moving on:

1. **Menu bar icon visible.** ✏️ in menu bar, no Dock icon.
2. **Press `⌘⇧D`.** macOS prompts for Accessibility permission → grant it in System Settings → Privacy & Security → Accessibility (re-run app if needed).
3. **Press `⌘⇧D` again.** Cursor's screen should fill with a transparent overlay (visually it will look unchanged since it's transparent — verify by trying to click apps below — clicks should NOT pass through).
4. **Drag mouse on screen.** A red line should follow. Release. Line stays.
5. **Draw several strokes.**
6. **Press `⌘Z`.** Last stroke disappears.
7. **Press `⇧⌘Z`.** Stroke comes back.
8. **Press `⌘⇧D`.** Overlay vanishes; clicking apps works normally.
9. **Press `⌘⇧D` again.** Overlay reappears with all your previous strokes.
10. **Click ✏️ in menu bar (left-click).** Should toggle overlay (same as hotkey).
11. **Right-click ✏️.** Menu shows "Quit strokekit". Click it → app exits.

- [ ] **Step 4: Commit**

```bash
git add strokekit/AppDelegate.swift
git commit -m "feat(app): wire status item, hotkey, store, and overlay"
```

---

## Task 13: Add `README.md` and `LICENSE`

**Files:**
- Create: `README.md`
- Create: `LICENSE`

- [ ] **Step 1: Create LICENSE**

Create `~/dev/gzuk/LICENSE`:

```
MIT License

Copyright (c) 2026 leevigong

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Create README**

Create `~/dev/gzuk/README.md`:

```markdown
# strokekit

A free, open-source macOS app for drawing on top of any screen content. The standalone "draw on screen" feature from Bandicam, without the recording.

> **Status:** v0.1 — pen tool only. See [the design spec](docs/superpowers/specs/2026-04-30-strokekit-design.md) for the full v1.0 plan.

## Why

Existing options on macOS each have a gap:
- **DrawPen** — no shape tools (rectangle, circle)
- **Pensela** — archived since 2022, removed from Homebrew
- **Annotate** — has the tools, but tools are buried in a menu bar dropdown and drawings fade by default

strokekit aims to fill those gaps.

## v0.1 features

- Menu bar app — no Dock icon
- `⌘⇧D` to toggle drawing mode anywhere
- Red freehand pen, 3pt
- `⌘Z` / `⇧⌘Z` undo / redo
- Drawings persist across toggles

## Install (from source)

Requires Xcode 15+ and macOS 14+.

```bash
git clone https://github.com/leevigong/strokekit
cd strokekit
open strokekit.xcodeproj
```

Build and run with `⌘R`. On first launch grant Accessibility permission for the global hotkey.

## License

MIT — see [LICENSE](LICENSE).
```

- [ ] **Step 3: Commit**

```bash
git add README.md LICENSE
git commit -m "docs: add README and MIT LICENSE for v0.1"
```

---

## Task 14: Tag v0.1.0

- [ ] **Step 1: Verify all tests still pass**

In Xcode: `⌘U`. All tests across `DrawingStoreTests`, `ShapeRendererTests`, `ScreenManagerTests` pass.

- [ ] **Step 2: Verify the build is clean**

In Xcode: Product → Clean Build Folder (`⇧⌘K`), then `⌘B`. No warnings or errors.

- [ ] **Step 3: Tag**

```bash
git tag -a v0.1.0 -m "v0.1.0: pen-only MVP

- Menu bar app, no Dock
- ⌘⇧D global hotkey toggles drawing mode
- Single screen (cursor's screen) overlay
- Red 3pt freehand pen
- Undo / redo
- Drawings persist across toggles

Plan 1 of 3 from docs/superpowers/plans/2026-04-30-strokekit-v0.1.md complete."
```

- [ ] **Step 4: Verify**

```bash
git tag --list
# Should show: v0.1.0
git log --oneline | head -20
# Should show ~14 commits
```

---

## Done

v0.1 ships an end-to-end working app. Plan 2 (`2026-XX-XX-strokekit-v0.5.md`) adds the rest of the tools, color palette, width selector, and floating toolbar. Plan 3 (`2026-XX-XX-strokekit-v1.0.md`) adds Settings UI, first-run flow, and Homebrew distribution.
