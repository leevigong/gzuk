# 그려적어 (GZUK) 퍼블리싱 체크리스트

> 출시까지 남은 작업을 추적하는 문서. 끝낸 항목은 `[x]` 로 체크.

---

## 1. 코드 안정화 (필수)

- [x] 메모리 leak 체크 — 0 leaks 확인 (NSEvent monitor 정리 완료, AppDelegate.keyMonitor)
- [x] 한국어/English 모드 텍스트 검증 — `.help()` 잔재 제거 (Passthrough/Whiteboard toggles)
- [x] 첫 실행 권한 요청 흐름 — unsandboxed, 별도 권한 불필요 확인
- [x] **멀티 모니터 동작 검증** — 옵션 A 채택: 커서 있는 모니터 하나만 덮음 (현재 동작 유지). 모든 모니터 오버레이(C)는 v1.x follow-up.
- [x] **엣지 케이스 테스트**
  - [x] 그리기 모드 켠 채로 절전 → wake — stroke 보존, ⌃G/단축키/툴바 정상
  - [x] 모니터 연결/해제 도중 토글 — `didChangeScreenParametersNotification` 핸들러 추가 (Overlay 재배치, Toolbar 화면 밖이면 기본 위치로 snap)
  - [x] 200+ shapes 누적 시 성능 — 400개에서도 매끄러움 (DEBUG ⌃⇧S 스트레스 테스트, `#if DEBUG` 로 유지)
  - [x] 풀스크린 앱 위에서 동작 확인 — `.fullScreenAuxiliary` 로 정상 표시
  - ~~Fast user switch~~ — skip (borderless floating window 는 macOS 가 자동 복원, 위험 낮음)

---

## 2. 코드 서명 + 공증 (배포 필수)

- [ ] Apple Developer 계정 ($99/년) 가입 — **가장 시급, 1주일 소요**
- [ ] Developer ID Application 인증서 발급
- [ ] Xcode Hardened Runtime 활성화
- [ ] `xcodebuild archive` → `.app` 추출 → `codesign`
- [ ] `xcrun notarytool submit` → Apple 공증
- [ ] `xcrun stapler staple` → 공증 스티커 부착
- [ ] Gatekeeper 통과 확인 (다른 Mac 에서 실행 테스트)

---

## 3. 배포 채널

### A. Homebrew Cask (1순위 추천)

- [ ] DMG 또는 ZIP 만들기
- [ ] GitHub Release 업로드
- [ ] homebrew-cask 레포 PR 또는 자체 tap 운영
- [ ] postflight 에서 Spotlight 키워드(그적/그려적어/GZUK) 자동 등록

### B. 직접 배포 (DMG)

- [ ] `create-dmg` 로 DMG 빌드
- [ ] 랜딩 페이지 다운로드 링크
- [ ] Sparkle 등 auto-update (선택)

### C. Mac App Store (보류)

- [ ] Sandbox 리팩토링 (xattr 등 차단됨)
- [ ] 화면 녹화 권한 사유 작성
- [ ] App Store Connect 메타데이터
- → **단기 비추천**

---

## 4. 마케팅 자산

- [ ] 랜딩 페이지 (도메인 + 스크린샷 + 다운로드 버튼)
- [ ] README 다운로드 링크/사용법 갱신
- [ ] Accent 아이콘 버전 활용 (빨간 그려/적어)
- [ ] 데모 GIF / 동영상
- [ ] ProductHunt 페이지
- [ ] 한국 커뮤니티 글 (긱뉴스/클리앙/뽐뿌/개발자 슬랙)
- [ ] Twitter / Instagram 출시 포스트

---

## 5. 법적 / 운영

- [x] MIT LICENSE
- [ ] Privacy Policy (데이터 수집 안 함 명시)
- [ ] GitHub Issues 버그 리포트 루트
- [ ] v1.0 으로 버전 bump (현재 v0.5)

---

## 6. 분석 / 모니터링 (선택)

- [ ] TelemetryDeck (익명 사용량, GDPR 친화)
- [ ] Sentry / Crashlytics 크래시 리포트

---

## 🎯 추천 출시 시퀀스

1. Homebrew Cask 로 **v0.9 베타** — 개발자 피드백
2. 약 한 달 안정화
3. 랜딩 페이지 + DMG + ProductHunt **v1.0 정식**
4. (선택) Mac App Store 는 v1.x 별도 트랙

## 🔥 가장 시급

**Apple Developer 계정 + Developer ID 서명.** 신청에 1주일 이상 걸리니 다른 작업과 병행해서 즉시 시작.
