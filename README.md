# 그려적어 (GZUK)

A free, open-source macOS app for drawing and writing directly on top of any screen — meetings, lectures, demos, code reviews. The standalone "draw on screen" feature from Bandicam, without the recording.

> **Status:** v0.9 — preparing for public release. Tracked in [docs/publishing-checklist.md](docs/publishing-checklist.md).

## Why

Existing options on macOS each have a gap:
- **DrawPen** — no shape tools (rectangle, circle)
- **Pensela** — archived since 2022, removed from Homebrew
- **Annotate** — has the tools, but they're buried in a menu bar dropdown and drawings fade by default

그려적어 aims to fill those gaps with a Korean-first design and a single-keystroke entry point.

## Features

- **Menu bar app** — no Dock icon, doesn't cover the menu bar. The 그적 status icon shows a red dot while drawing is active and dims to gray when our app loses focus, so you can see at a glance whether shortcuts will fire.
- **`⌃G` global hotkey** — toggle drawing from anywhere. Press it again while another app has focus to reclaim the overlay without turning drawing off.
- **9 tools** — pen, highlighter, line, arrow, rectangle, circle, text, counter, eraser. Single-letter shortcuts (P/H/L/A/R/C/T/N/E) work even with Korean IME on.
- **8-color palette** + **4 line widths** (counter circle scales with line width too).
- **Whiteboard mode** (`W`) — fill the canvas white for lecture-board / brainstorm use.
- **Pass-through mode** (`S`) — keep drawings visible while clicks reach the app below. Great for live demos.
- **Multi-line text** with auto-wrap at the canvas edge; Shift+Enter for newlines; Korean handwriting font (Gowun Dodum) bundled.
- **Floating toolbar** — anchored under the 그적 menubar icon; collapse with `M` to a small pill, drag any empty area to move; position remembered.
- **Object-based eraser** (`E`) — click or drag to remove whole shapes.
- **Undo / redo / clear** — `⌘Z` / `⌘⇧Z` / `⌘⌫` (or the toolbar trash).
- **Korean ⇆ English** language toggle in Settings (`⌘,`); hot-swap, no restart.
- **Multi-Space friendly** — Settings window follows the active desktop instead of yanking you back.
- **Drawings persist** across drawing-mode toggles within a session.

## Install

### Homebrew (recommended, when v1.0 ships)

```bash
brew install --cask leevigong/gzuk/gzuk
```

The cask's postflight hook strips the download quarantine attribute so the ad-hoc-signed app bypasses Gatekeeper on first launch — no Apple Developer ID is used; installing via the tap is an act of trust in the maintainer.

### Build from source

Requires Xcode 16+ and macOS 14+.

```bash
git clone https://github.com/leevigong/gzuk
cd gzuk
open GZUK.xcodeproj
```

Build and run with `⌘R`. The app uses no special permissions (`LSUIElement` only, unsandboxed).

## Repo layout

```
GZUK/                       Swift sources (drawing, overlay, toolbar, menubar, settings)
GZUKTests/                  XCTest target — DrawingStore / ShapeRenderer / HitTester / ScreenManager
GZUKUITests/                XCUITest target
scripts/
├─ deploy.sh                Local install: build → /Applications/그려적어.app + Spotlight keywords
├─ release.sh               Release archive → ad-hoc sign → ZIP + SHA256 (for the homebrew cask)
├─ make_app_icon.swift      Regenerate the AppIcon.appiconset PNGs from the Gowun Dodum font
├─ cask-template/           Drop-in for the leevigong/homebrew-gzuk tap repo
└─ web-template/            Next.js 14 + Tailwind landing page (becomes leevigong/gzuk.app)
docs/
└─ publishing-checklist.md  Live release prep tracker
```

## License

MIT — see [LICENSE](LICENSE). The bundled font (Gowun Dodum) is OFL 1.1.
