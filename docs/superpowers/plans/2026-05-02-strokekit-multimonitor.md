# strokekit Multi-Monitor Follow Plan

> Drafted 2026-05-02 to be executed in v1.0 (post-Settings UI). Architecture
> approved by user (옵션 A 절충안): one virtual canvas, toolbar follows the
> cursor, drawings stored in absolute global coordinates.

## Goal

When the user toggles drawing mode on a multi-monitor setup, they should be
able to draw on **any** screen without re-toggling. Drawings stay anchored to
their physical location even when the cursor moves between screens.

## Approach

| Layer | Decision |
|-------|----------|
| Overlay window | One transparent `NSWindow` covering the union of all `NSScreen.frames` |
| Toolbar position (default) | The screen containing the cursor at the moment of activation |
| Drawing coordinates | Absolute global coordinates (`NSScreen` global space, origin at primary screen's bottom-left) |
| Menu bar handling | Each `NSScreen` has its own menu bar; subtract each one when drawing the whiteboard fill |
| Inter-screen gaps | Coordinates already account for them; clicks in gaps fall through harmlessly because no `NSScreen` reports a hit |

## Architecture changes

### 1. `ScreenManager`
Add helpers:
```swift
static func unionFrame(of screens: [NSScreen] = NSScreen.screens) -> CGRect
static func menuBarRects(for screens: [NSScreen] = NSScreen.screens) -> [CGRect]
```

`unionFrame` = `NSScreen.screens.reduce(.null) { $0.union($1.frame) }`.
`menuBarRects` returns one rect per screen for the menu bar strip
(`NSRect(x: screen.frame.minX, y: screen.visibleFrame.maxY,
         width: screen.frame.width, height: screen.frame.maxY - screen.visibleFrame.maxY)`).

### 2. `OverlayWindowController.show()`
Replace the single-screen frame with `ScreenManager.unionFrame()`.
Pass the menu bar rects into `DrawingCanvasView` so it can punch holes in the
whiteboard fill.

### 3. `DrawingCanvasView.draw(_:)`
When `store.isWhiteboard`:
- Fill `bounds`
- For each menu bar rect (converted into view coordinates), `ctx.clear(rect)` to leave the menu bar visible.

### 4. `ToolbarWindowController` default position
Already uses `ScreenManager.screenWithCursor()`'s frame for its anchor —
keep this. The toolbar always opens on the cursor's screen even though the
overlay covers everything.

### 5. Drawing coordinate system
Store/render shapes already use canvas-local coordinates. Because the canvas
now spans `unionFrame()`, "canvas-local" = "global minus unionFrame.origin".
This is automatic from `convert(event.locationInWindow, from: nil)` because
the window covers the whole virtual screen.

No changes needed to `Shape` enum or `ShapeRenderer`.

### 6. Pass-through and click-through
`OverlayWindow.ignoresMouseEvents` toggling already works at the window level.
Confirmed correct for multi-screen.

## Edge cases to test

- **Screen disconnected mid-session.** Listen for `NSApplication.didChangeScreenParametersNotification`; on fire, hide & re-show the overlay so it picks up the new union frame. Drawings outside the new frame are kept in the store but invisible.
- **Resolution change / display arrangement change.** Same notification as above.
- **Sidecar / AirPlay mid-session.** `NSScreen.screens` updates; same handler.
- **Notch on the cursor's screen.** Already handled by `screen.visibleFrame` math.
- **Mission Control invocation.** `.canJoinAllSpaces` + `.popUpMenu` levels already coexist with Mission Control — verified for v0.5.

## Tasks

1. Add `ScreenManager.unionFrame()` + `menuBarRects()` (TDD with mock screens).
2. Update `OverlayWindowController.show()` to use union frame.
3. Update `DrawingCanvasView.draw(_:)` to clear menu bar rects when whiteboard is on.
4. Wire `NSApplication.didChangeScreenParametersNotification` in `OverlayWindowController` → re-show overlay if drawing mode is active.
5. Manual QA on a dual-monitor setup: pen, shapes, text, eraser, whiteboard, pass-through, undo/redo across screens.
6. Update `docs/strokekit-overview.md` with the new behavior.
7. Tag `v0.6.0`.

## Out of scope

- Per-screen drawing layers (different drawings on each monitor) — global coords are enough for v1.
- Smooth animation of toolbar between screens.
- Per-screen pass-through (whole overlay toggles together).
