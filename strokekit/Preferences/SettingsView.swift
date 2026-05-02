import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView(prefs: PreferencesStore.shared)
                .tabItem { Label("General", systemImage: "gearshape") }

            ShortcutSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 460, height: 280)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @Bindable var prefs: PreferencesStore

    var body: some View {
        Form {
            Section("Startup") {
                Toggle(isOn: Binding(
                    get: { prefs.launchAtLogin },
                    set: { prefs.setLaunchAtLogin($0) })
                ) {
                    Label("Launch at login", systemImage: "power")
                }
            }

            Section("Appearance") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Toolbar opacity", systemImage: "slider.horizontal.3")
                    HStack {
                        Slider(value: Binding(
                            get: { prefs.toolbarOpacity },
                            set: { prefs.setToolbarOpacity($0) }),
                               in: 0.3...1.0)
                        Text("\(Int(prefs.toolbarOpacity * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    Text("Lower opacity makes the toolbar less intrusive while you draw.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Shortcuts

struct ShortcutSettingsView: View {
    var body: some View {
        Form {
            Section("Main hotkey") {
                LabeledContent {
                    KeyCap("⌘ ⇧ ⌥ 7")
                } label: {
                    Label("Toggle drawing mode", systemImage: "paintbrush.pointed")
                }
                Text("Customizable hotkey is planned for the next release. Combinations with ⌘⇧⌥ rarely conflict with other apps.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("In-canvas shortcuts") {
                LabeledContent { KeyCap("⌘ Z") }
                    label:        { Label("Undo", systemImage: "arrow.uturn.backward") }
                LabeledContent { KeyCap("⇧ ⌘ Z") }
                    label:        { Label("Redo", systemImage: "arrow.uturn.forward") }
                LabeledContent { KeyCap("⇧ ↵") }
                    label:        { Label("Newline in text", systemImage: "return") }
                LabeledContent { KeyCap("↵") }
                    label:        { Label("Commit text", systemImage: "checkmark") }
                LabeledContent { KeyCap("esc") }
                    label:        { Label("Cancel text edit", systemImage: "xmark") }
            }
        }
        .formStyle(.grouped)
    }
}

private struct KeyCap: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
