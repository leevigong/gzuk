"use client";

import { useEffect, useRef, useState } from "react";
import { Wifi } from "lucide-react";
import { strings, t, type Lang } from "./i18n";

const GITHUB_REPO = "https://github.com/leevigong/gzuk";
const RELEASE_ZIP = "https://github.com/leevigong/gzuk/releases/latest";
const BREW_CMD    = "brew install --cask leevigong/gzuk/gzuk";

// Section eyebrow style. Features is the visual anchor (accent red); the
// utility sections (Download, Shortcuts) stay subtle gray so the page has
// a single point of color emphasis.
const eyebrowBase = "text-base sm:text-lg tracking-[0.2em] font-medium";
const eyebrowAccent = `${eyebrowBase} text-accent`;
const eyebrowMuted  = `${eyebrowBase} opacity-50`;

export default function HomePage() {
  const [lang, setLang] = useState<Lang>("ko");

  // Apple-style fade-up reveal as sections enter the viewport.
  useEffect(() => {
    const els = document.querySelectorAll<HTMLElement>(".reveal");
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            e.target.classList.add("in");
            io.unobserve(e.target);
          }
        }
      },
      { threshold: 0.15 }
    );
    els.forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  return (
    <main className="min-h-screen overflow-x-hidden">
      <Nav lang={lang} setLang={setLang} />
      <Hero lang={lang} />
      <DemoFrame lang={lang} />
      <Features lang={lang} />
      <Download lang={lang} />
      <Shortcuts lang={lang} />
      <Footer lang={lang} />
    </main>
  );
}

function Nav({ lang, setLang }: { lang: Lang; setLang: (l: Lang) => void }) {
  return (
    <nav className="border-b border-black/5 dark:border-white/[0.06]">
      <div className="mx-auto max-w-6xl px-5 sm:px-6 h-12 flex items-center justify-between text-[13px]">
        <a href="#top" className="flex items-center gap-2.5">
          {/* Stacked dual-tone wordmark — mirrors the app icon: "그려" red
              + stroke-bold on top, "적어" regular underneath. */}
          <span className="inline-flex flex-col leading-[0.95] text-[14px] tracking-tight">
            <span
              className="text-accent"
              style={{ WebkitTextStroke: "0.025em currentColor" }}
            >
              그려
            </span>
            <span className="font-normal">적어</span>
          </span>
          <span className="tracking-widest text-[11px] font-bold">GZUK</span>
        </a>
        {/* Mobile: only Download + lang toggle. The rest is reachable
            by scroll, so hiding them keeps the bar uncluttered. */}
        <div className="flex items-center gap-4 sm:gap-7">
          <a href="#features"  className="opacity-70 hover:opacity-100 transition hidden sm:inline">{t(strings.nav.features,  lang)}</a>
          <a href="#shortcuts" className="opacity-70 hover:opacity-100 transition hidden sm:inline">{t(strings.nav.shortcuts, lang)}</a>
          <a href="#download"  className="opacity-70 hover:opacity-100 transition">{t(strings.nav.download,  lang)}</a>
          <a href={GITHUB_REPO} target="_blank" rel="noreferrer" className="opacity-70 hover:opacity-100 transition hidden sm:inline">{t(strings.nav.github, lang)}</a>
          <LangToggle lang={lang} setLang={setLang} />
        </div>
      </div>
    </nav>
  );
}

function LangToggle({ lang, setLang }: { lang: Lang; setLang: (l: Lang) => void }) {
  return (
    <div className="flex rounded-full border border-black/15 dark:border-white/15 overflow-hidden text-[11px]">
      {(["ko", "en"] as Lang[]).map((l) => (
        <button
          key={l}
          onClick={() => setLang(l)}
          className={`px-2.5 py-0.5 transition ${
            l === lang
              ? "bg-[var(--fg)] text-[var(--bg)]"
              : "opacity-50 hover:opacity-100"
          }`}
        >
          {l === "ko" ? "한" : "EN"}
        </button>
      ))}
    </div>
  );
}

/** Stacked "그/적" mini wordmark used in nav and footer. Mirrors the
 *  brand treatment from the big hero wordmark — "그" gets a stroke-based
 *  bold so it visibly outweighs "적", which Gowun Dodum's single-weight
 *  font can't otherwise do. */
function Glyph({ small = false }: { small?: boolean }) {
  return (
    <span
      className={`inline-flex flex-col leading-[0.95] font-brand ${
        small ? "text-[15px]" : "text-[18px]"
      }`}
    >
      <span
        className="text-accent"
        style={{ WebkitTextStroke: "0.025em currentColor" }}
      >
        그
      </span>
      <span className="font-normal">적</span>
    </span>
  );
}

