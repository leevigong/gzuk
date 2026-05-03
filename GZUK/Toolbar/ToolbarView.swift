import SwiftUI

struct ToolbarView: View {
    let store: DrawingStore

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(Tool.allCases) { tool in
                    ToolButton(tool: tool, store: store)
                }
            }

            Divider()
            HStack(spacing: 10) {
                ColorPaletteView(store: store)
                Divider().frame(height: 18)
                LineWidthPickerView(store: store)
            }

            Divider()
            HStack(spacing: 10) {
                WhiteboardToggleView(store: store)
                PassthroughToggleView(store: store)
                Divider().frame(height: 18)
                Button { store.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 28)
                }.buttonStyle(.plain).help("Undo")
                Button { store.redo() } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 28)
                }.buttonStyle(.plain).help("Redo")
                Button { store.clear() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 28)
                }.buttonStyle(.plain).help("Clear")
                Button { store.toggle() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.secondary)
                }.buttonStyle(.plain).help("Close drawing mode (⌘⇧⌥7)")
                    .padding(.leading, 6)
            }

            // Visual grip indicator at the bottom — actual drag is handled
            // by the DragHandleView placed behind the buttons.
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.primary.opacity(0.25))
                .frame(width: 36, height: 4)
                .allowsHitTesting(false)
        }
        .padding(8)
        // Drag layer behind the buttons. Its frame is whatever the VStack
        // is sized to — no infinite expansion.
        .background(DragHandleView())
        .background(.regularMaterial)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
        )
        .frame(width: 380)
    }
}
