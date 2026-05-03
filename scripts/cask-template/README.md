# homebrew-gzuk

Homebrew tap for [그려적어 (GZUK)](https://github.com/leevigong/gzuk) — draw and write directly on your macOS screen.

## Install

```bash
brew install --cask leevigong/gzuk/gzuk
```

The first command is shorthand for:

```bash
brew tap leevigong/gzuk
brew install --cask gzuk
```

## Update

```bash
brew upgrade --cask gzuk
```

## Uninstall

```bash
brew uninstall --cask gzuk
```

## Why a custom tap?

그려적어 is distributed as an ad-hoc-signed app rather than a notarized one (no Apple Developer ID is used). The cask's `postflight` hook strips the download quarantine attribute so macOS Gatekeeper doesn't block first launch — installing via this tap is an act of trust in the maintainer.

If you'd rather verify before installing, the source code lives at https://github.com/leevigong/gzuk and you can build it yourself with `xcodebuild` or run `scripts/release.sh`.