function Hero({ lang }: { lang: Lang }) {
  return (
    <section id="top" className="px-5 sm:px-6 pt-20 sm:pt-32 pb-14 sm:pb-20 text-center">
      <div className="mx-auto max-w-5xl">
        <p className="reveal text-xs tracking-[0.2em] opacity-50 mb-8">
          {t(strings.hero.eyebrow, lang)}
        </p>

        {/* Brand wordmark — Gowun Dodum, the only place we keep handwriting
            feel. Mirrors the app icon: "그려" is accent red AND visibly
            bolder via -webkit-text-stroke (Gowun Dodum has no real bold
            weight); "적어" stays regular. */}
        <div className="reveal flex flex-col items-center font-brand leading-[0.95] mb-12 text-[clamp(4rem,12vw,8rem)]">
          <span
            className="text-accent"
            style={{ WebkitTextStroke: "0.02em currentColor" }}
          >
            그려
          </span>
          <span className="font-normal">적어</span>
        </div>

        <h1 className="reveal text-display tracking-tightest">
          <span className="block opacity-60">{t(strings.hero.line1, lang)}</span>
          <span className="block">{t(strings.hero.line2, lang)}</span>
        </h1>

        <p className="reveal mt-8 text-[17px] sm:text-[19px] opacity-65 leading-relaxed max-w-prose mx-auto">
          {t(strings.hero.sub, lang)}
        </p>

        <div className="reveal mt-12 flex flex-wrap justify-center gap-3">
          <a
            href="#download"
            className="px-6 py-3 rounded-full bg-[var(--fg)] text-[var(--bg)] font-medium hover:opacity-90 transition"
          >
            {t(strings.hero.cta_brew, lang)}
          </a>
          <a
            href={GITHUB_REPO}
            target="_blank"
            rel="noreferrer"
            className="px-6 py-3 rounded-full border border-black/15 dark:border-white/20 hover:bg-black/5 dark:hover:bg-white/5 transition"
          >
            {t(strings.hero.cta_github, lang)}
          </a>
        </div>
      </div>
    </section>
  );
}

function DemoFrame({ lang }: { lang: Lang }) {
  return (
    <section className="px-5 sm:px-6 pb-20 sm:pb-32">
      <div className="reveal mx-auto max-w-5xl">
        <div className="relative aspect-[16/10] rounded-3xl overflow-hidden shadow-[0_40px_100px_-20px_rgba(80,30,150,0.45)] border border-black/[0.06]">
          <DemoScene lang={lang} />
        </div>
        <div className="mt-8 flex justify-center">
          <a
            href="#download"
            className="group inline-flex items-center gap-2.5 px-7 sm:px-8 py-3.5 sm:py-4 rounded-full bg-accent text-white text-[16px] sm:text-[18px] font-semibold shadow-[0_10px_28px_-10px_rgba(255,45,45,0.45)] hover:opacity-80 hover:-translate-y-0.5 transition"
          >
            <span className="opacity-85 font-medium">
              {t(strings.demo.note_pre, lang)}
            </span>
            <span className="group-hover:translate-x-0.5 transition">
              {t(strings.demo.note_link, lang)}
            </span>
          </a>
        </div>
      </div>
    </section>
  );
}

/**
 * Mocked-up "in use" hero: a Keynote-style window being annotated. Slide
 * is intentionally spare — heading + SVG bar chart — so the GZUK overlay
 * (red circle, arrow, handwritten note) is the focal point. Bars use SVG
 * so percentage heights render reliably (the earlier flex/h-[%] approach
 * was fragile inside nested absolute containers).
 */
// ----- Static annotation sampling --------------------------------------
// The pre-rendered red marks on the slide (underline, Q4 ellipse, arrow,
// "Q4 가 핵심!" label) are SVG so they stay sharp, but we want the eraser
// to swallow them whole — same as user-drawn pen strokes. Each annotation
// is described by a list of sample points in SVG viewBox coordinates
// (1000×560). On erase we convert the eraser's CSS-pixel position back
// into viewBox space and do a vertex hit-test against these samples.

const sampleQuadratic = (p0: Pt, p1: Pt, p2: Pt, n: number): Pt[] => {
  const out: Pt[] = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n, u = 1 - t;
    out.push({
      x: u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x,
      y: u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y,
    });
  }
  return out;
};
const sampleCubic = (p0: Pt, p1: Pt, p2: Pt, p3: Pt, n: number): Pt[] => {
  const out: Pt[] = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n, u = 1 - t;
    out.push({
      x: u * u * u * p0.x + 3 * u * u * t * p1.x + 3 * u * t * t * p2.x + t * t * t * p3.x,
      y: u * u * u * p0.y + 3 * u * u * t * p1.y + 3 * u * t * t * p2.y + t * t * t * p3.y,
    });
  }
  return out;
};
const sampleRotatedEllipse = (
  cx: number, cy: number, rx: number, ry: number, deg: number, n: number,
): Pt[] => {
  const cos = Math.cos((deg * Math.PI) / 180);
  const sin = Math.sin((deg * Math.PI) / 180);
  const out: Pt[] = [];
  for (let i = 0; i < n; i++) {
    const t = (i / n) * Math.PI * 2;
    const ex = rx * Math.cos(t);
    const ey = ry * Math.sin(t);
    out.push({ x: cx + ex * cos - ey * sin, y: cy + ex * sin + ey * cos });
  }
  return out;
};

