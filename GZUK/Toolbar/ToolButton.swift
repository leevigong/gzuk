import SwiftUI

struct ToolButton: View {
    let tool: Tool
    let store: DrawingStore
    private let prefs = PreferencesStore.shared

    var body: some View {
        Button {
            store.setTool(tool)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: dynamicSymbolName)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 30, height: 30)

                if prefs.showShortcutHints {
                    Text(String(tool.hotkey).uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .opacity(0.9)
                        .padding(.trailing, 1)
                        .padding(.bottom, 1)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(store.currentTool == tool
                          ? Color.accentColor.opacity(0.25)
                          : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .help("\(tool.displayName) (\(String(tool.hotkey).uppercased()))")
    }

    /// Counter shows the next number that would be placed on click
    /// (e.g. `2.circle` after the user drops a "1"). SF Symbols cover 0–50.
    private var dynamicSymbolName: String {
        if tool == .counter {
            let n = store.nextCounterNumber
            if n >= 0 && n <= 50 {
                return "\(n).circle"
            }
            return "circle"
        }
        return tool.symbolName
    }
}
