import AppKit

final class StatusItemController {
    private let statusItem: NSStatusItem
    private let onToggle: () -> Void
    private let onSettings: () -> Void

    /// Frame of the status item button in screen coordinates (or nil if unavailable).
    var buttonFrameOnScreen: NSRect? {
        statusItem.button?.window?.frame
    }

    init(onToggle: @escaping () -> Void,
         onSettings: @escaping () -> Void) {
        self.onToggle = onToggle
        self.onSettings = onSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = Self.makeStatusBarImage()
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    /// Draws a vertical stack of "그" (bold) over "적" (regular).
    /// Uses Gowun Dodum if available, otherwise falls back to Apple SD Gothic Neo.
    private static func makeStatusBarImage() -> NSImage {
        let fontSize: CGFloat = 10
        let visualGap: CGFloat = 4           // visible space between glyph cap-tops
        let horizontalPadding: CGFloat = 3

        let bold = NSFont(name: "GowunDodum-Regular", size: fontSize)
            .map { NSFontManager.shared.convert($0, toHaveTrait: .boldFontMask) }
            ?? NSFont(name: "AppleSDGothicNeo-Bold", size: fontSize)
            ?? .boldSystemFont(ofSize: fontSize)
        let regular = NSFont(name: "GowunDodum-Regular", size: fontSize)
            ?? NSFont(name: "AppleSDGothicNeo-Regular", size: fontSize)
            ?? .systemFont(ofSize: fontSize)

        // Template-compatible: pure black fill, no stroke. (Stroke attributes
        // can break NSImage template inversion in dark mode.)
        // Both glyphs use the same bold font so 그/적 weights match.
        let topAttrs: [NSAttributedString.Key: Any] = [
            .font: bold,
            .foregroundColor: NSColor.black
        ]
        let bottomAttrs: [NSAttributedString.Key: Any] = [
            .font: bold,
            .foregroundColor: NSColor.black
        ]

        let topSize = ("그" as NSString).size(withAttributes: topAttrs)
        let bottomSize = ("적" as NSString).size(withAttributes: bottomAttrs)

        // Tight stacking: space the two baselines by capHeight (+ optional visualGap)
        // rather than by full line height (which includes ascender/descender padding).
        let capH = max(bold.capHeight, regular.capHeight)
        let bottomY: CGFloat = 0
        let topY = capH + visualGap

        let contentWidth = max(topSize.width, bottomSize.width)
        let contentHeight = topY + bold.ascender + abs(bold.descender)

        let imageSize = NSSize(
            width: ceil(contentWidth + horizontalPadding * 2),
            height: ceil(contentHeight)
        )

        // Bake glyphs into an explicit bitmap (Retina-aware) so colors are
        // resolved once at creation time. Avoids lazy re-evaluation that can
        // interfere with template-image inversion in dark mode.
        let scale: Int = 2
        let pixelsWide = Int(imageSize.width) * scale
        let pixelsHigh = Int(imageSize.height) * scale
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        rep.size = imageSize

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let topX = (imageSize.width - topSize.width) / 2
        let bottomX = (imageSize.width - bottomSize.width) / 2
        // Draw each glyph multiple times with sub-pixel offsets to fake bold.
        // Keeps the image template-compatible (pure black + alpha).
        // Same offsets for both → identical visual weight.
        let offsets: [CGPoint] = [.zero, CGPoint(x: 0.5, y: 0), CGPoint(x: 0, y: 0.5), CGPoint(x: 0.5, y: 0.5)]
        for off in offsets {
            ("그" as NSString).draw(at: NSPoint(x: topX + off.x, y: topY + off.y), withAttributes: topAttrs)
            ("적" as NSString).draw(at: NSPoint(x: bottomX + off.x, y: bottomY + off.y), withAttributes: bottomAttrs)
        }
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: imageSize)
        image.addRepresentation(rep)
        image.isTemplate = true
        return image
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            onToggle()
        }
    }

    @objc private func openSettings() { onSettings() }

    private func showMenu() {
        let menu = NSMenu()
        let settings = NSMenuItem(title: "설정…",
                                  action: #selector(openSettings),
                                  keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "그려적어 종료",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Detach so subsequent left-clicks toggle instead of opening the menu
        statusItem.menu = nil
    }
}