type StaticAnnotationId = "underline" | "ellipse" | "arrow" | "text";
const STATIC_ANNOTATIONS: { id: StaticAnnotationId; vbPoints: Pt[] }[] = [
  // "M 232 210 Q 260 202 290 207 T 350 210"  — wobbly underline under "38%"
  {
    id: "underline",
    vbPoints: [
      ...sampleQuadratic({ x: 232, y: 210 }, { x: 260, y: 202 }, { x: 290, y: 207 }, 8),
      // T continues the prior quadratic — control point reflected through
      // the previous endpoint (290, 207).
      ...sampleQuadratic({ x: 290, y: 207 }, { x: 320, y: 212 }, { x: 350, y: 210 }, 8),
    ],
  },
  // ellipse cx=808 cy=312 rx=32 ry=100 rotation=-3°
  {
    id: "ellipse",
    vbPoints: sampleRotatedEllipse(808, 312, 32, 100, -3, 32),
  },
  // Curvy arrow + arrowhead — both treated as one annotation so the whole
  // arrow disappears together.
  {
    id: "arrow",
    vbPoints: [
      ...sampleCubic({ x: 720, y: 130 }, { x: 760, y: 165 }, { x: 790, y: 195 }, { x: 808, y: 218 }, 14),
      { x: 808, y: 218 }, { x: 812, y: 208 }, { x: 816, y: 198 },
      { x: 808, y: 218 }, { x: 799, y: 214.5 }, { x: 790, y: 211 },
    ],
  },
  // "Q4 가 핵심!" handwritten label, x=720 y=100 font=34, rotated -3°.
  // Sample a coarse grid over the rotated bbox so the eraser catches it
  // anywhere along the text.
  {
    id: "text",
    vbPoints: (() => {
      const cos = Math.cos((-3 * Math.PI) / 180);
      const sin = Math.sin((-3 * Math.PI) / 180);
      const pts: Pt[] = [];
      for (let i = 0; i <= 6; i++) {
        for (let j = 0; j <= 2; j++) {
          const lx = (i / 6) * 160;
          const ly = -30 + (j / 2) * 36;
          pts.push({ x: 720 + lx * cos - ly * sin, y: 100 + lx * sin + ly * cos });
        }
      }
      return pts;
    })(),
  },
];

