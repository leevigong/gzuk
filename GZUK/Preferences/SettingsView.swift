import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label(L.t("일반", "General"), systemImage: "gearshape") }
            ShortcutsTab()
                .tabItem { Label(L.t("단축키", "Shortcuts"), systemImage: "keyboard") }
        }
        .frame(width: 440, height: 380)
    }
}

// MARK: - General

private struct GeneralTab: View {
    let prefs = PreferencesStore.shared

    var body: some View {
        Form {
            Section(L.t("시작", "Startup")) {
                Toggle(isOn: Binding(
                    get: { prefs.launchAtLogin },
                    set: { prefs.setLaunchAtLogin($0) })
                ) {
                    Label(L.t("로그인 시 자동 실행", "Launch at login"),
                          systemImage: "power")
                }
            }

            Section(L.t("모양", "Appearance")) {
                LabeledContent {
                    HStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { prefs.toolbarOpacity },
                            set: { prefs.setToolbarOpacity($0) }),
                               in: 0.3...1.0)
                            .frame(width: 140)
                        Text("\(Int(prefs.toolbarOpacity * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                } label: {
                    Label(L.t("툴바 투명도", "Toolbar opacity"),
                          systemImage: "slider.horizontal.3")
                }
            }

            Section(L.t("언어", "Language")) {
                Picker(selection: Binding(
                    get: { prefs.language },
                    set: { prefs.setLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                } label: { EmptyView() }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Shortcuts

private struct ShortcutsTab: View {
    var body: some View {
        Form {
            Section {
                LabeledContent {
                    KeyCap("⌥G")
                } label: {
                    Label(L.t("그리기 모드 토글", "Toggle drawing mode"),
                          systemImage: "paintbrush.pointed")
                }
            } header: {
                Text(L.t("전역", "Global"))
            } footer: {
                Text(L.t("어디서든 ⌥G로 그리기 모드를 켜고 끌 수 있어요.",
                         "Press ⌥G anywhere to toggle drawing mode."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(L.t("도구", "Tools")) {
                ForEach(Tool.allCases) { tool in
                    LabeledContent {
                        KeyCap(String(tool.hotkey).uppercased())
                            .font(.system(.caption, design: .monospaced))
                    } label: {
                        Label(tool.displayName, systemImage: tool.symbolName)
                    }
                }
            }

            Section(L.t("기타", "Other")) {
                LabeledContent {
                    KeyCap("S")
                } label: {
                    Label(L.t("커서 / 그리기 토글", "Toggle cursor / draw"),
                          systemImage: "cursorarrow")
                }
                LabeledContent {
                    KeyCap("W")
                } label: {
                    Label(L.t("화이트보드 토글", "Toggle whiteboard"),
                          systemImage: "square.and.pencil")
                }
                LabeledContent {
                    KeyCap("M")
                } label: {
                    Label(L.t("툴바 접기 / 펼치기", "Minimize / expand toolbar"),
                          systemImage: "arrow.down.right.and.arrow.up.left")
                }
                // Only the ⌥ set is advertised. ⌘Z / ⌘⇧Z / ⌥⌫ still work
                // (see AppDelegate.installKeyboardShortcuts) but stay
                // undocumented so the ⌥D/⌥G/⌥Z cluster is what users learn.
                LabeledContent {
                    KeyCap("⌥Z")
                } label: {
                    Label(L.t("실행 취소", "Undo"),
                          systemImage: "arrow.uturn.backward")
                }
                LabeledContent {
                    KeyCap("⌥⇧Z")
                } label: {
                    Label(L.t("다시 실행", "Redo"),
                          systemImage: "arrow.uturn.forward")
                }
                LabeledContent {
                    KeyCap("⌥D")
                } label: {
                    Label(L.t("모두 지우기", "Clear all"),
                          systemImage: "trash")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

}

// MARK: - KeyCap

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
