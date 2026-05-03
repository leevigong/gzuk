import SwiftUI

struct WhiteboardToggleView: View {
    let store: DrawingStore

    var body: some View {
        Button {
            store.toggleWhiteboard()
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(store.isWhiteboard
                              ? Color.accentColor.opacity(0.25)
                              : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
