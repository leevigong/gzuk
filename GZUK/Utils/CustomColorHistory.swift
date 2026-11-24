import AppKit

/// Colors the user picked with the rainbow swatch, kept without any explicit
/// "save" step.
///
/// - `current` is what the rainbow swatch holds (pressing it switches back).
/// - `saved` mirrors the "그려적어" palette in the system color panel
///   (see ColorListStore), newest first.
///
/// Only colors actually drawn with are recorded (see `recordUse`), so the
/// dozens of intermediate values the color wheel passes through while the
/// user drags it never pile up.
struct CustomColorHistory: Equatable {
    /// Enough for a working set of label colors; past that the oldest go, so
    /// the palette never turns into an endless scroll.
    static let maxSaved = 30

    private(set) var current: NSColor?
    private(set) var saved: [NSColor] = []

    init(current: NSColor? = nil, saved: [NSColor] = []) {
        self.current = current
        self.saved = Array(saved.prefix(Self.maxSaved))
    }

    /// A shape was just committed in `color`. A non-preset color becomes the
    /// rainbow's, and joins the front of `saved` unless it's already there
    /// (existing entries keep their place, so the palette doesn't reshuffle
    /// when the user reuses a saved color). Returns what changed.
    @discardableResult
    mutating func recordUse(of color: NSColor, presets: [NSColor]) -> (current: Bool, saved: Bool) {
        if presets.contains(where: { Self.same($0, color) }) { return (false, false) }
        var changed = (current: false, saved: false)
        if current.map({ !Self.same($0, color) }) ?? true {
            current = color
            changed.current = true
        }
        if !saved.contains(where: { Self.same($0, color) }) {
            saved.insert(color, at: 0)
            if saved.count > Self.maxSaved {
                saved.removeLast(saved.count - Self.maxSaved)
            }
            changed.saved = true
        }
        return changed
    }

    /// Colors match when their sRGB components agree to within rounding —
    /// NSColor's own == also compares color space, which the picker changes.
    static func same(_ x: NSColor, _ y: NSColor) -> Bool {
        guard let a = x.usingColorSpace(.sRGB),
              let b = y.usingColorSpace(.sRGB) else { return false }
        return abs(a.redComponent - b.redComponent) < 0.001 &&
               abs(a.greenComponent - b.greenComponent) < 0.001 &&
               abs(a.blueComponent - b.blueComponent) < 0.001
    }

    static func == (l: Self, r: Self) -> Bool {
        func eq(_ a: NSColor?, _ b: NSColor?) -> Bool {
            switch (a, b) {
            case (nil, nil): return true
            case let (a?, b?): return same(a, b)
            default: return false
            }
        }
        return eq(l.current, r.current)
            && l.saved.count == r.saved.count
            && zip(l.saved, r.saved).allSatisfy { same($0, $1) }
    }
}

/// The "그려적어" palette in the system color panel (Color Palettes tab).
/// Saved under ~/Library/Colors, so it's also offered by other apps' color
/// panels. The palette itself is the source of truth: it's re-read before
/// every change, so colors the user deletes there stay deleted.
enum ColorListStore {
    static let name = "그려적어"

    static func load() -> [NSColor] {
        guard let list = NSColorList(named: name) else { return [] }
        return list.allKeys.compactMap { list.color(withKey: $0) }
    }

    static func save(_ colors: [NSColor]) {
        let list = existingEditableList() ?? NSColorList(name: name)
        for key in list.allKeys {
            list.removeColor(withKey: key)
        }
        for (i, color) in colors.enumerated() {
            list.insertColor(color, key: key(for: color), at: i)
        }
        do {
            try list.write(to: nil)   // nil → ~/Library/Colors/<name>.clr
        } catch {
            NSLog("GZUK: saving color palette failed: \(error)")
        }
        attachIfNeeded(list)
    }

    /// A list written for the first time this session isn't picked up by an
    /// already-created color panel on its own.
    static func attachIfNeeded(_ list: NSColorList? = NSColorList(named: name)) {
        guard let list, NSColorPanel.sharedColorPanelExists,
              !NSColorList.availableColorLists.contains(where: { $0 === list })
        else { return }
        NSColorPanel.shared.attachColorList(list)
    }

    private static func existingEditableList() -> NSColorList? {
        guard let list = NSColorList(named: name), list.isEditable else { return nil }
        return list
    }

    /// Hex label shown next to each swatch in the palette's list view.
    private static func key(for color: NSColor) -> String {
        let c = color.usingColorSpace(.sRGB) ?? color
        return String(format: "#%02X%02X%02X",
                      Int((c.redComponent * 255).rounded()),
                      Int((c.greenComponent * 255).rounded()),
                      Int((c.blueComponent * 255).rounded()))
    }
}
