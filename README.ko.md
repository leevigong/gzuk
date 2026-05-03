# 그려적어 (GZUK)

> [🇺🇸 English README](README.md)

화면 위에 바로, 그리고 적어요.
어떤 macOS 화면이든 `⌃G` 한 번이면 어노테이션이 시작됩니다 — 회의, 강의,
데모, 코드 리뷰.

→ 자세한 소개와 데모: **https://gzuk-app.vercel.app**

## 설치

```bash
brew install --cask leevigong/gzuk/gzuk
```

Apple Developer 인증서 없이 ad-hoc 서명만 됐어요. cask 의 postflight 가
다운로드 quarantine 속성을 자동으로 제거해서 첫 실행 시 Gatekeeper 경고가
뜨지 않습니다 — 메인테이너 신뢰가 전제된 설치 방식입니다.

## 소스에서 빌드

Xcode 16+, macOS 14+ 필요.

```bash
git clone https://github.com/leevigong/gzuk
cd gzuk
open GZUK.xcodeproj
```

`⌘R` 로 실행. 별도 시스템 권한 필요 없음 (`LSUIElement`, 샌드박스 미사용).

## 라이선스

MIT — [LICENSE](LICENSE) 참조. 번들 폰트 (Gowun Dodum) 는 OFL 1.1.
