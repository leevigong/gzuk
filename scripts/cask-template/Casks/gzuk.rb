cask "gzuk" do
  version "1.0"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE_SH"

  url "https://github.com/leevigong/gzuk/releases/download/v#{version}/gzuk-#{version}.zip"
  name "그려적어"
  desc "Draw and write directly on your macOS screen"
  homepage "https://gzuk.app"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "그려적어.app"

  # The app is ad-hoc signed (no Apple Developer ID). Strip the download
  # quarantine attribute so macOS Gatekeeper doesn't block first launch —
  # users trust the cask maintainer rather than an Apple-issued certificate.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine",
                          "#{appdir}/그려적어.app"]
  end

  zap trash: [
    "~/Library/Preferences/com.leevigong.GZUK.plist",
    "~/Library/Saved Application State/com.leevigong.GZUK.savedState",
  ]
end
