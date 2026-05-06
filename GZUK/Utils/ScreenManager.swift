import AppKit

/// Minimal protocol exposing only what ScreenManager needs from NSScreen,
/// so we can inject mocks in tests.
protocol ScreenLike: AnyObject {
    var frame: CGRect { get }
}

extension NSScreen: ScreenLike {}

extension NSScreen {
    /// Stable per-physical-display identifier. Used to keep separate drawing
    /// canvases per monitor so moving between displays doesn't drag old
    /// strokes onto a new screen.
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }
}

enum ScreenManager {
    /// Returns the screen whose frame contains the given point, or nil.
    static func screen(at point: CGPoint, in screens: [ScreenLike]) -> ScreenLike? {
        screens.first { $0.frame.contains(point) }
    }

    /// Convenience: real NSScreen.screens + current mouse location.
    static func screenWithCursor() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) }
    }
}
