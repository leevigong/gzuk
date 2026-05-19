import SwiftUI

struct ToolbarView: View {
    let store: DrawingStore

    var body: some View {
        Group {
            if store.isToolbarCollapsed {
                CollapsedToolbarView(store: store)
            } else {
                ExpandedToolbarView(store: store)
            }
        }
    }
}

private struct ExpandedToolbarView: View {
    let store: DrawingStore

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(Tool.allCases) { tool in
                    ToolButton(tool: tool, store: store)
                        .tooltip("\(tool.displayName) (\(String(tool.hotkey).uppercased()))")
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
                    .tooltip(store.isWhiteboard
                             ? L.t("화이트보드 끄기 (W)", "Whiteboard off (W)")
                             : L.t("화이트보드 (W)", "Whiteboard (W)"))
                PassthroughToggleView(store: store)
                    .tooltip(store.isPassthrough
                             ? L.t("커서 (S)", "Cursor (S)")
                             : L.t("그리기 (S)", "Draw (S)"))
                Divider().frame(height: 18)
                Button { store.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 28)
                }.buttonStyle(.plain)
                    .tooltip(L.t("실행 취소 (⌘Z)", "Undo (⌘Z)"))
                Button { store.redo() } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 28)
                }.buttonStyle(.plain)
                    .tooltip(L.t("다시 실행 (⌘⇧Z)", "Redo (⌘⇧Z)"))
                Button { store.clear() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 28)
                }.buttonStyle(.plain)
                    .tooltip(L.t("모두 지우기 (⌥⌫)", "Clear all (⌥⌫)"))
                Button { store.toggleToolbarCollapsed() } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.secondary)
                }.buttonStyle(.plain)
                    .padding(.leading, 6)
                    .tooltip(L.t("접기 (M)", "Minimize (M)"))
                Button { store.toggle() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.secondary)
                }.buttonStyle(.plain)
                    .tooltip(L.t("닫기 (⌥G)", "Close (⌥G)"))
            }

            // Visual grip indicator at the bottom — actual drag is handled
            // by the DragHandleView placed behind the buttons.
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.primary.opacity(0.25))
                .frame(width: 36, height: 4)
                .allowsHitTesting(false)
        }
        .padding(8)
        .background(DragHandleView())
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
        )
        .frame(width: 380)
    }
}

private struct CollapsedToolbarView: View {
    let store: DrawingStore

    private var modeSymbol: String {
        store.isPassthrough ? "cursorarrow" : store.currentTool.symbolName
    }

    private var modeColor: AnyShapeStyle {
        if store.isPassthrough { return AnyShapeStyle(.primary) }
        if store.currentTool == .eraser { return AnyShapeStyle(.secondary) }
        return AnyShapeStyle(Color(nsColor: store.currentColor))
    }

    var body: some View {
        HStack(spacing: 4) {
            Button { store.togglePassthrough() } label: {
                Image(systemName: modeSymbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(modeColor)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(store.isPassthrough
                                  ? Color.accentColor.opacity(0.25)
                                  : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .tooltip(store.isPassthrough
                     ? L.t("커서 (S)", "Cursor (S)")
                     : L.t("그리기 (S)", "Draw (S)"))

            Button { store.toggleToolbarCollapsed() } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
            }.buttonStyle(.plain)
                .tooltip(L.t("펼치기 (M)", "Expand (M)"))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(DragHandleView())
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}
