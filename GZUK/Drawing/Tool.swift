import Foundation

enum Tool: String, CaseIterable, Identifiable {
    case pen
    case highlighter
    case line
    case arrow
    case rectangle
    case circle
    case text
    case counter
    case eraser

    var id: String { rawValue }

    /// SF Symbol used in the toolbar.
    var symbolName: String {
        switch self {
        case .pen:         return "pencil.tip"
        case .highlighter: return "highlighter"
        case .line:        return "line.diagonal"
        case .arrow:       return "arrow.up.right"
        case .rectangle:   return "rectangle"
        case .circle:      return "circle"
        case .text:        return "textformat"
        case .counter:     return "1.circle"
        case .eraser:      return "eraser"
        }
    }

    /// Single-key shortcut (no modifiers) shown in tooltips and accepted by
    /// the canvas when text editing isn't active.
    var hotkey: Character {
        switch self {
        case .pen:         return "p"
        case .highlighter: return "h"
        case .line:        return "l"
        case .arrow:       return "a"
        case .rectangle:   return "r"
        case .circle:      return "c"
        case .text:        return "t"
        case .counter:     return "n"   // N for number
        case .eraser:      return "e"
        }
    }

    /// Hardware keyCode (US-QWERTY layout positions). Used for matching
    /// the shortcut regardless of active input method (e.g. Korean IME
    /// would otherwise convert P → ㅔ, T → ㅅ).
    var keyCode: UInt16 {
        switch self {
        case .pen:         return 35  // P
        case .highlighter: return 4   // H
        case .line:        return 37  // L
        case .arrow:       return 0   // A
        case .rectangle:   return 15  // R
        case .circle:      return 8   // C
        case .text:        return 17  // T
        case .counter:     return 45  // N
        case .eraser:      return 14  // E
        }
    }

    var displayName: String {
        switch self {
        case .pen:         return L.t("펜", "Pen")
        case .highlighter: return L.t("형광펜", "Highlighter")
        case .line:        return L.t("선", "Line")
        case .arrow:       return L.t("화살표", "Arrow")
        case .rectangle:   return L.t("사각형", "Rectangle")
        case .circle:      return L.t("원", "Circle")
        case .text:        return L.t("텍스트", "Text")
        case .counter:     return L.t("번호", "Counter")
        case .eraser:      return L.t("지우개", "Eraser")
        }
    }
}
