import SwiftUI

struct PassthroughToggleView: View {
    let store: DrawingStore

    var body: some View {
        Button {
            store.togglePassthrough()
        } label: {
            // Same cursor icon for both states — only the background color changes,
            // so users always know where to click to toggle pass-through.
            Image(systemName: "cursorarrow")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(store.isPassthrough
                              ? Color.accentColor.opacity(0.25)
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(store.isPassthrough
              ? "Click-through ON — cursor passes through to apps below"
              : "Click-through OFF — cursor draws on overlay")
    }
}