function DemoScene({ lang }: { lang: Lang }) {
  // Two interaction modes:
  //  - Desktop (fine pointer + wide enough): drawing is always live, tool
  //    swap via the tiny toolbar hotspots feels natural with a mouse.
  //  - Mobile (coarse pointer): drawing is OFF by default so the page can
  //    scroll past the demo. A "✏️ 그려보기" button on the slide enters
  //    drawing mode, where a bigger bottom bar handles tool swap + exit.
  const [isDesktop,    setIsDesktop]    = useState(false);
  const [isMobileTouch, setIsMobileTouch] = useState(false);
  const [mobileDrawing, setMobileDrawing] = useState(false);
  useEffect(() => {
    const mqDesktop = window.matchMedia("(any-pointer: fine) and (min-width: 768px)");
    const mqTouch   = window.matchMedia("(any-pointer: coarse)");
    const update = () => {
      const desk = mqDesktop.matches;
      setIsDesktop(desk);
      setIsMobileTouch(mqTouch.matches && !desk);
    };
    update();
    mqDesktop.addEventListener("change", update);
    mqTouch.addEventListener("change", update);
    return () => {
      mqDesktop.removeEventListener("change", update);
      mqTouch.removeEventListener("change", update);
    };
  }, []);
  // Whether the canvas should accept pointer events right now.
  const drawingActive = isDesktop || mobileDrawing;
  const showCanvas    = isDesktop || isMobileTouch;

  // Only pen and eraser are wired up — the rest of the toolbar is
  // decorative ("install for the full set"). Toolbar image swaps to mirror
  // the selected state so the blue selection ring follows the user's pick.
  const [tool, setTool] = useState<"pen" | "eraser">("pen");

  // Static SVG annotations the eraser has swallowed. Cleared on RESET so
  // the demo returns to its initial composed state.
  const [erasedStatic, setErasedStatic] = useState<Set<StaticAnnotationId>>(
    () => new Set(),
  );
  const eraseStatic = (id: StaticAnnotationId) => {
    setErasedStatic((prev) => {
      if (prev.has(id)) return prev;
      const next = new Set(prev);
      next.add(id);
      return next;
    });
  };
  const resetStatic = () => setErasedStatic(new Set());

  const visibleStatic = STATIC_ANNOTATIONS.filter((a) => !erasedStatic.has(a.id));

  return (
    <div
      className="absolute inset-0"
      style={{
        // Approximation of the macOS Sonoma wallpaper: cool blue top-right
        // sweeping into pink, then red/orange, into a green bottom. Built
        // from overlapping radial gradients so it reads as a single flowing
        // mesh rather than hard color stops.
        background: `
          radial-gradient(ellipse 70% 55% at 85% 12%, #4F73E2 0%, transparent 55%),
          radial-gradient(ellipse 55% 45% at 55% 30%, #E64C8B 0%, transparent 60%),
          radial-gradient(ellipse 60% 50% at 25% 48%, #E5402B 0%, transparent 65%),
          radial-gradient(ellipse 90% 60% at 50% 100%, #58B04F 0%, transparent 70%),
          linear-gradient(180deg, #5273DA 0%, #C84864 45%, #4FA64A 100%)
        `,
      }}
    >
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_30%_15%,rgba(255,255,255,0.15),transparent_55%)]" />

      {/* Mock macOS menubar — matches the layout of the real menubar:
          left side has the Apple logo + active app menus (Keynote);
          right side has system status items including the GZUK 그적
          status icon, IME indicator, battery, mute, wifi, search,
          control center, and date/time. */}
      <div className="absolute top-0 inset-x-0 h-7 backdrop-blur-xl bg-black/10 flex items-center justify-between px-3 sm:px-4 text-white text-[10px] sm:text-[11px]">
        {/* Left — active app menus. The full set is hidden on narrow
            viewports so the right-side status cluster doesn't get
            squished — only the active app name stays. */}
        <div className="flex items-center gap-2.5 sm:gap-4">
          <span className="font-semibold">Keynote</span>
          <span className="opacity-80 hidden sm:inline">파일</span>
          <span className="opacity-80 hidden sm:inline">편집</span>
          <span className="opacity-80 hidden sm:inline">보기</span>
        </div>

        {/* Right — system status cluster (kept minimal: 그적 / battery /
            wifi / date-time) */}
        <div className="flex items-center gap-3.5">
          {/* GZUK status item — mirrors the desktop app's stacked glyph
              icon. The app fakes bold via 4-stroke sub-pixel overlay because
              Gowun Dodum has no real bold weight; browsers do the equivalent
              when font-weight:700 is requested on a single-weight font, so
              just `font-bold` on "그" reads closer to the native rendering
              than -webkit-text-stroke (which looks more outlined). */}
          <div className="relative flex flex-col items-center leading-[1.05] font-brand text-[10px] tracking-tight">
            <span className="font-bold">그</span>
            <span className="font-normal">적</span>
            <span className="absolute -top-[1px] -right-[3px] w-[3.5px] h-[3.5px] rounded-full bg-accent" />
          </div>
          <Wifi size={12} strokeWidth={2} />
          {/* Mobile: short time only. Desktop: full date+time. */}
          <span className="text-[10px] sm:hidden">2:57</span>
          <span className="text-[11px] hidden sm:inline">5월 3일 (일) 오후 2:57</span>
        </div>
      </div>

      {/* Keynote window — `top` differs by viewport because the menubar is
          a fixed 28px tall while the demo container is aspect-[16/10]. On
          a phone the container is short enough that the fixed menubar
          eats more than 8%, so we push the window down a bit more there. */}
      <div className="absolute inset-x-[3%] top-[14%] sm:top-[8%] bottom-[6%] rounded-xl bg-white shadow-[0_30px_80px_-20px_rgba(60,20,120,0.55)] overflow-hidden flex flex-col">
        {/* Title bar with traffic lights */}
        <div className="h-7 flex items-center px-3 gap-1.5 border-b border-black/[0.06] bg-gradient-to-b from-[#F7F5F8] to-[#EFEDF1]">
          <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F57]" />
          <span className="w-2.5 h-2.5 rounded-full bg-[#FEBC2E]" />
          <span className="w-2.5 h-2.5 rounded-full bg-[#28C840]" />
          <span className="ml-3 text-[10px] text-ink-500">Keynote — Q2 사업 리뷰</span>
        </div>

        {/* Slide canvas — single SVG handles BOTH the slide content and the
            GZUK overlay annotations on top, in one coordinate system. */}
        <div className="flex-1 relative">
          <svg
            className="absolute inset-0 w-full h-full"
            viewBox="0 0 1000 560"
            preserveAspectRatio="xMidYMid meet"
          >
            {/* Slide eyebrow */}
            <text x="80" y="120" fontSize="13" fill="#6E6E73" letterSpacing="3">
              Q2 · 사업 성과
            </text>
            {/* Heading — slightly smaller so it doesn't dominate */}
            <text x="80" y="190" fontSize="38" fontWeight="700" fill="#0B0B0B">
              매출이 38% 증가
            </text>

            {/* Bar chart — all gray; the red circle annotation does the
                "this one matters" emphasis instead of bar color, so brand
                red stays exclusive to GZUK marks. */}
            {[
              { x: 580, h: 50,  v: "Q1" },
              { x: 650, h: 85,  v: "Q2" },
              { x: 720, h: 115, v: "Q3" },
              { x: 790, h: 175, v: "Q4" },
            ].map((b, i) => (
              <g key={i}>
                <rect
                  x={b.x} y={400 - b.h} width="36" height={b.h}
                  fill="#A1A1A6" rx="3"
                />
                <text
                  x={b.x + 18} y="425"
                  fontSize="12" fill="#6E6E73" textAnchor="middle"
                >
                  {b.v}
                </text>
              </g>
            ))}

            {/* Page indicator */}
            <text x="960" y="540" fontSize="11" fill="#A1A1A6" textAnchor="end">
              2 / 12
            </text>

            {/* === GZUK overlay annotations ===
                Each is conditionally rendered so the eraser can swallow
                them whole — see DrawingOverlay's static hit-test. */}
            {!erasedStatic.has("underline") && (
              <path
                d="M 232 210 Q 260 202 290 207 T 350 210"
                stroke="#FF2D2D" strokeWidth="3.5" fill="none" strokeLinecap="round"
              />
            )}
            {!erasedStatic.has("ellipse") && (
              <ellipse
                cx="808" cy="312" rx="32" ry="100"
                stroke="#FF2D2D" strokeWidth="3" fill="none"
                transform="rotate(-3 808 312)"
              />
            )}
            {!erasedStatic.has("arrow") && (
              <g>
                <path
                  d="M 720 130 C 760 165, 790 195, 808 218"
                  stroke="#FF2D2D" strokeWidth="3" fill="none" strokeLinecap="round"
                />
                <path
                  d="M 808 218 L 816 198 M 808 218 L 790 211"
                  stroke="#FF2D2D" strokeWidth="3" fill="none" strokeLinecap="round"
                />
              </g>
            )}
            {!erasedStatic.has("text") && (
              <text
                x="720" y="100"
                fontSize="34"
                fontFamily="Gowun Dodum, sans-serif"
                fontWeight="700"
                fill="#FF2D2D"
                transform="rotate(-3 720 100)"
              >Q4 가 핵심!</text>
            )}
          </svg>

          {showCanvas && (
            <DrawingOverlay
              lang={lang}
              tool={tool}
              staticAnnotations={visibleStatic}
              onEraseStatic={eraseStatic}
              onReset={resetStatic}
              interactive={drawingActive}
              showHint={!isMobileTouch}
            />
          )}

          {/* Mobile: enter-drawing-mode CTA. Compact pill placed near the
              bottom of the slide so it doesn't cover the chart. Matches
              the desktop hint's black pill so both read as "drawing
              affordance". */}
          {isMobileTouch && !mobileDrawing && (
            <button
              type="button"
              onClick={() => setMobileDrawing(true)}
              className="absolute left-1/2 bottom-2.5 -translate-x-1/2 z-20 px-3 py-1.5 rounded-full bg-black/85 backdrop-blur text-white text-[11px] font-semibold shadow-[0_4px_14px_-4px_rgba(0,0,0,0.4)] active:scale-95 transition"
            >
              그려보기 ✏️
            </button>
          )}

          {/* Mobile: in-drawing control bar. Compact, sits in the same
              bottom slot as the start CTA so layout doesn't jump. */}
          {isMobileTouch && mobileDrawing && (
            <div className="absolute left-1/2 bottom-2.5 -translate-x-1/2 z-20 flex items-center gap-0.5 px-0.5 py-0.5 rounded-full bg-black/85 backdrop-blur shadow-[0_4px_14px_-4px_rgba(0,0,0,0.45)] text-[10px] text-white">
              <button
                type="button"
                onClick={() => setTool("pen")}
                className={`px-2 py-1 rounded-full transition ${
                  tool === "pen" ? "bg-white/20" : "opacity-70"
                }`}
              >
                ✏️ 펜
              </button>
              <button
                type="button"
                onClick={() => setTool("eraser")}
                className={`px-2 py-1 rounded-full transition ${
                  tool === "eraser" ? "bg-white/20" : "opacity-70"
                }`}
              >
                🧽 지우개
              </button>
              <span className="w-px h-3 bg-white/25 mx-0.5" />
              <button
                type="button"
                onClick={() => setMobileDrawing(false)}
                className="px-2 py-1 rounded-full opacity-90 active:bg-white/10 transition"
              >
                ✓ 완료
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Floating GZUK toolbar — actual screenshot for visual fidelity. On
          desktop the pen/eraser hotspots are clickable; on mobile the
          toolbar is purely decorative (mobile uses the bottom control bar
          instead because the icons are too small for tap targets). */}
      <ToolbarImage tool={tool} setTool={setTool} interactive={isDesktop} />
    </div>
  );
}

