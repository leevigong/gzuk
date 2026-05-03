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

        // Restore the user's last position if they dragged the toolbar
        // before; otherwise use the default (top-center of the screen).
        let origin = ToolbarPositionStore.load() ?? defaultOrigin(for: size)
        win.setFrameOrigin(origin)
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
        // Always re-anchor under the 그적 menubar icon on collapse/expand —
        // matches the "popover-style" default position the user picked. If
        // the anchor is unavailable, fall back to the toolbar's current
        // center so we don't jump weirdly.
        let origin: CGPoint
        if anchorProvider() != nil {
            origin = defaultOrigin(for: newSize)
        } else {
            let oldFrame = win.frame
            origin = CGPoint(
                x: oldFrame.midX - newSize.width / 2,
                y: oldFrame.origin.y + (oldFrame.height - newSize.height)
            )
        }
        win.setFrame(NSRect(origin: origin, size: newSize), display: true, animate: false)
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
        let center = CGPoint(x: win.frame.midX, y: win.frame.midY)
        let stillVisible = NSScreen.screens.contains { $0.visibleFrame.contains(center) }
        if !stillVisible {
            let origin = defaultOrigin(for: win.frame.size)
            win.setFrameOrigin(origin)
        }
    }

    /// Default position: anchored under the 그적 menubar status item like a
    /// popover, so users see "this came from there." Falls back to top-
    /// center if the status item position is unavailable (no screen with
    /// cursor, etc.).
    private func defaultOrigin(for size: CGSize) -> CGPoint {
        let screen = ScreenManager.screenWithCursor() ?? NSScreen.main
        guard let f = screen?.visibleFrame else {
            return CGPoint(x: 100, y: 100)
        }
        // 1pt cosmetic gap below the menubar.
        let topY = f.maxY - size.height - 1

        if let anchor = anchorProvider() {
            // Center the toolbar horizontally on the status item, but clamp
            // to keep it fully on-screen (right edge especially — the icon
            // sits near the right of the menubar).
            let desiredX = anchor.midX - size.width / 2
            let minX = f.minX + 4
            let maxX = f.maxX - size.width - 4
            let x = max(minX, min(maxX, desiredX))
            return CGPoint(x: x, y: topY)
        }

        // Fallback — top-center of screen.
        return CGPoint(x: f.midX - size.width / 2, y: topY)
    }
}
