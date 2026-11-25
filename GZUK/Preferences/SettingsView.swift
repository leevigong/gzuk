import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label(L.t("일반", "General"), systemImage: "gearshape") }
            ShortcutsTab()
                .tabItem { Label(L.t("단축키", "Shortcuts"), systemImage: "keyboard") }
        }
        .frame(width: 440, height: 520)
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

            Section {
                Toggle(isOn: Binding(
                    get: { prefs.keepDrawingsOnExit },
                    set: { prefs.setKeepDrawingsOnExit($0) })
                ) {
                    Label(L.t("그리기 모드를 꺼도 그림 유지",
                              "Keep drawings after exiting"),
                          systemImage: "pin")
                }
                LabeledContent {
                    OutlineSwatches(prefs: prefs)
                } label: {
                    Label(L.t("선 테두리", "Stroke outline"),
                          systemImage: "circle.dashed")
                }
            } header: {
                Text(L.t("그리기", "Drawing"))
            } footer: {
                Text(L.t("그림을 유지하면 ⌥G로 나온 뒤에도 표시가 남고, 클릭은 아래 앱으로 그대로 전달돼요. 테두리는 ⊘로 끌 수 있고, 새로 그리는 선부터 적용돼요.",
                         "Kept drawings stay on screen after ⌥G and let clicks through to the app below. Pick ⊘ for no outline; it applies to new strokes."))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                LabeledContent {
                    KeyCap("⌥V")
                } label: {
                    Label(L.t("누르는 동안만 그리기", "Draw while held"),
                          systemImage: "hand.point.up.left")
                }
            } header: {
                Text(L.t("전역", "Global"))
            } footer: {
                Text(L.t("어디서든 ⌥G로 그리기 모드를 켜고 끌 수 있어요. ⌥V는 누르고 있는 동안만 켜져요.",
                         "Press ⌥G anywhere to toggle drawing mode. ⌥V turns it on only while held."))
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

// MARK: - Outline swatches

/// "None" plus the toolbar's preset colors, in one row. Replaces a separate
/// on/off toggle + ColorPicker: the picker shared the system color panel with
/// the toolbar's rainbow swatch, which positions it next to the toolbar — on
/// a dual-monitor setup that's often a different screen from Settings.
private struct OutlineSwatches: View {
    let prefs: PreferencesStore

    var body: some View {
        HStack(spacing: 4) {
            Button {
                prefs.setOutlineEnabled(false)
            } label: {
                Image(systemName: "nosign")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 18, height: 18)
                    .overlay(ring(selected: !prefs.outlineEnabled))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(L.t("테두리 없음", "No outline"))

            ForEach(Array(ColorPaletteView.presetColors.enumerated()), id: \.offset) { _, color in
                let selected = prefs.outlineEnabled
                    && CustomColorHistory.same(prefs.outlineColor, color)
                Button {
                    prefs.setOutlineColor(color)
                    prefs.setOutlineEnabled(true)
                } label: {
                    Circle()
                        .fill(Color(nsColor: color))
                        .frame(width: 18, height: 18)
                        .overlay(ring(selected: selected))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func ring(selected: Bool) -> some View {
        Circle().stroke(selected ? Color.accentColor : Color.primary.opacity(0.15),
                        lineWidth: selected ? 2 : 1)
    }
}
