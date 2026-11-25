import SwiftUI

/// Toolbar control for the stroke outline, next to the widths since it's the
/// same kind of setting: how strokes are drawn. The button previews pen +
/// outline color together; clicking it opens a popover with the same choices
/// as Settings. O toggles it without the popover.
struct OutlineToggleView: View {
    let store: DrawingStore
    let prefs = PreferencesStore.shared
    @State private var showsPicker = false

    var body: some View {
        Button {
            showsPicker.toggle()
        } label: {
            OutlineIcon(store: store, prefs: prefs)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(prefs.outlineEnabled
                              ? Color.accentColor.opacity(0.25)
                              : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showsPicker, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L.t("선 테두리", "Stroke outline"))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                OutlineSwatches(prefs: prefs) { showsPicker = false }
            }
            .padding(12)
        }
    }
}

/// Live preview of the next stroke: a dot in the pen color inside a ring in
/// the outline color, so the toolbar shows both at a glance. Off: the pen
/// dot with a faint dashed ring.
private struct OutlineIcon: View {
    let store: DrawingStore
    let prefs: PreferencesStore

    var body: some View {
        ZStack {
            if prefs.outlineEnabled {
                Circle().fill(Color(nsColor: prefs.outlineColor))
            } else {
                Circle().strokeBorder(Color.secondary.opacity(0.6),
                                      style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            }
            Circle()
                .fill(Color(nsColor: store.currentColor))
                .padding(4.5)
        }
        // Keeps a white ring/pen visible against the light toolbar.
        .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 0.5))
        .frame(width: 18, height: 18)
    }
}

// MARK: - Outline swatches

/// None + preset colors in one row — used both in Settings and in the
/// toolbar's outline popover. Deliberately not a ColorPicker: that shares the
/// system color panel with the rainbow swatch, which positions it next to
/// the toolbar (on a dual-monitor setup, often a different screen).
struct OutlineSwatches: View {
    let prefs: PreferencesStore
    /// Called after any pick, e.g. to close the popover hosting the row.
    var onPick: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            Button {
                prefs.setOutlineEnabled(false)
                onPick()
            } label: {
                Image(systemName: "nosign")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().strokeBorder(Color.primary, lineWidth: 2)
                            .opacity(prefs.outlineEnabled ? 0 : 1)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(L.t("테두리 없음", "No outline"))

            ForEach(Array(ColorPaletteView.presetColors.enumerated()), id: \.offset) { _, color in
                let selected = prefs.outlineEnabled
                    && CustomColorHistory.same(prefs.outlineColor, color)
                Button {
                    prefs.setOutlineColor(color)
                    prefs.setOutlineEnabled(true)
                    onPick()
                } label: {
                    SwatchCircle(color: color, selected: selected)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
