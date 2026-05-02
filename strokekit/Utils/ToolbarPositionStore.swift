import AppKit

enum ToolbarPositionStore {
    private static let key = "strokekit.toolbar.lastOrigin"

    static func save(_ origin: CGPoint) {
        // Store as Double explicitly so NSNumber round-trip works on all archs.
        let dict: [String: Double] = ["x": Double(origin.x),
                                      "y": Double(origin.y)]
        UserDefaults.standard.set(dict, forKey: key)
    }

    static func load() -> CGPoint? {
        guard let dict = UserDefaults.standard.dictionary(forKey: key),
              let x = dict["x"] as? Double,
              let y = dict["y"] as? Double else { return nil }
        return CGPoint(x: x, y: y)
    }
}
