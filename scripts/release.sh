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

ZIP_SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
ZIP_SIZE=$(du -h "$ZIP_PATH" | awk '{print $1}' | tr -d '[:space:]')

# Build the DMG too. We use create-dmg's defaults — a clean window with the
# .app and an Applications-folder shortcut side by side, so the install
# flow is the familiar drag-to-Applications. `create-dmg` picks pleasant
# default sizes; tweak only when there's a real reason (e.g. brand-coloured
# background image).
DMG_NAME="gzuk-${VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

echo "▸ Creating DMG (${DMG_NAME})…"
if ! command -v create-dmg >/dev/null 2>&1; then
    echo "✗ create-dmg not installed. Run: brew install create-dmg" >&2
    exit 1
fi
create-dmg \
    --volname "${APP_DISPLAY_NAME} ${VERSION}" \
    --window-size 540 380 \
    --icon-size 100 \
    --icon "${APP_DISPLAY_NAME}.app" 140 180 \
    --app-drop-link 380 180 \
    --hide-extension "${APP_DISPLAY_NAME}.app" \
    --no-internet-enable \
    "$DMG_PATH" \
    "$DIST_APP" >/dev/null

DMG_SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}' | tr -d '[:space:]')

# Sparkle EdDSA signature for the DMG so existing users get auto-updates.
# The private key lives in the maintainer's Keychain (item name "Private key
# for signing Sparkle updates"). If sign_update fails with "ABORTED!", grant
# access via Keychain Access → Access Control on that item.
SIGN_UPDATE_BIN=""
for candidate in \
    "$HOME/Library/Developer/Xcode/DerivedData"/GZUK-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update; do
    if [[ -x "$candidate" ]]; then
        SIGN_UPDATE_BIN="$candidate"
        break
    fi
done

SPARKLE_BLOCK=""
if [[ -z "$SIGN_UPDATE_BIN" ]]; then
    SPARKLE_BLOCK="(sign_update binary not found — open the project in Xcode once to fetch Sparkle artifacts.)"
else
    if SIGN_OUTPUT=$("$SIGN_UPDATE_BIN" "$DMG_PATH" 2>&1); then
        # sign_update prints e.g.  sparkle:edSignature="..." length="123"
        # Strip the trailing length=…" since we emit it separately.
        ED_SIG_ATTR=$(echo "$SIGN_OUTPUT" | sed -E 's/ length="[0-9]+"//')
        DMG_BYTES=$(stat -f "%z" "$DMG_PATH")
        BUILD_VERSION=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" \
            -showBuildSettings 2>/dev/null \
            | awk -F' = ' '/ CURRENT_PROJECT_VERSION /{gsub(/^ +| +$/,"",$2); print $2; exit}')
        SPARKLE_BLOCK=$(cat <<SPARKLE_EOF

✓ Sparkle-signed ${DMG_NAME}
  ${SIGN_OUTPUT}

  Appcast item to add to scripts/web-template/public/appcast.xml.
  Note: sparkle:version is CFBundleVersion (integer), NOT MARKETING_VERSION.

    <item>
      <title>${VERSION}</title>
      <sparkle:version>${BUILD_VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure url="https://github.com/leevigong/gzuk/releases/download/v${VERSION}/${DMG_NAME}"
                 sparkle:version="${BUILD_VERSION}"
                 sparkle:shortVersionString="${VERSION}"
                 length="${DMG_BYTES}"
                 type="application/octet-stream"
                 ${ED_SIG_ATTR} />
    </item>
SPARKLE_EOF
)
    else
        SPARKLE_BLOCK=$(cat <<SPARKLE_EOF

✗ Sparkle signing failed:
  ${SIGN_OUTPUT}

  Fix: open Keychain Access, find "Private key for signing Sparkle updates",
  Access Control tab → add ${SIGN_UPDATE_BIN}, then rerun.
SPARKLE_EOF
)
    fi
fi

cat <<EOF

✓ Built ${ZIP_PATH}
  size:   ${ZIP_SIZE}
  sha256: ${ZIP_SHA256}

✓ Built ${DMG_PATH}
  size:   ${DMG_SIZE}
  sha256: ${DMG_SHA256}
${SPARKLE_BLOCK}

Next steps:
  1) Upload both to GitHub Releases:
       gh release create v${VERSION} "${ZIP_PATH}" "${DMG_PATH}" \\
         --repo leevigong/gzuk --title "v${VERSION}"

  2) Update homebrew-gzuk/Casks/gzuk.rb (use the ZIP — fastest install):
       version "${VERSION}"
       sha256  "${ZIP_SHA256}"
       url     "https://github.com/leevigong/gzuk/releases/download/v${VERSION}/${ZIP_NAME}"

  3) Append the appcast <item> above to scripts/web-template/public/appcast.xml,
     then deploy the Vercel site so existing users get the update via Sparkle.
EOF
