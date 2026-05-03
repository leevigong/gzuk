import AppKit

final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let onToggle: () -> Void
    private let onSettings: () -> Void

    private var isDrawing = false
    private var isPassthrough = false
    private var hovering = false
    private var menuShowing = false
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    /// Frame of the status item button in screen coordinates (or nil if unavailable).
    var buttonFrameOnScreen: NSRect? {
        statusItem.button?.window?.frame
    }

    init(onToggle: @escaping () -> Void,
         onSettings: @escaping () -> Void) {
        self.onToggle = onToggle
        self.onSettings = onSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            let dark = button.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            button.image = Self.makeStatusBarImage(active: false, focused: false, dark: dark)
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Refresh icon when our app gains/loses focus so the dot accurately
        // reflects whether keyboard shortcuts will fire right now.
        NotificationCenter.default.addObserver(
            self, selector: #selector(refreshIcon),
            name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(refreshIcon),
            name: NSApplication.didResignActiveNotification, object: nil)
        // Re-render the glyph when the system flips between light/dark mode
        // so the literal-color icon (we don't use isTemplate) stays visible.
        DistributedNotificationCenter.default.addObserver(
            self, selector: #selector(refreshIcon),
            name: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil)

        // Custom hover detection: NSStatusBar's tracking-area dispatch is
        // unreliable (system intercepts events), so poll mouse position via
        // global+local mouse-moved monitors and toggle TooltipManager when
        // the cursor crosses our button's screen rect.
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.checkHover()
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.checkHover()
            return event
        }
    }

    deinit {
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m) }
        if let m = localMouseMonitor { NSEvent.removeMonitor(m) }
    }

    private func checkHover() {
        // Don't fight the right-click menu — its dropdown sits exactly where
        // the tooltip would appear.
        if menuShowing {
            if hovering { hovering = false; TooltipManager.shared.hide() }
            return
        }
        guard let frame = buttonFrameOnScreen else { return }
        let inside = frame.contains(NSEvent.mouseLocation)
        if inside, !hovering {
            hovering = true
            // TooltipManager places the tooltip ~14pt below the anchor;
            // shift the anchor up so the gap from the menubar icon is small.
            let anchor = CGPoint(x: frame.midX, y: frame.minY + 10)
            TooltipManager.shared.show(Self.tooltip(active: isDrawing,
                                                     passthrough: isPassthrough,
                                                     focused: NSApp.isActive),
                                        at: anchor)
        } else if !inside, hovering {
            hovering = false
            TooltipManager.shared.hide()
        }
    }

    /// Switch the menubar icon to reflect drawing-mode state. Focus state is
    /// read live so the icon dims if our app loses focus while drawing is on.
    func setActive(_ active: Bool) {
        isDrawing = active
        refreshIcon()
    }

    /// Pass-through (cursor) mode tracker — the icon stays the same, but the
    /// hover tooltip changes from "그리는 중" to "커서 모드" so the label
    /// matches what's actually happening.
    func setPassthrough(_ on: Bool) {
        isPassthrough = on
    }

    @objc private func refreshIcon() {
        let focused = NSApp.isActive
        // Detect light vs dark menubar via the status item button's effective
        // appearance. Falls back to the app's appearance when the button isn't
        // available yet.
        let appearance = statusItem.button?.effectiveAppearance ?? NSApp.effectiveAppearance
        let dark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        statusItem.button?.image = Self.makeStatusBarImage(active: isDrawing,
                                                            focused: focused,
                                                            dark: dark)
    }

    /// Hover label. Active/idle states are kept terse; the unfocused state is
    /// the only one that needs to teach the ⌃G trick, since users would
    /// otherwise be stuck wondering why shortcuts stopped firing. Pass-through
    /// (cursor) mode gets its own label so "그리는 중" doesn't lie about what
    /// clicks are actually doing.
    private static func tooltip(active: Bool, passthrough: Bool, focused: Bool) -> String {
        if !active {
            return L.t("그려적어 (⌃G)", "그려적어 (⌃G)")
        }
        if !focused {
            return L.t("포커스 잃음 — ⌃G 로 회수",
                       "No focus — ⌃G to reclaim")
        }
        if passthrough {
            return L.t("커서 모드", "Cursor mode")
        }
        return L.t("그리는 중", "Drawing")
    }

    /// Draws a vertical stack of "그" over "적", plus an optional small dot
    /// in the top-right indicating drawing-mode state:
    ///   active && focused → bright red dot (shortcuts will work)
    ///   active && !focused → muted gray dot (drawing on, but our app
    ///                                          isn't frontmost so shortcuts
    ///                                          won't fire)
    ///   !active → no dot
    /// Glyphs are drawn with a literal color (white in dark mode, near-black
    /// in light) and `isTemplate = false`, so the active state's red dot
    /// keeps its color AND the inactive state's stroke weight matches the
    /// active one (template inversion was visibly thinning the fake-bold).
    private static func makeStatusBarImage(active: Bool, focused: Bool, dark: Bool) -> NSImage {
        let fontSize: CGFloat = 11
        let visualGap: CGFloat = 4           // visible space between glyph cap-tops
        let horizontalPadding: CGFloat = 3

        let bold = NSFont(name: "GowunDodum-Regular", size: fontSize)
            .map { NSFontManager.shared.convert($0, toHaveTrait: .boldFontMask) }
            ?? NSFont(name: "AppleSDGothicNeo-Bold", size: fontSize)
            ?? .boldSystemFont(ofSize: fontSize)
        let regular = NSFont(name: "GowunDodum-Regular", size: fontSize)
            ?? NSFont(name: "AppleSDGothicNeo-Regular", size: fontSize)
            ?? .systemFont(ofSize: fontSize)

        // Glyphs: white on a dark menubar, near-black on a light one. Same
        // color for both active and idle so the fake-bold rendering doesn't
        // get thinned by template-image processing.
        let glyphColor: NSColor = dark ? NSColor.white
                                       : NSColor(white: 0.07, alpha: 1.0)
        let topAttrs: [NSAttributedString.Key: Any] = [
            .font: bold,
            .foregroundColor: glyphColor
        ]
        let bottomAttrs: [NSAttributedString.Key: Any] = [
            .font: regular,
            .foregroundColor: glyphColor
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

        // Reserve a little extra space top-right for the active-state dot.
        let dotDiameter: CGFloat = 4
        let extraRightSpace: CGFloat = active ? dotDiameter + 1 : 0
        let imageSize = NSSize(
            width: ceil(contentWidth + horizontalPadding * 2 + extraRightSpace),
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
        // Center glyphs in the original glyph area (excluding the reserved
        // dot space) so they don't shift when the active state flips.
        let glyphAreaWidth = contentWidth + horizontalPadding * 2
        let topX = (glyphAreaWidth - topSize.width) / 2
        let bottomX = (glyphAreaWidth - bottomSize.width) / 2
        // 그 gets fake-bold via sub-pixel overlay; 적 draws once (regular weight).
        let boldOffsets: [CGPoint] = [.zero, CGPoint(x: 0.5, y: 0), CGPoint(x: 0, y: 0.5), CGPoint(x: 0.5, y: 0.5)]
        for off in boldOffsets {
            ("그" as NSString).draw(at: NSPoint(x: topX + off.x, y: topY + off.y), withAttributes: topAttrs)
        }
        ("적" as NSString).draw(at: NSPoint(x: bottomX, y: bottomY), withAttributes: bottomAttrs)

        // Active indicator dot — top-right corner.
        // Red = focused (shortcuts work) / Gray = unfocused (need to click in).
        if active {
            let dotRect = NSRect(
                x: imageSize.width - dotDiameter - 0.5,
                y: imageSize.height - dotDiameter - 1,
                width: dotDiameter,
                height: dotDiameter
            )
            let dotColor: NSColor = focused
                ? NSColor(red: 1.0, green: 0.13, blue: 0.13, alpha: 1.0)
                : NSColor(white: 0.6, alpha: 0.85)
            dotColor.setFill()
            NSBezierPath(ovalIn: dotRect).fill()
        }
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: imageSize)
        image.addRepresentation(rep)
        // Always non-template: we pick the glyph color manually based on
        // light/dark mode (so the red dot stays red in active state, AND
        // the inactive bold weight matches the active one — template
        // processing was visibly thinning the fake-bold strokes).
        image.isTemplate = false
        return image
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        // Any click dismisses the hover hint immediately so it doesn't
        // overlap the menu or remain stale through the toggle.
        hovering = false
        TooltipManager.shared.hide()
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            onToggle()
        }
    }

    @objc private func openSettings() {
        // Defer so the menu fully dismisses (and the status button's
        // highlighted background clears) before the Settings window opens.
        DispatchQueue.main.async { [weak self] in
            self?.onSettings()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        let settings = NSMenuItem(title: L.t("설정…", "Settings…"),
                                  action: #selector(openSettings),
                                  keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L.t("그려적어 종료", "Quit GZUK"),
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        menuShowing = true
        // performClick blocks until the menu is dismissed.
        statusItem.button?.performClick(nil)
        menuShowing = false
        // Detach so subsequent left-clicks toggle instead of opening the menu
        statusItem.menu = nil
        // Force the highlighted (purple) background off — AppKit doesn't always
        // clear it on its own when the menu action opens another window.
        statusItem.button?.highlight(false)
    }
}
