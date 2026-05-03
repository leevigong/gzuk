import SwiftUI
import AppKit

/// Floating tooltip panel that lives in its own NSWindow so it can render
/// outside the toolbar's bounds without forcing extra padding inside.
final class TooltipManager {
    static let shared = TooltipManager()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<TooltipView>?
    private var hideTask: DispatchWorkItem?

    private init() {}

    func show(_ text: String, at screenPoint: CGPoint) {
        hideTask?.cancel()
        hideTask = nil

        let view = TooltipView(text: text)
        if let host = hostingView, let panel {
            host.rootView = view
            host.layoutSubtreeIfNeeded()
            position(panel: panel, host: host, near: screenPoint)
            panel.orderFront(nil)
            return
        }

        let host = NSHostingView(rootView: view)
        host.translatesAutoresizingMaskIntoConstraints = true
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: host.fittingSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,
                                    .stationary, .ignoresCycle]
        panel.ignoresMouseEvents = true
        panel.contentView = host

        self.panel = panel
        self.hostingView = host

        host.layoutSubtreeIfNeeded()
        position(panel: panel, host: host, near: screenPoint)
        panel.orderFront(nil)
    }

    func hide() {
        // Tiny delay so rapid hover-between-buttons doesn't flicker.
        let task = DispatchWorkItem { [weak self] in
            self?.panel?.orderOut(nil)
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: task)
    }

    private func position(panel: NSPanel, host: NSHostingView<TooltipView>, near screenPoint: CGPoint) {
        let size = host.fittingSize
        // 14pt below the cursor, horizontally centered on it.
        var x = screenPoint.x - size.width / 2
        var y = screenPoint.y - size.height - 14

        if let screen = NSScreen.screens.first(where: { $0.frame.contains(screenPoint) })
                       ?? NSScreen.main {
            let f = screen.visibleFrame
            x = max(f.minX + 4, min(f.maxX - size.width - 4, x))
            // If too close to bottom of screen, flip above the cursor.
            if y < f.minY + 4 { y = screenPoint.y + 14 }
        }
        panel.setFrame(NSRect(origin: CGPoint(x: x, y: y), size: size),
                       display: true,
                       animate: false)
    }
}

private struct TooltipView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.primary.opacity(0.12), lineWidth: 0.5))
            .fixedSize()
            .padding(2)
    }
}

/// SwiftUI view modifier — shows a tooltip via the global TooltipManager
/// when the mouse hovers, hides on exit. Fully avoids macOS NSToolTip
/// reliability issues in borderless high-level windows.
struct InlineTooltip: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering, !text.isEmpty {
                TooltipManager.shared.show(text, at: NSEvent.mouseLocation)
            } else {
                TooltipManager.shared.hide()
            }
        }
    }
}

extension View {
    /// Hover tooltip rendered in a separate floating panel so it can extend
    /// past the host window without clipping.
    func tooltip(_ text: String) -> some View {
        modifier(InlineTooltip(text: text))
    }
}
