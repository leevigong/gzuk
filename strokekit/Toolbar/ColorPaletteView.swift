import SwiftUI
import AppKit

struct ColorPaletteView: View {
    let store: DrawingStore

    private static let presets: [(NSColor, String)] = [
        (.systemRed, "Red"),
        (.systemOrange, "Orange"),
        (.systemYellow, "Yellow"),
        (.systemGreen, "Green"),
        (.systemBlue, "Blue"),
        (.systemPurple, "Purple"),
        (.white, "White"),
        (.black, "Black"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, item in
                let (color, name) = item
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
                .help(name)
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
