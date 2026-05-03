import AppKit

@MainActor
func runApp() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

MainActor.assumeIsolated {
    runApp()
}
