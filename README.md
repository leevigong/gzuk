# strokekit

A free, open-source macOS app for drawing on top of any screen content. The standalone "draw on screen" feature from Bandicam, without the recording.

> **Status:** v0.5 — full Bandicam-parity tool set + floating toolbar. See [the design spec](docs/superpowers/specs/2026-04-30-strokekit-design.md) for the full v1.0 plan.

## Why

Existing options on macOS each have a gap:
- **DrawPen** — no shape tools (rectangle, circle)
- **Pensela** — archived since 2022, removed from Homebrew
- **Annotate** — has the tools, but tools are buried in a menu bar dropdown and drawings fade by default

strokekit aims to fill those gaps.

## v0.5 features

- Menu bar app — no Dock icon
- `⌘⇧⌥7` (configurable in v1.0) to toggle drawing mode anywhere
- 9 tools: pen, highlighter, line, arrow, rectangle, circle, text, counter, eraser
- 8-color palette + custom picker (NSColorPanel)
- 4 line widths (2/4/6/10pt)
- Whiteboard mode (toggle to draw on a white canvas)
- Floating toolbar — drag to reposition; position remembered
- Undo / redo / clear all (`⌘Z` / `⇧⌘Z` / toolbar trash)
- Object-based eraser (click a shape to remove it)
- Drawings persist across drawing-mode toggles

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
