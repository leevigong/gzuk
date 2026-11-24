import SwiftUI

struct LineWidthPickerView: View {
    let store: DrawingStore
    private static let widths: [CGFloat] = [2, 4, 6, 10]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Self.widths, id: \.self) { w in
                Button {
                    store.setLineWidth(w)
                } label: {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: dotSize(for: w), height: dotSize(for: w))
                        .frame(width: 22, height: 22)   // hit-target
                        // `.plain` buttons only hit-test drawn pixels, so
                        // without this only the dot itself was clickable
                        // (~5pt across for the thinnest width).
                        .contentShape(Rectangle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(store.currentLineWidth == w
                                        ? Color.accentColor : .clear,
                                        lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .tooltip(L.t("굵기 \(Int(w))pt", "Width \(Int(w))pt"))
            }
        }
    }

    private func dotSize(for w: CGFloat) -> CGFloat {
        // Map 2/4/6/10 → ~ 4/6/8/12 visual diameter
        4 + w * 0.8
    }
}
