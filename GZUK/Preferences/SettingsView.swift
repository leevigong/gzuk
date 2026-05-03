import SwiftUI

struct SettingsView: View {
    let prefs = PreferencesStore.shared

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
                }
                Toggle(isOn: Binding(
                    get: { prefs.showShortcutHints },
                    set: { prefs.setShowShortcutHints($0) })
                ) {
                    Label("Show shortcut hints on toolbar",
                          systemImage: "character.cursor.ibeam")
                }
            }

            // Hero: the one shortcut everyone needs.
            Section("Hotkey") {
                LabeledContent {
                    KeyCap("⌘ ⇧ ⌥ 7")
                } label: {
                    Label("Toggle drawing mode", systemImage: "paintbrush.pointed")
                }
            }

            // Advanced: tool shortcuts. Compact, gray, foldable.
            Section {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Tool.allCases) { tool in
                            HStack {
                                Image(systemName: tool.symbolName)
                                    .frame(width: 16)
                                    .foregroundColor(.secondary)
                                Text(tool.displayName)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(tool.hotkey).uppercased())
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.top, 2)
                } label: {
                    Label("Tool shortcuts", systemImage: "keyboard")
                        .font(.callout)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 380)
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