/** Real toolbar screenshot. Two variants (pen-selected / eraser-selected)
 *  are swapped based on the active tool so the embedded blue selection
 *  ring tracks the user's choice. Only pen and eraser hotspots are
 *  clickable; the other icons are decorative. */
function ToolbarImage({
  tool,
  setTool,
  interactive,
}: {
  tool: "pen" | "eraser";
  setTool: (t: "pen" | "eraser") => void;
  interactive: boolean;
}) {
  const src =
    tool === "eraser"
      ? "/screenshots/toolbar-eraser.png"
      : "/screenshots/toolbar-pen.png";

  // Hotspot positions are percentages of the toolbar PNG. They map to the
  // pen icon (top-left tool) and eraser icon (top-right tool). A persistent
  // blue outline marks them as the only interactive icons in the otherwise-
  // decorative toolbar — selection state is still communicated by swapping
  // the toolbar PNG (built-in blue ring follows the choice).
  const hotspot =
    "absolute rounded-md cursor-pointer transition ring-2 ring-blue-500/45 hover:ring-blue-500 hover:bg-blue-500/10";
  // Values measured directly from the toolbar PNG: the built-in light-blue
  // selection rectangle around the selected pen button spans x 12.68–19.60%,
  // y 15.17–31.74%. We size hotspots to that exact rectangle so our outline
  // sits flush with (rather than offset from) the real button bounds.
  const hotspotStyle = (left: string) => ({
    left,
    top: "15.2%",
    width: "6.9%",
    height: "16.6%",
  });

  return (
    <div
      className="absolute left-1/2 top-[8%] sm:top-[2%] -translate-x-1/2 z-10 select-none"
      style={{ width: "min(46%, 340px)" }}
    >
      <div className="relative">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={src}
          alt="그려적어 toolbar"
          className="w-full h-auto block drop-shadow-[0_10px_30px_rgba(0,0,0,0.35)] pointer-events-none"
        />
        {interactive && (
          <>
            <button
              type="button"
              onClick={() => setTool("pen")}
              className={hotspot}
              style={hotspotStyle("12.7%")}
              aria-label="Pen"
              title="펜 — 체험 가능"
            />
            <button
              type="button"
              onClick={() => setTool("eraser")}
              className={hotspot}
              style={hotspotStyle("80.4%")}
              aria-label="Eraser"
              title="지우개 — 체험 가능"
            />
          </>
        )}
      </div>
    </div>
  );
}

