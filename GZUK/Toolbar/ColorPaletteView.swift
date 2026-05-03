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

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, item in
                let (color, nameFn) = item
                Button {
                    store.setColor(color)
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
                .tooltip(nameFn())
            }
        }
    }

    private func isSelected(_ color: NSColor) -> Bool {
        guard let a = store.currentColor.usingColorSpace(.sRGB),
              let b = color.usingColorSpace(.sRGB) else { return false }
        return abs(a.redComponent - b.redComponent) < 0.001 &&
               abs(a.greenComponent - b.greenComponent) < 0.001 &&
               abs(a.blueComponent - b.blueComponent) < 0.001
    }
}
