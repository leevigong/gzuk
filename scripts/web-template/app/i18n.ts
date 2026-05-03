// Bilingual string table. Tiny on purpose — we hot-swap between languages
// from a single React state, no i18n framework, no SSR negotiation.
export type Lang = "ko" | "en";

export const strings = {
  nav: {
    download:  { ko: "다운로드", en: "Download" },
    features:  { ko: "기능",     en: "Features" },
    shortcuts: { ko: "단축키",   en: "Shortcuts" },
    github:    { ko: "GitHub",   en: "GitHub" },
  },

  hero: {
    eyebrow: { ko: "macOS · 오픈소스",  en: "macOS · open source" },
    line1:   { ko: "화면 위에 바로,",    en: "Draw and write," },
    line2:   { ko: "그리고 적어요.",     en: "right on your screen." },
    sub: {
      ko: "회의·강의·데모·코드 리뷰 — 어디서든 즉시.",
      en: "Meetings, lectures, demos, code reviews — anywhere, instantly.",
    },
    cta_brew:   { ko: "Homebrew 로 설치", en: "Install with Homebrew" },
    cta_github: { ko: "GitHub 에서 보기", en: "View on GitHub" },
  },

  features: {
    eyebrow: { ko: "기능", en: "Features" },
    title:   { ko: "필요한 만큼.", en: "Everything you need." },
    items: [
      {
        title: { ko: "9개 도구. 한 손에.", en: "Nine tools, one hand" },
        body:  {
          ko: "펜, 형광펜, 직선, 화살표, 사각형, 원, 텍스트, 번호, 지우개.",
          en: "Pen, highlighter, line, arrow, rectangle, circle, text, counter, eraser.",
        },
      },
      {
        title: { ko: "화이트보드 한 번에", en: "Whiteboard instantly" },
        body:  {
          ko: "W 키 한 번이면 화면이 흰 캔버스. 강의·브레인스토밍에 즉시.",
          en: "Tap W to flip the screen into a white canvas — perfect for lectures and brainstorms.",
        },
      },
      {
        title: { ko: "그린 채로 클릭", en: "Click through annotations" },
        body:  {
          ko: "어노테이션은 두고 클릭은 밑의 앱으로 통과. 데모 자연스럽게.",
          en: "Keep annotations on screen while clicks pass through to the app underneath.",
        },
      },
      {
        title: { ko: "한국어 IME 친화", en: "Korean-IME friendly" },
        body:  {
          ko: "한글 입력 켜놔도 P/H/L/A/⌘Z 단축키 그대로 작동.",
          en: "Tool shortcuts (P/H/L/A/⌘Z) keep working even with Korean IME on.",
        },
      },
    ],
  },

  download: {
    eyebrow:    { ko: "다운로드",          en: "Download" },
    title:      { ko: "지금 시작하세요.",  en: "Get it now." },
    brew_label: { ko: "터미널에서:",       en: "In your terminal:" },
    or:         { ko: "또는 직접 다운로드", en: "Or download directly" },
    note: {
      ko: "Apple Developer 인증서 없이 ad-hoc 서명만 됐어요.\nbrew 로 설치하면 Gatekeeper 경고가 자동 처리됩니다.\nZIP 직접 받으시면 우클릭 → 열기 한 번 필요.",
      en: "The app is ad-hoc signed (no Apple Developer ID).\nInstalling via brew skips the Gatekeeper prompt automatically.\nWith the manual ZIP, right-click → Open the first time.",
    },
  },

  shortcuts: {
    eyebrow: { ko: "단축키",     en: "Shortcuts" },
    title:   { ko: "키 하나로.",  en: "One key away." },
    cols: {
      action: { ko: "동작",     en: "Action" },
      key:    { ko: "단축키",   en: "Shortcut" },
    },
    rows: [
      { a: { ko: "그리기 토글 (전역)", en: "Toggle drawing (global)" }, k: "⌃G" },
      { a: { ko: "펜",                 en: "Pen" },                     k: "P" },
      { a: { ko: "형광펜",             en: "Highlighter" },             k: "H" },
      { a: { ko: "직선",               en: "Line" },                    k: "L" },
      { a: { ko: "화살표",             en: "Arrow" },                   k: "A" },
      { a: { ko: "사각형",             en: "Rectangle" },               k: "R" },
      { a: { ko: "원",                 en: "Circle" },                  k: "C" },
      { a: { ko: "텍스트",             en: "Text" },                    k: "T" },
      { a: { ko: "번호",               en: "Counter" },                 k: "N" },
      { a: { ko: "지우개",             en: "Eraser" },                  k: "E" },
      { a: { ko: "커서 (패스스루)",   en: "Cursor (pass-through)" },  k: "S" },
      { a: { ko: "화이트보드",         en: "Whiteboard" },              k: "W" },
      { a: { ko: "툴바 접기/펴기",      en: "Toggle toolbar" },          k: "M" },
      { a: { ko: "되돌리기",           en: "Undo" },                    k: "⌘Z" },
      { a: { ko: "다시하기",           en: "Redo" },                    k: "⌘⇧Z" },
      { a: { ko: "전부 지우기",        en: "Clear all" },               k: "⌘⌫" },
      { a: { ko: "설정",               en: "Settings" },                k: "⌘," },
    ],
  },

  footer: {
    license: { ko: "MIT 오픈소스",          en: "MIT-licensed open source" },
    made:    { ko: "한국에서 만들었어요 🇰🇷", en: "Made in Korea 🇰🇷" },
  },
} as const;

export const t = <T extends { ko: string; en: string }>(s: T, lang: Lang) =>
  s[lang];