type Pt = { x: number; y: number };
type Stroke = { points: Pt[] };

/**
 * Stroke-based drawing canvas. The canvas is a render target only — truth
 * lives in `strokesRef` (an array of point lists). Pen appends a new
 * stroke; eraser removes whole strokes whose any sample lies within the
 * eraser radius (matches the native app's "stroke erase" behavior — drag
 * across a line and the entire line vanishes, not just the touched pixels).
 */
function DrawingOverlay({
  lang,
  tool,
  staticAnnotations,
  onEraseStatic,
  onReset,
  interactive,
  showHint,
}: {
  lang: Lang;
  tool: "pen" | "eraser";
  staticAnnotations: { id: StaticAnnotationId; vbPoints: Pt[] }[];
  onEraseStatic: (id: StaticAnnotationId) => void;
  onReset: () => void;
  // When false (mobile, drawing mode off), the canvas is render-only:
  // pointer events pass through so the page can scroll, hint and RESET
  // hide so the slide reads as the static composed mock.
  interactive: boolean;
  // Mobile already shows a "✏️ 그려보기" CTA + bottom control bar, so the
  // big "여기에 직접 그려보세요" pill would be redundant noise there.
  showHint: boolean;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const drawingRef = useRef(false);
  // Pointer handlers close over `tool` at first render; mirror via ref so
  // they always read the latest selection without rebinding listeners.
  const toolRef = useRef(tool);
  toolRef.current = tool;

  // Source of truth. `strokesRef` is committed history; `currentRef` is
  // the in-progress pen stroke that hasn't been pushed yet.
  const strokesRef = useRef<Stroke[]>([]);
  const currentRef = useRef<Stroke | null>(null);
  // Smoothing state for the in-progress pen stroke.
  const lastPosRef = useRef<Pt | null>(null);
  const lastMidRef = useRef<Pt | null>(null);

  const [hasDrawn, setHasDrawn] = useState(false);

  const stylePen = (ctx: CanvasRenderingContext2D) => {
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.strokeStyle = "#FF2D2D";
    ctx.fillStyle = "#FF2D2D";
    ctx.lineWidth = 3.5;
    ctx.globalCompositeOperation = "source-over";
    ctx.globalAlpha = 1;
  };

  // Render a stroke with midpoint-quadratic smoothing — same algorithm
  // used live during drawing, so a redraw after erase looks identical.
  const drawSmoothed = (ctx: CanvasRenderingContext2D, s: Stroke) => {
    const pts = s.points;
    if (pts.length === 0) return;
    if (pts.length === 1) {
      ctx.beginPath();
      ctx.arc(pts[0].x, pts[0].y, ctx.lineWidth / 2, 0, Math.PI * 2);
      ctx.fill();
      return;
    }
    let lastMid = pts[0];
    for (let i = 1; i < pts.length; i++) {
      const last = pts[i - 1];
      const cur  = pts[i];
      const mid  = { x: (last.x + cur.x) / 2, y: (last.y + cur.y) / 2 };
      ctx.beginPath();
      ctx.moveTo(lastMid.x, lastMid.y);
      ctx.quadraticCurveTo(last.x, last.y, mid.x, mid.y);
      ctx.stroke();
      lastMid = mid;
    }
    // Tail segment from the last midpoint to the final sample.
    const last = pts[pts.length - 1];
    ctx.beginPath();
    ctx.moveTo(lastMid.x, lastMid.y);
    ctx.lineTo(last.x, last.y);
    ctx.stroke();
  };

  const renderAll = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d")!;
    ctx.save();
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.restore();
    stylePen(ctx);
    for (const s of strokesRef.current) drawSmoothed(ctx, s);
    if (currentRef.current) drawSmoothed(ctx, currentRef.current);
  };

  // Size the backing buffer to the element's CSS box × DPR so strokes stay
  // crisp. With stroke-based truth we just re-render on resize.
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const setup = () => {
      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();
      const ctx = canvas.getContext("2d");
      if (!ctx || rect.width === 0) return;
      canvas.width = Math.round(rect.width * dpr);
      canvas.height = Math.round(rect.height * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      renderAll();
    };
    setup();
    const ro = new ResizeObserver(setup);
    ro.observe(canvas);
    return () => ro.disconnect();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const getPos = (e: React.PointerEvent<HTMLCanvasElement>): Pt => {
    const rect = canvasRef.current!.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  };

  // Vertex-based hit test. Pointer samples are dense enough (every few
  // pixels) that we don't need point-to-segment distance for a feel-right
  // erase — the eraser radius is generous and any hit removes the whole
  // stroke anyway.
  const strokeNear = (s: Stroke, p: Pt, r: number) => {
    const r2 = r * r;
    for (const pt of s.points) {
      const dx = pt.x - p.x;
      const dy = pt.y - p.y;
      if (dx * dx + dy * dy < r2) return true;
    }
    return false;
  };

  // Mirror static annotations through a ref so the closure inside the
  // pointer handlers always reads the latest "still visible" set.
  const staticRef = useRef(staticAnnotations);
  staticRef.current = staticAnnotations;

  const eraseAt = (p: Pt) => {
    // 1) Pen strokes — straight CSS-pixel distance check.
    const before = strokesRef.current.length;
    strokesRef.current = strokesRef.current.filter(
      (s) => !strokeNear(s, p, 22),
    );
    if (strokesRef.current.length !== before) renderAll();

    // 2) Static SVG annotations — points are stored in viewBox space
    // (1000×560 with `xMidYMid meet`); convert eraser pos to viewBox
    // coords once per call rather than per point so this stays cheap.
    const canvas = canvasRef.current;
    if (!canvas || staticRef.current.length === 0) return;
    const rect = canvas.getBoundingClientRect();
    const scale = Math.min(rect.width / 1000, rect.height / 560);
    if (scale <= 0) return;
    const offX = (rect.width  - 1000 * scale) / 2;
    const offY = (rect.height -  560 * scale) / 2;
    const vbX = (p.x - offX) / scale;
    const vbY = (p.y - offY) / scale;
    const vbR = 22 / scale;
    const vbR2 = vbR * vbR;
    for (const ann of staticRef.current) {
      for (const pt of ann.vbPoints) {
        const dx = pt.x - vbX;
        const dy = pt.y - vbY;
        if (dx * dx + dy * dy < vbR2) {
          onEraseStatic(ann.id);
          break;
        }
      }
    }
  };

  const onPointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current!;
    const pos = getPos(e);
    canvas.setPointerCapture(e.pointerId);
    drawingRef.current = true;
    if (!hasDrawn) setHasDrawn(true);

    if (toolRef.current === "eraser") {
      eraseAt(pos);
      return;
    }

    // Pen: start a new in-progress stroke. The starting dot is drawn
    // directly so a click-without-drag leaves a visible mark.
    currentRef.current = { points: [pos] };
    lastPosRef.current = pos;
    lastMidRef.current = pos;
    const ctx = canvas.getContext("2d")!;
    stylePen(ctx);
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, ctx.lineWidth / 2, 0, Math.PI * 2);
    ctx.fill();
  };

  const onPointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!drawingRef.current) return;
    const pos = getPos(e);

    if (toolRef.current === "eraser") {
      eraseAt(pos);
      return;
    }

    const cur = currentRef.current;
    if (!cur) return;
    cur.points.push(pos);
    const ctx = canvasRef.current!.getContext("2d")!;
    stylePen(ctx);
    // Midpoint-quadratic smoothing: each segment runs from the previous
    // midpoint to the new midpoint, with the actual sample as the control
    // point — adjacent segments share endpoints, no gaps.
    const last = lastPosRef.current!;
    const lastMid = lastMidRef.current!;
    const mid = { x: (last.x + pos.x) / 2, y: (last.y + pos.y) / 2 };
    ctx.beginPath();
    ctx.moveTo(lastMid.x, lastMid.y);
    ctx.quadraticCurveTo(last.x, last.y, mid.x, mid.y);
    ctx.stroke();
    lastPosRef.current = pos;
    lastMidRef.current = mid;
  };

  const onPointerUp = () => {
    if (!drawingRef.current) return;
    drawingRef.current = false;
    if (currentRef.current && currentRef.current.points.length > 0) {
      strokesRef.current.push(currentRef.current);
    }
    currentRef.current = null;
    lastPosRef.current = null;
    lastMidRef.current = null;
  };

  const clear = () => {
    strokesRef.current = [];
    currentRef.current = null;
    renderAll();
    setHasDrawn(false);
    // Bring the static annotations back too — RESET is full demo restore.
    onReset();
  };

  return (
    <>
      <canvas
        ref={canvasRef}
        className="absolute inset-0 w-full h-full"
        style={{
          cursor: interactive
            ? tool === "eraser"
              ? "cell"
              : "crosshair"
            : "default",
          touchAction: interactive ? "none" : "auto",
          pointerEvents: interactive ? "auto" : "none",
        }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        onPointerLeave={onPointerUp}
      />
      {interactive && showHint && !hasDrawn && (
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 px-6 sm:px-7 py-3 sm:py-3.5 rounded-full bg-black/85 backdrop-blur text-white text-[16px] sm:text-[18px] font-semibold tracking-wide pointer-events-none shadow-[0_12px_40px_rgba(0,0,0,0.4)] gzuk-breathe">
          {t(strings.demo.hint, lang)}
        </div>
      )}
      {interactive && hasDrawn && (
        <button
          onClick={clear}
          className="absolute top-1.5 right-1.5 sm:top-2.5 sm:right-2.5 px-1.5 sm:px-2.5 py-0.5 sm:py-1 rounded-full bg-white/90 backdrop-blur text-[9px] sm:text-[11px] text-black/80 border border-black/10 hover:bg-white shadow-sm transition"
        >
          {t(strings.demo.clear, lang)}
        </button>
      )}
    </>
  );
}


