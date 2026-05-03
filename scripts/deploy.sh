#!/usr/bin/env bash
# Build → install to /Applications/그려적어.app → set Spotlight keywords → relaunch.
# Usage: ./scripts/deploy.sh
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="GZUK.xcodeproj"
SCHEME="GZUK"
CONFIG="Debug"
DEST_NAME="그려적어"
DEST_PATH="/Applications/${DEST_NAME}.app"
KEYWORDS=("그적" "그려적어" "GZUK")

echo "▸ Building ${SCHEME} (${CONFIG})…"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" build -quiet

# Locate the built .app via xcodebuild settings (more reliable than DerivedData glob).
BUILT_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" \
    -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{print $2; exit}')
SRC_APP="${BUILT_DIR}/${SCHEME}.app"

if [[ ! -d "$SRC_APP" ]]; then
    echo "✗ Built app not found at: $SRC_APP" >&2
    exit 1
fi

echo "▸ Stopping running instances…"
pkill -f "${SCHEME}" 2>/dev/null || true
sleep 1

echo "▸ Installing to ${DEST_PATH}…"
ditto "$SRC_APP" "$DEST_PATH"

echo "▸ Tagging Spotlight keywords (${KEYWORDS[*]})…"
# Finder Comment — simple string Spotlight indexes.
xattr -w com.apple.metadata:kMDItemFinderComment "${KEYWORDS[*]}" "$DEST_PATH"
# kMDItemKeywords — proper array (binary plist), most reliable for queries.
HEX=$(python3 -c "
import plistlib, sys
print(plistlib.dumps([$(printf "'%s'," "${KEYWORDS[@]}" | sed 's/,$//')], fmt=plistlib.FMT_BINARY).hex())
")
xattr -wx com.apple.metadata:kMDItemKeywords "$HEX" "$DEST_PATH"

echo "▸ Re-registering with LaunchServices + Spotlight…"
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREG" -f -R "$DEST_PATH"
mdimport "$DEST_PATH"

echo "▸ Launching ${DEST_NAME}…"
open "$DEST_PATH"

echo "✓ Done. Try: ⌘+Space → ${KEYWORDS[*]}"
