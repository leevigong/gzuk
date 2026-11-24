import SwiftUI
import AppKit

struct ColorPaletteView: View {
    let store: DrawingStore

    private static let presets: [(NSColor, () -> String)] = [
        (.systemRed,    { L.t("빨강", "Red") }),
        (.systemOrange, { L.t("주황", "Orange") }),
        (.systemYellow, { L.t("노랑", "Yellow") }),
        (.systemGreen,  { L.t("초록", "Green") }),
        (.systemBlue,   { L.t("파랑", "Blue") }),
        (.systemPurple, { L.t("보라", "Purple") }),
        (.white,        { L.t("흰색", "White") }),
        (.black,        { L.t("검정", "Black") }),
    ]

    static var presetColors: [NSColor] { presets.map(\.0) }

    var body: some View {
        HStack(spacing: 4) {
            CustomColorButton(store: store,
                              isCustom: !Self.presetColors.contains(where: isSelected))
                .tooltip(L.t("색상 직접 선택", "Custom color"))
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, item in
                let (color, nameFn) = item
                swatch(color)
                    .tooltip(nameFn())
            }
        }
    }

    private func swatch(_ color: NSColor) -> some View {
        Button {
            store.setColor(color)
            // Picking a swatch settles the color — the custom panel has
            // nothing left to do and would only cover the screen.
            CustomColorPanel.shared.close()
        } label: {
            Circle()
                .fill(Color(nsColor: color))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle().stroke(
                        isSelected(color)
                            ? Color.accentColor
                            : Color.primary.opacity(0.15),
                        lineWidth: isSelected(color) ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ color: NSColor) -> Bool {
        CustomColorHistory.same(store.currentColor, color)
    }
}

/// Rainbow swatch in front of the presets. Opens the system color panel;
/// while a non-preset color is active the swatch shows it inside the
/// rainbow ring so the user can see what's selected.
private struct CustomColorButton: View {
    let store: DrawingStore
    let isCustom: Bool

    private static let rainbow = AngularGradient(
        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
        center: .center)

    var body: some View {
        Button {
            CustomColorPanel.shared.open(store: store)
        } label: {
            Group {
                if isCustom {
                    // Selected: thin rainbow ring around the chosen color.
                    // No accent ring like the presets get — it would sit on
                    // top of the rainbow and bury it; ring + solid center is
                    // already distinct from the all-rainbow idle state.
                    Circle()
                        .fill(Color(nsColor: store.currentColor))
                        .padding(3.5)
                        .overlay(Circle().strokeBorder(Self.rainbow, lineWidth: 2.5))
                } else {
                    Circle()
                        .fill(Self.rainbow)
                        .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                }
            }
            .frame(width: 18, height: 18)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Drives the shared NSColorPanel for the custom swatch. Needs to be an
/// NSObject so the panel can call back via target/action.
final class CustomColorPanel: NSObject {
    static let shared = CustomColorPanel()
    private weak var store: DrawingStore?
    /// The rainbow's own color: the last custom color drawn with (persisted,
    /// see CustomColorHistory). Choosing a preset in between doesn't erase
    /// it — pressing the rainbow again switches back to it.
    private var lastCustomColor: NSColor? {
        PreferencesStore.shared.customColor
    }

    func open(store: DrawingStore) {
        self.store = store
        if let custom = lastCustomColor {
            store.setColor(custom)
        }
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.isContinuous = true
        panel.color = store.currentColor
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        // Above the toolbar (.floating + 1) and overlay, or it opens hidden
        // behind them. Follow the user across Spaces like the toolbar does.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 2)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ColorListStore.attachIfNeeded()
        // Open straight on the saved colors once there are any — reusing one
        // is the common case. New colors are a tab away (the wheel), and get
        // added to the palette once drawn with. With nothing saved yet the
        // palette tab would just be empty, so leave the panel's own choice.
        if !ColorListStore.load().isEmpty {
            panel.mode = .colorList
        }
        placeNearToolbar(panel)
        panel.orderFront(nil)
    }

    /// The panel otherwise reopens wherever AppKit last left it — often a far
    /// corner of the screen, away from the swatch that opened it. Drop it
    /// just under the toolbar (or above it when there's no room below),
    /// left-aligned with it and kept inside the screen.
    private func placeNearToolbar(_ panel: NSPanel) {
        guard let toolbar = NSApp.windows.first(where: { $0 is ToolbarWindow && $0.isVisible }),
              let screen = toolbar.screen ?? NSScreen.main else { return }
        let gap: CGFloat = 8
        let bounds = screen.visibleFrame
        let size = panel.frame.size
        var y = toolbar.frame.minY - gap - size.height
        if y < bounds.minY {
            y = toolbar.frame.maxY + gap
        }
        var x = toolbar.frame.minX
        x = min(max(x, bounds.minX), bounds.maxX - size.width)
        y = min(max(y, bounds.minY), bounds.maxY - size.height)
        panel.setFrameOrigin(CGPoint(x: x, y: y))
    }

    /// Called when drawing mode ends, so the panel doesn't float over the
    /// user's work with nothing to apply its color to.
    func close() {
        guard NSColorPanel.sharedColorPanelExists else { return }
        NSColorPanel.shared.orderOut(nil)
    }

    @objc private func colorChanged(_ sender: NSColorPanel) {
        // Not recorded here: the wheel fires for every intermediate value
        // while dragging. The color joins the history once drawn with.
        store?.setColor(sender.color.usingColorSpace(.sRGB) ?? sender.color)
    }
}