function Features({ lang }: { lang: Lang }) {
  return (
    <section id="features" className="px-5 sm:px-6 py-20 sm:py-24 border-t border-black/5 dark:border-white/[0.06]">
      <div className="reveal mx-auto max-w-5xl">
        <div className="text-center mb-12">
          <p className={eyebrowAccent}>
            {t(strings.features.eyebrow, lang)}
          </p>
        </div>
        <div className="grid sm:grid-cols-2 gap-5">
          {strings.features.items.map((f, i) => (
            <div
              key={i}
              className="p-7 sm:p-8 rounded-2xl border border-black/[0.08] dark:border-white/[0.08] bg-white/50 dark:bg-white/[0.02] hover:bg-white dark:hover:bg-white/[0.04] transition break-keep"
            >
              <h3 className="text-[18px] sm:text-[20px] font-bold mb-2.5 tracking-tight">
                {t(f.title, lang)}
              </h3>
              <p className="opacity-65 leading-relaxed text-[15px]">
                {t(f.body, lang)}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Download({ lang }: { lang: Lang }) {
  return (
    <section id="download" className="px-5 sm:px-6 py-24 sm:py-32 border-t border-black/5 dark:border-white/[0.06]">
      <div className="reveal mx-auto max-w-3xl text-center">
        <p className={`${eyebrowMuted} mb-12`}>
          {t(strings.download.eyebrow, lang)}
        </p>

        <p className="opacity-55 mb-3 sm:mb-4 text-[13px] sm:text-[15px]">{t(strings.download.brew_label, lang)}</p>
        <CopyableCommand cmd={BREW_CMD} />

        <p className="mt-10 sm:mt-14 mb-3 sm:mb-4 opacity-55 text-[13px] sm:text-[15px]">{t(strings.download.or, lang)}</p>
        <a
          href={RELEASE_ZIP}
          target="_blank"
          rel="noreferrer"
          className="inline-block px-5 sm:px-7 py-2.5 sm:py-4 rounded-full border border-black/15 dark:border-white/20 text-[13px] sm:text-[16px] hover:bg-black/5 dark:hover:bg-white/5 transition"
        >
          GitHub Releases →
        </a>

        <p className="mt-10 sm:mt-14 text-[11px] sm:text-[13px] opacity-45 leading-relaxed max-w-xl mx-auto whitespace-pre-line">
          {t(strings.download.note, lang)}
        </p>
      </div>
    </section>
  );
}

function CopyableCommand({ cmd }: { cmd: string }) {
  const [copied, setCopied] = useState(false);
  const onCopy = () => {
    navigator.clipboard.writeText(cmd);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };
  return (
    <div className="inline-flex items-center gap-2 sm:gap-3 px-3.5 sm:px-5 py-3 sm:py-3.5 rounded-2xl bg-black/[0.05] dark:bg-white/[0.06] text-[13px] sm:text-sm whitespace-nowrap max-w-full">
      <span className="opacity-40 shrink-0">$</span>
      <span>{cmd}</span>
      <button
        onClick={onCopy}
        className="shrink-0 opacity-50 hover:opacity-100 text-[10px] sm:text-[11px] px-2 sm:px-2.5 py-0.5 sm:py-1 rounded-full border border-black/15 dark:border-white/15 transition"
      >
        {copied ? "✓" : "copy"}
      </button>
    </div>
  );
}

function Shortcuts({ lang }: { lang: Lang }) {
  return (
    <section id="shortcuts" className="px-5 sm:px-6 py-24 sm:py-32 border-t border-black/5 dark:border-white/[0.06]">
      <div className="reveal mx-auto max-w-3xl">
        <p className={`${eyebrowMuted} mb-12 text-center`}>
          {t(strings.shortcuts.eyebrow, lang)}
        </p>
        <div className="overflow-hidden rounded-2xl border border-black/10 dark:border-white/10">
          <table className="w-full text-[13px] sm:text-[14px]">
            <thead className="bg-black/[0.04] dark:bg-white/[0.04] text-left font-ui">
              <tr>
                <th className="px-4 sm:px-6 py-3 sm:py-3.5 font-medium">{t(strings.shortcuts.cols.action, lang)}</th>
                <th className="px-4 sm:px-6 py-3 sm:py-3.5 font-medium w-24 sm:w-32">{t(strings.shortcuts.cols.key, lang)}</th>
              </tr>
            </thead>
            <tbody>
              {strings.shortcuts.rows.map((r, i) => (
                <tr key={i} className="border-t border-black/[0.06] dark:border-white/[0.06]">
                  <td className="px-4 sm:px-6 py-3 sm:py-3.5">{t(r.a, lang)}</td>
                  <td className="px-4 sm:px-6 py-3 sm:py-3.5">
                    {/* One keycap pill — joined with thin spaces between glyphs
                        so multi-key combos like ⌘⇧Z don't look cramped. */}
                    <kbd
                      className="inline-flex items-center px-2 sm:px-2.5 py-0.5 rounded-md border border-black/15 dark:border-white/15 bg-black/[0.04] dark:bg-white/[0.06] text-[12px] sm:text-[13px] font-medium"
                    >
                      {[...r.k].join(" ")}
                    </kbd>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
}

function Footer({ lang }: { lang: Lang }) {
  return (
    <footer className="px-5 sm:px-6 py-12 sm:py-16 border-t border-black/5 dark:border-white/[0.06]">
      <div className="mx-auto max-w-5xl flex flex-wrap items-center justify-between gap-4 text-[12px] opacity-55">
        <div className="flex items-center gap-2">
          <Glyph small />
          <span>그려적어 / GZUK</span>
        </div>
        <div className="flex items-center gap-4">
          <span>{t(strings.footer.license, lang)}</span>
          <span>·</span>
          <span>{t(strings.footer.made, lang)}</span>
        </div>
      </div>
    </footer>
  );
}
