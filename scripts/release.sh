#!/usr/bin/env bash
# Build a Release archive, ad-hoc sign it, ZIP it, and print the SHA256 for
# the Homebrew Cask formula. Usage: ./scripts/release.sh
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="GZUK.xcodeproj"
SCHEME="GZUK"
CONFIG="Release"
APP_DISPLAY_NAME="그려적어"
DIST_DIR="dist"
ARCHIVE_PATH="${DIST_DIR}/GZUK.xcarchive"

VERSION=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" \
    -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/ MARKETING_VERSION /{gsub(/^ +| +$/,"",$2); print $2; exit}')

if [[ -z "$VERSION" ]]; then
    echo "✗ Could not read MARKETING_VERSION from project" >&2
    exit 1
fi

ZIP_NAME="gzuk-${VERSION}.zip"
ZIP_PATH="${DIST_DIR}/${ZIP_NAME}"

echo "▸ Cleaning ${DIST_DIR}…"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "▸ Archiving ${SCHEME} ${VERSION} (${CONFIG})… (~30s)"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'platform=macOS' \
    archive -quiet

SRC_APP="${ARCHIVE_PATH}/Products/Applications/${SCHEME}.app"
if [[ ! -d "$SRC_APP" ]]; then
    echo "✗ Archived app not found at: $SRC_APP" >&2
    exit 1
fi

# Copy the .app out and rename to its user-facing display name so users
# unzipping see "그려적어.app" instead of "GZUK.app".
DIST_APP="${DIST_DIR}/${APP_DISPLAY_NAME}.app"
ditto "$SRC_APP" "$DIST_APP"

echo "▸ Ad-hoc signing (no Developer ID)…"
codesign --force --deep --sign - --timestamp=none "$DIST_APP"
codesign --verify --deep --strict "$DIST_APP"

echo "▸ Stripping extended attributes…"
xattr -cr "$DIST_APP"

echo "▸ Creating ZIP (${ZIP_NAME})…"
ditto -c -k --sequesterRsrc --keepParent "$DIST_APP" "$ZIP_PATH"

SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
SIZE=$(du -h "$ZIP_PATH" | awk '{print $1}' | tr -d '[:space:]')

cat <<EOF

✓ Built ${ZIP_PATH}
  size:   ${SIZE}
  sha256: ${SHA256}

Next steps:
  1) Upload to GitHub Releases:
       gh release create v${VERSION} "${ZIP_PATH}" \\
         --repo leevigong/gzuk --title "v${VERSION}"

  2) Update homebrew-gzuk/Casks/gzuk.rb:
       version "${VERSION}"
       sha256  "${SHA256}"
       url     "https://github.com/leevigong/gzuk/releases/download/v${VERSION}/${ZIP_NAME}"
EOF
