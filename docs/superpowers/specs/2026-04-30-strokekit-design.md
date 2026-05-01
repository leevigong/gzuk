# strokekit — Design Spec

**Date:** 2026-04-30
**Status:** Draft v2 — pending user review
**Bundle ID:** `com.leevigong.strokekit`

## Summary

A free, open-source macOS app for drawing on top of any screen content — the standalone "drawing on screen" feature from Bandicam, without the recording. Distributed via Homebrew.

## Motivation

Existing options fall short:

- **DrawPen** (Homebrew) — lacks shape tools (rectangle, circle, etc.)
- **Pensela** — archived since 2022, removed from Homebrew
- **Annotate** (epilande) — has all the tools but UX problems:
  - Tools are buried in a menu bar dropdown (not discoverable, every tool change requires opening menu)
  - Default Drawing Mode is "Fade" (lines disappear) — must press Space every session to persist
  - Not on Homebrew

strokekit fixes those three issues while matching feature parity.

## Goals (v1.0)

- Match Bandicam / Annotate drawing tool set
- Floating icon-based toolbar (always visible during drawing) — *not* a text dropdown
- Default Persist mode (drawings stay until cleared)
- Distributable via Homebrew

## Non-Goals

- Screen recording (Bandicam's other half) — out of scope
- Cross-platform (macOS only)
- Cloud sync, sharing
- Save drawings to file (deferred to v0.2)

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Language | Swift 5.9+ |
| UI (toolbar, settings) | SwiftUI |
| UI (drawing canvas) | AppKit (`NSView` + `CGContext`) for performance |
| Window management | AppKit (`NSWindow`, `NSPanel`, `NSPopover`) |
| Global hotkey | [`soffes/HotKey`](https://github.com/soffes/HotKey) Swift Package |
| Persistence | `UserDefaults` (settings), in-memory (drawings) |
| Min macOS | 14.0 (Sonoma) — required for `@Observable` macro |
| Build | Xcode 15+ |

**Hybrid SwiftUI + AppKit rationale:** SwiftUI for everything that benefits from declarative state (toolbar, settings). AppKit `NSView` for the drawing canvas, where freehand pen drawing must stay smooth at 60fps.

---

## Feature Scope (v1.0 MVP)

Drawing tools matching Bandicam:

- Pen (freehand)
- Highlighter (semi-transparent freehand)
- Line (straight)
- Arrow
- Rectangle
- Circle / Ellipse
- Text
- Counter (sequential numbered circles)
- Eraser
- Undo / Redo
- Color picker
- Line width selector
- Whiteboard mode — toggle that fills the overlay with a solid color (white or black) so drawings are visible without underlying screen content
- Color palette: 8 preset swatches (red, orange, yellow, green, blue, purple, white, black) + "More…" button opening `NSColorPanel`. No recent-colors history in v1.

UX behaviors:

- **Activation:** Menu bar icon click + global shortcut (`⌘⇧D`, fixed in v1) — both work
- **Toolbar mode:** User selects in Settings:
  - **Dropdown** — toolbar appears as `NSPopover` anchored to menu bar icon
  - **Floating** — toolbar appears as draggable `NSPanel`, position remembered between sessions
- **Drawing persistence:** Drawings restored when overlay re-toggled (not cleared on hide)
- **Monitor:** Overlay shown on the screen containing the mouse cursor at the moment of activation. If the cursor moves to another screen mid-session, the overlay does **not** follow — user must toggle off and on to switch screens. (This avoids the surprise of the canvas jumping; a future "follow cursor" mode can be a setting.)
- **Default mode:** Persist (drawings don't fade)
- **Click handling:** While drawing mode is on, the overlay captures all mouse events on its screen (clicks don't reach apps below). To interact with apps below, toggle drawing mode off. (An "interactive" pass-through mode is a future enhancement.)

---

## Architecture

### App form

Menu bar–only app (`LSUIElement = true` in `Info.plist`). No Dock icon, no main window. Always resident in the menu bar with a ✏️ status item.

### Top-level windows

Two windows are created when drawing mode is activated:

1. **OverlayWindow** — transparent `NSWindow` at `.floating` window level (`NSWindow.Level.floating`, raw value 3) covering the active screen. Captures all mouse events while drawing mode is on. `ignoresMouseEvents = false` while active. Uses `.borderless` style mask, `backgroundColor = .clear`, `isOpaque = false`.
2. **ToolbarWindow** — either an `NSPopover` (Dropdown mode) or an `NSPanel` (Floating mode) at `.popUpMenu` level (raw value 101) — strictly above the overlay so it's never occluded by ongoing drawing. Renders the SwiftUI toolbar via `NSHostingView`.

We deliberately avoid `.statusBar` and `.mainMenu` levels (system-reserved). `.popUpMenu` is the documented "above floating, below screensaver" tier.

### Component map

| Component | Role | File |
|-----------|------|------|
| `AppDelegate` | App lifecycle, wires components | `App/AppDelegate.swift` |
| `StatusItemController` | Menu bar icon + menu | `MenuBar/StatusItemController.swift` |
| `HotkeyManager` | Global hotkey registration via `HotKey` | `MenuBar/HotkeyManager.swift` |
| `OverlayWindowController` | Lifecycle of the transparent overlay | `Overlay/OverlayWindowController.swift` |
| `OverlayWindow` | `NSWindow` subclass (transparent, floating) | `Overlay/OverlayWindow.swift` |
| `DrawingCanvasView` | `NSView` — receives mouse events, renders shapes via `CGContext` | `Overlay/DrawingCanvasView.swift` |
| `ToolbarWindowController` | Lifecycle of toolbar (popover or panel) | `Toolbar/ToolbarWindowController.swift` |
| `ToolbarView` | SwiftUI — tool buttons, color, width | `Toolbar/ToolbarView.swift` |
| `ColorPickerView` | SwiftUI — color palette + custom picker | `Toolbar/ColorPickerView.swift` |
| `LineWidthSlider` | SwiftUI — width slider | `Toolbar/LineWidthSlider.swift` |
| `DrawingStore` | `@Observable` — single source of truth (shapes, current tool, undo/redo) | `Drawing/DrawingStore.swift` |
| `Tool` | enum (`pen`, `highlighter`, `line`, `arrow`, `rectangle`, `circle`, `text`, `counter`, `eraser`) | `Drawing/Tool.swift` |
| `Shape` | enum representing one drawn item | `Drawing/Shape.swift` |
| `ShapeRenderer` | Renders a `Shape` to a `CGContext` | `Drawing/ShapeRenderer.swift` |
| `PreferencesStore` | Wraps `UserDefaults` (toolbar mode, hotkey, default color/width) | `Preferences/PreferencesStore.swift` |
| `PreferencesView` | SwiftUI — settings window | `Preferences/PreferencesView.swift` |
| `ScreenManager` | Detects which `NSScreen` contains the mouse | `Utils/ScreenManager.swift` |

### Key data types

```swift
enum Tool {
    case pen, highlighter, line, arrow, rectangle, circle, text, counter, eraser
}

enum Shape {
    case freehand(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    case highlighter(points: [CGPoint], color: NSColor, lineWidth: CGFloat)
    case line(from: CGPoint, to: CGPoint, color: NSColor, lineWidth: CGFloat)
    case arrow(from: CGPoint, to: CGPoint, color: NSColor, lineWidth: CGFloat)
    case rectangle(rect: CGRect, color: NSColor, lineWidth: CGFloat, filled: Bool)
    case circle(rect: CGRect, color: NSColor, lineWidth: CGFloat, filled: Bool)
    case text(origin: CGPoint, string: String, font: NSFont, color: NSColor)
    case counter(center: CGPoint, number: Int, color: NSColor)
}

@Observable
final class DrawingStore {
    var shapes: [Shape] = []
    var currentTool: Tool = .pen
    var currentColor: NSColor = .systemRed
    var currentLineWidth: CGFloat = 3
    var isDrawing: Bool = false

    private var undoStack: [[Shape]] = []
    private var redoStack: [[Shape]] = []

    func toggle() { ... }
    func beginShape(at point: CGPoint) { ... }
    func appendPoint(_ point: CGPoint) { ... }
    func commitShape() { ... }      // pushes to undoStack
    func undo() { ... }
    func redo() { ... }
    func clear() { ... }
}
```

### State ownership and observation

`DrawingStore` is the **single source of truth**. Mutations go through `DrawingStore` methods only — no direct field writes from outside.

Observation differs by UI layer:

- **SwiftUI views** (`ToolbarView`, `PreferencesView`) — automatic. SwiftUI integrates with `@Observable` natively; reading any tracked property inside a `body` registers it.
- **AppKit views** (`DrawingCanvasView`) — *not* automatic. The view manually subscribes by calling `withObservationTracking(_:onChange:)` (Observation framework, macOS 14+) inside its `viewDidMoveToWindow` / a re-arming closure:

  ```swift
  func observeStore() {
      withObservationTracking {
          _ = store.shapes
          _ = store.currentTool   // any properties we care about
      } onChange: { [weak self] in
          DispatchQueue.main.async {
              self?.needsDisplay = true
              self?.observeStore()    // re-arm after each fire
          }
      }
  }
  ```

  `withObservationTracking` fires once per change, so re-arming inside `onChange` is required. This is the documented Apple pattern for AppKit + `@Observable`.

### Window level / mouse event handling

The overlay window is created with `acceptsMouseMovedEvents = true` and `ignoresMouseEvents = false`. Toggling drawing mode off **closes** the overlay window (not just hides) — there's no "overlay shown but click-through" state in v1. This keeps the mental model simple and avoids the surprise of phantom invisible mouse capture.

The toolbar `NSPanel` is created with:
```swift
panel.level = .popUpMenu
panel.isFloatingPanel = true
panel.becomesKeyOnlyIfNeeded = true   // doesn't steal focus
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

For drag-to-move, the toolbar's SwiftUI root view defines a small grip area at the top edge (4pt tall, full width). A custom `DragHandleView` (NSView subclass) is overlaid on the SwiftUI content via `NSViewRepresentable` — it implements `mouseDown` / `mouseDragged` to call `panel.performDrag(with:)`. `isMovableByWindowBackground = true` alone is unreliable when SwiftUI hit-testing intercepts events.

---

## UX Specifications

### Eraser
**Object-based** (delete whole shape, not pixel erase). On `mouseDown`, find the topmost `Shape` whose hit region contains the click point and remove it. Hit testing uses the shape's stroke + fill region with a 4pt tolerance for thin strokes. The removal is one undoable operation per click. Pixel-level erasing is not in v1.

### Text
1. User selects Text tool, clicks on canvas at point P
2. An inline `NSTextField` is added to the canvas overlay at P with cursor active
3. User types
4. **Commit** on `Enter` (or click outside) → text becomes a `Shape.text`, field removed
5. **Cancel** on `Esc` → field removed, no shape added
6. Font is a fixed system font for v1; size scales with current line width

### Counter
- Each click while Counter tool is active places a numbered circle and increments the counter
- Counter starts at 1 and persists across drawing-mode toggles (until cleared)
- **Reset to 1** on `Clear All`
- **Undo** of a counter click decrements; **Redo** re-increments
- Shape stores its number so re-rendering after undo is stable

### Whiteboard mode
- Toggleable via toolbar button (separate from tool selection — it's a layer, not a tool)
- When on, the overlay paints its background a solid color (white by default; black is the alternative — toggle in Settings)
- Drawings render on top of the solid color
- Toggling off restores transparent overlay (drawings unchanged)

### Color palette
- 8 preset swatches in the toolbar: red, orange, yellow, green, blue, purple, white, black
- "More…" button opens `NSColorPanel` (system color picker)
- Currently-selected color shown highlighted in the swatch row
- Per-tool color memory is **not** in v1 — color is global

### Line width
- 4 preset widths shown as dot-size icons: 2pt, 4pt, 6pt, 10pt
- Custom width via slider in Settings (1–24pt)

### First-run experience
1. App launches, status item appears in menu bar
2. A welcome `NSPopover` opens automatically from the status item:
   > **Welcome to strokekit**
   > Press `⌘⇧D` anywhere to start drawing on your screen.
   > Click ✏️ in the menu bar for tools and settings.
   > [Got it]
3. On first activation of drawing mode, macOS prompts for **Accessibility** permission (required by `HotKey` for global shortcut). If denied, the menu bar icon click still works as fallback.
4. **Screen Recording permission is not requested in v1** — the overlay doesn't read pixels.

---

## Data Flow

### Toggling drawing mode (⌘⇧D)

```
HotkeyManager
  → DrawingStore.toggle()
    → isDrawing = true
    → OverlayWindowController.show()
        - ScreenManager finds screen with mouse
        - creates NSWindow at that screen's frame
        - .floating level, opaque = false
        - mounts DrawingCanvasView (re-renders existing shapes)
    → ToolbarWindowController.show()
        - reads PreferencesStore.toolbarMode
        - Dropdown → NSPopover anchored to status item
        - Floating → NSPanel at last remembered position
        - mounts ToolbarView (SwiftUI)
```

### Drawing a freehand stroke

```
User mouse-drags on canvas
  → DrawingCanvasView.mouseDown(at: p1)
    → DrawingStore.beginShape(at: p1)
  → DrawingCanvasView.mouseDragged(at: p2..pN)
    → DrawingStore.appendPoint(pN)
    → canvas.needsDisplay = true (incremental redraw)
  → DrawingCanvasView.mouseUp
    → DrawingStore.commitShape()  // push to undoStack
```

### Tool change

```
User taps ▭ in toolbar
  → ToolbarView (SwiftUI button action)
    → DrawingStore.currentTool = .rectangle
      → SwiftUI auto-tracks: ToolbarView re-renders (highlight)
      → DrawingCanvasView's withObservationTracking fires:
          - re-arm tracking
          - update NSCursor
          (no needsDisplay — shapes didn't change)
```

### Undo

```
⌘Z pressed
  → HotkeyManager (or NSResponder chain when toolbar focused)
    → DrawingStore.undo()
      - pop last commit from undoStack
      - push to redoStack
      - shapes updated
    → canvas.needsDisplay = true
```

### Disabling drawing mode

```
⌘⇧D again or status item click
  → DrawingStore.toggle()
    → isDrawing = false
    → OverlayWindowController.hide()  // window closed; shapes retained in store
    → ToolbarWindowController.hide()
```

When re-toggled, shapes are restored unchanged (Q5 = restored).

---

## Project Layout

```
strokekit/
├── strokekit.xcodeproj/
├── strokekit/
│   ├── App/
│   │   ├── strokekitApp.swift
│   │   ├── AppDelegate.swift
│   │   └── Info.plist
│   ├── MenuBar/
│   │   ├── StatusItemController.swift
│   │   └── HotkeyManager.swift
│   ├── Overlay/
│   │   ├── OverlayWindowController.swift
│   │   ├── OverlayWindow.swift
│   │   └── DrawingCanvasView.swift
│   ├── Toolbar/
│   │   ├── ToolbarWindowController.swift
│   │   ├── ToolbarView.swift
│   │   ├── ColorPickerView.swift
│   │   └── LineWidthSlider.swift
│   ├── Drawing/
│   │   ├── DrawingStore.swift
│   │   ├── Tool.swift
│   │   ├── Shape.swift
│   │   └── ShapeRenderer.swift
│   ├── Preferences/
│   │   ├── PreferencesStore.swift
│   │   └── PreferencesView.swift
│   ├── Utils/
│   │   └── ScreenManager.swift
│   └── Assets.xcassets/
├── strokekitTests/
│   ├── DrawingStoreTests.swift
│   ├── ShapeRendererTests.swift
│   └── ScreenManagerTests.swift
├── README.md
├── LICENSE              (MIT)
└── .gitignore
```

External dependencies: only `soffes/HotKey` (Swift Package, MIT).

---

## Testing Strategy

Unit tests focus on logic that isn't tied to window/drawing:

- `DrawingStoreTests` — tool changes, shape add/commit, undo/redo, clear, color/width state
- `ShapeRendererTests` — geometry/path construction (use mock `CGContext` or snapshot the resulting `CGPath`)
- `PreferencesStoreTests` — round-trip through `UserDefaults`
- `ScreenManagerTests` — given mouse coords + mock screens, returns the expected `NSScreen`

Manual QA covers what unit tests can't:

- Overlay window appears on the correct monitor, captures mouse
- Drawing remains smooth at 60fps
- Toolbar mode switching (Dropdown ↔ Floating)
- Global hotkey works while focus is in another app
- Mission Control / Stage Manager interactions

TDD is the default for `DrawingStore` and `ShapeRenderer`.

---

## Distribution

Three-stage rollout:

### v0.1 — GitHub Releases (unsigned)
- `.dmg` or `.zip` posted to GitHub Releases
- Users right-click → Open the first time to bypass Gatekeeper
- Sufficient for personal use and early adopters

### v0.5 — Personal Homebrew tap
- Separate `homebrew-strokekit` repo
- `Casks/strokekit.rb` (Ruby DSL) pointing at the latest GitHub Release
- `brew tap leevigong/strokekit && brew install --cask strokekit`

### v1.0 — Official Homebrew Cask
- Submit PR to `homebrew/homebrew-cask` once there's some user base
- `brew install --cask strokekit` works without a tap

### Optional: Apple Developer Program ($99/yr)
- Code signing + notarization → no Gatekeeper warning
- Recommended for v1.0+, skipped for MVP

---

## Risks

1. **Accessibility permission** — required for global hotkey via `HotKey`. Handled by system prompt on first hotkey use; spec explicitly handles fallback (menu bar click) when denied.
2. **Screen Recording permission** — transparent `NSWindow` doesn't require it. Only needed if a future feature reads pixels (eyedropper, PNG export). Not in v1.
3. **Hotkey conflict (`⌘⇧D`)** — possible collision with other apps' shortcuts. v1 is fixed; v0.2 adds user-customizable hotkey in Settings.
4. **Window level / Mission Control** — `.popUpMenu` (101) is below screensaver but above floating, so Mission Control will properly hide the overlay during the gesture. Verified pattern.
5. **Screen disconnect during drawing** — observe `NSApplication.didChangeScreenParametersNotification`. If the overlay's screen is removed, hide drawing mode and notify.
6. **`@Observable` re-arming** — `withObservationTracking` fires once; forgetting to re-arm is a common bug. Centralize in a single helper method on `DrawingCanvasView`.

These will be resolved as encountered; none block the architecture.

---

## Roadmap (post v1.0)

**v0.2**
- Save drawings to PNG (`⌘S`)
- User-customizable global hotkey (Settings)
- Per-tool keyboard shortcuts (`P` for pen, `R` for rectangle, etc.)
- Recent colors history

**v0.3**
- "Interactive overlay" pass-through mode (draw above apps you can still click)
- Custom whiteboard background colors
- Multi-monitor "follow cursor" option

**v0.5**
- Personal Homebrew tap published

**v1.0**
- Code signing + notarization (requires Apple Developer)
- Submit to official `homebrew/homebrew-cask`

---

## Decisions Log (from brainstorm)

| # | Question | Choice |
|---|----------|--------|
| Q1 | MVP scope | D — full Bandicam/Annotate parity |
| Q2 | Tech stack | Swift + SwiftUI/AppKit hybrid |
| Q3 | Swift experience | B — beginner Swift, knows other languages |
| Q4 | Activation | C — menu bar icon + global shortcut |
| Q5 | Drawings on toggle off | b — restored when re-toggled |
| Q6 | Multi-monitor | a — only the screen with mouse |
| Q7 | File save | C — deferred to v0.2 |
| Approach | SwiftUI vs AppKit | B — hybrid (SwiftUI UI, AppKit canvas) |
| Hotkey lib | Carbon vs HotKey | HotKey package |
| Toolbar UX | Dropdown vs Floating | **Both** (user selects in Settings) |

---

## Assets

- **Menu bar icon**: SF Symbol `pencil.tip` rendered as template image (auto-tints with menu bar)
- **Dock icon**: hidden (`LSUIElement = true`) but still required by Xcode — ship a 1024×1024 placeholder PNG of the same pencil-tip glyph for v1.0; refine later
- **App name in About**: "strokekit"
- **Bundle ID**: `com.leevigong.strokekit`
- **License**: MIT — `LICENSE` file in repo root

## README outline

The repo `README.md` covers:
1. One-line description
2. Screenshot / demo GIF
3. Install (Homebrew once published; `.dmg` in the meantime)
4. Quick start (`⌘⇧D`)
5. Feature list
6. Differences from DrawPen / Annotate
7. Build from source
8. Contributing
9. License
