# 그려적어 (GZUK)

> [🇰🇷 한국어 README](README.ko.md)

Draw and write directly on top of any macOS screen.
One `⌃G` and any window becomes a canvas — meetings, lectures, demos,
code reviews.

→ Full overview and demo: **https://gzuk-app.vercel.app**

## Install

```bash
brew install --cask leevigong/gzuk/gzuk
```

The cask's postflight strips the download quarantine attribute so the
ad-hoc-signed app bypasses Gatekeeper on first launch — no Apple
Developer ID is used; installing via the tap is an act of trust in the
maintainer.

## Build from source

Requires Xcode 16+ and macOS 14+.

```bash
git clone https://github.com/leevigong/gzuk
cd gzuk
open GZUK.xcodeproj
```

`⌘R` to run. The app uses no special permissions (`LSUIElement` only,
unsandboxed).

## License

MIT — see [LICENSE](LICENSE). Bundled font (Gowun Dodum) is OFL 1.1.
