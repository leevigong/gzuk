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
}
