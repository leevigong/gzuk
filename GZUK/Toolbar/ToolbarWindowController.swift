import AppKit
import SwiftUI

final class ToolbarWindowController {
    private let store: DrawingStore
    private let anchorProvider: () -> NSRect?
    private var window: ToolbarWindow?
    private var screenChangeObserver: NSObjectProtocol?

    init(store: DrawingStore,
         anchorProvider: @escaping () -> NSRect? = { nil }) {
        self.store = store
        self.anchorProvider = anchorProvider
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }

    deinit {
        if let obs = screenChangeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func show() {
        guard window == nil else { return }

        let hosting = NSHostingView(rootView: ToolbarView(store: store))
        let size = hosting.fittingSize
        let win = ToolbarWindow(contentSize: size)
        win.contentView = hosting
        win.alphaValue = PreferencesStore.shared.toolbarOpacity

        // Restore the user's last drag position if it's still on a visible
        // screen. ⌃G is just a toggle — pressing it on a different monitor
        // shouldn't move the toolbar; the session sticks where it started.
        // The "click an icon on monitor B to start a new session there"
        // path explicitly clears the stored position before toggling, so
        // load() returns nil and we fall through to defaultOrigin (which
        // anchors to the cursor's monitor).
        let restored = Self.onScreenOrigin(ToolbarPositionStore.load(), size: size)
        // A restored position came from a deliberate drag, so it outranks the
        // menubar anchor on the next collapse/expand too.
        win.userHasRepositioned = restored != nil
        win.setFrameOrigin(restored ?? defaultOrigin(for: size))
        win.updateLevelForMenuBarOverlap()
        win.orderFront(nil)
        self.window = win

        observeOpacity()
        observeCollapseState()
    }

    private func observeOpacity() {
        withObservationTracking {
            _ = PreferencesStore.shared.toolbarOpacity
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.window?.alphaValue = PreferencesStore.shared.toolbarOpacity
                self?.observeOpacity()
            }
        }
    }

    /// Resize the window to match the SwiftUI content when the toolbar
    /// collapses or expands. Anchors the window so the top-left corner
    /// stays put as the height changes.
    private func observeCollapseState() {
        withObservationTracking {
            _ = store.isToolbarCollapsed
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.resizeToFit()
                self?.observeCollapseState()
            }
        }
    }

    private func resizeToFit() {
        guard let win = window,
              let hosting = win.contentView as? NSHostingView<ToolbarView> else { return }
        // Force layout pass so fittingSize reflects the new SwiftUI tree.
        hosting.layoutSubtreeIfNeeded()
        let newSize = hosting.fittingSize
        // Re-anchor under the 그적 menubar icon on collapse/expand — matches
        // the "popover-style" default position. Skipped once the user has
        // dragged the toolbar somewhere themselves: yanking it back would
        // undo a deliberate placement (e.g. parked over the menubar) every
        // time they hit M. In that case — and when the anchor is unavailable
        // — keep the current top edge and re-center on the old midpoint so
        // the size change doesn't jump.
        let origin: CGPoint
        if anchorProvider() != nil && !win.userHasRepositioned {
            origin = defaultOrigin(for: newSize)
        } else {
            let oldFrame = win.frame
            origin = CGPoint(
                x: oldFrame.midX - newSize.width / 2,
                y: oldFrame.origin.y + (oldFrame.height - newSize.height)
            )
        }
        win.setFrame(NSRect(origin: origin, size: newSize), display: true, animate: false)
        win.updateLevelForMenuBarOverlap()
    }

    func hide() {
        if let w = window { ToolbarPositionStore.save(w.frame.origin) }
        window?.orderOut(nil)
        window = nil
    }

    /// If the toolbar's last position is no longer on any visible screen
    /// (monitor unplugged), snap it back to the default top-center of the
    /// current cursor's screen so it doesn't end up stranded off-screen.
    private func handleScreenChange() {
        guard let win = window else { return }
        if Self.onScreenOrigin(win.frame.origin, size: win.frame.size) == nil {
            win.setFrameOrigin(defaultOrigin(for: win.frame.size))
        }
        win.updateLevelForMenuBarOverlap()
    }

    /// Returns the origin unchanged if a window of the given size placed
    /// there would have its center on at least one visible screen; nil
    /// otherwise. Lets callers decide whether to keep or fall back.
    private static func onScreenOrigin(_ origin: CGPoint?, size: CGSize) -> CGPoint? {
        guard let origin else { return nil }
        let center = CGPoint(x: origin.x + size.width / 2,
                             y: origin.y + size.height / 2)
        // Test against `frame`, not `visibleFrame`: a toolbar deliberately
        // parked in the menubar strip is still perfectly on-screen, and
        // visibleFrame would report it as stranded and snap it away.
        let visible = NSScreen.screens.contains { $0.frame.contains(center) }
        return visible ? origin : nil
    }

    /// Default position: anchored under the 그적 menubar status item like a
    /// popover, so users see "this came from there." Falls back to top-
    /// center if the status item position is unavailable or on a different
    /// monitor (NSStatusItem only reports one button frame even when the
    /// icon visually appears on every display, so its anchor X is always
    /// the primary monitor's — clamping that into a secondary monitor's
    /// range would pin the toolbar to a screen edge instead of centering).
    private func defaultOrigin(for size: CGSize) -> CGPoint {
        let screen = ScreenManager.screenWithCursor() ?? NSScreen.main
        guard let s = screen, case let f = s.visibleFrame else {
            return CGPoint(x: 100, y: 100)
        }
        // 1pt cosmetic gap below the menubar.
        let topY = f.maxY - size.height - 1

        if let anchor = anchorProvider(),
           s.frame.contains(CGPoint(x: anchor.midX, y: anchor.midY)) {
            // Anchor is on the same monitor as the cursor — center the
            // toolbar horizontally under the status item icon, clamped to
            // keep it fully on-screen.
            let desiredX = anchor.midX - size.width / 2
            let minX = f.minX + 4
            let maxX = f.maxX - size.width - 4
            let x = max(minX, min(maxX, desiredX))
            return CGPoint(x: x, y: topY)
        }

        // No anchor or anchor is on a different monitor → top-center.
        return CGPoint(x: f.midX - size.width / 2, y: topY)
    }
}
