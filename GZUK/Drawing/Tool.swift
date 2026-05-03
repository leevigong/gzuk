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

    var displayName: String {
        switch self {
        case .pen:         return "Pen"
        case .highlighter: return "Highlighter"
        case .line:        return "Line"
        case .arrow:       return "Arrow"
        case .rectangle:   return "Rectangle"
        case .circle:      return "Circle"
        case .text:        return "Text"
        case .counter:     return "Counter"
        case .eraser:      return "Eraser"
        }
    }
}
