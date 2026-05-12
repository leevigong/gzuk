# Sparkle Auto-Update

GZUK uses [Sparkle 2](https://sparkle-project.org/) to push updates to users
who installed via DMG/ZIP (Homebrew users still get updates via `brew upgrade`).

## How it works

- App reads `SUFeedURL` from `Info.plist` →
  `https://gzuk-app.vercel.app/appcast.xml`
- Sparkle polls the feed periodically and on the user's "Check for Updates…"
  menubar action.
- Each `<item>` in the feed has an EdDSA signature; the app verifies it
  against `SUPublicEDKey` (also in `Info.plist`). Because the app is ad-hoc
  signed (no Developer ID), this EdDSA path is what makes updates safe.

## Maintainer key (one-time setup, already done)

The EdDSA private key lives in macOS Keychain on the maintainer's machine
under item name **"Private key for signing Sparkle updates"** (account
`ed25519`, service `https://sparkle-project.org`).

The matching public key is in `GZUK/Info.plist` as `SUPublicEDKey`. **Do not
change `SUPublicEDKey`** once shipped — existing installs will reject
updates signed with a different key, and there's no recovery besides telling
users to reinstall manually.

### Back up the private key

```sh
generate_keys -x sparkle-private.key
```

Then store `sparkle-private.key` somewhere safe (1Password, encrypted USB).
If the Mac dies and you lose the Keychain item, you can restore with:

```sh
generate_keys -f sparkle-private.key
```

## Releasing an update

1. Bump `MARKETING_VERSION` in `GZUK.xcodeproj/project.pbxproj`.
2. Commit + push.
3. `./scripts/release.sh` — builds DMG/ZIP, runs `sign_update` on the DMG,
   prints the `<enclosure>` snippet to paste into the appcast.
4. **First time only**: Keychain Access will prompt to allow `sign_update`
   to read the key. Click "Always Allow" so subsequent releases run clean.
5. `gh release create v${VERSION} dist/gzuk-${VERSION}.zip dist/gzuk-${VERSION}.dmg`
6. Paste the printed `<enclosure>` into a new `<item>` at the top of
   `scripts/web-template/public/appcast.xml`. Commit + push so Vercel
   re-deploys.
7. (If using Homebrew tap) update `homebrew-gzuk/Casks/gzuk.rb`.

## Troubleshooting

- **`sign_update` aborts with "You've cancelled the request to read the key"**
  — the Keychain dialog appeared but was denied. Open Keychain Access, find
  the "Private key for signing Sparkle updates" item, Access Control tab →
  add the `sign_update` binary (`~/Library/Developer/Xcode/DerivedData/GZUK-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update`)
  → Save Changes.

- **Sparkle reports "appcast not found"** — Vercel may not have redeployed
  after the `appcast.xml` push. Check the deploy log; the path must be
  `/appcast.xml` at the apex.

- **Updates show but won't install on user's machine** — usually a signature
  mismatch (wrong key) or download URL 404. Re-verify the `<enclosure url>`
  matches the actual GitHub Release asset URL exactly.
