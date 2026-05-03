"use client";

import { useEffect, useState } from "react";
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
      <DemoFrame />
      <Features lang={lang} />
      <Download lang={lang} />
      <Shortcuts lang={lang} />
      <Footer lang={lang} />
    </main>
  );
}

function Nav({ lang, setLang }: { lang: Lang; setLang: (l: Lang) => void }) {
  return (
    <nav className="sticky top-0 z-50 backdrop-blur-xl bg-[var(--bg)]/70 border-b border-black/5 dark:border-white/[0.06]">
      <div className="mx-auto max-w-6xl px-5 sm:px-6 h-12 flex items-center justify-between text-[13px]">
        <a href="#top" className="flex items-center gap-2">
          <Glyph small />
          <span className="font-semibold tracking-tight">그려적어</span>
          <span className="opacity-40 tracking-widest text-[11px] hidden sm:inline">GZUK</span>
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

/** Stacked "그/적" wordmark — mirrors the menubar icon. */
function Glyph({ small = false }: { small?: boolean }) {
  return (
    <span
      className={`inline-flex flex-col leading-[0.85] font-brand font-bold ${
        small ? "text-[14px]" : "text-[18px]"
      }`}
    >
      <span className="text-accent">그</span>
      <span>적</span>
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
          <span className="block">{t(strings.hero.line1, lang)}</span>
          <span className="block opacity-60">{t(strings.hero.line2, lang)}</span>
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

function DemoFrame() {
  return (
    <section className="px-5 sm:px-6 pb-20 sm:pb-32">
      <div className="reveal mx-auto max-w-5xl">
        <div className="relative aspect-[16/10] rounded-3xl overflow-hidden shadow-[0_40px_100px_-20px_rgba(80,30,150,0.45)] border border-black/[0.06]">
          <DemoScene />
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
function DemoScene() {
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

            {/* === GZUK overlay annotations === */}
            {/* Wobbly underline directly under "38%" (between "매출이 " and " 증가") */}
            <path
              d="M 232 210 Q 260 202 290 207 T 350 210"
              stroke="#FF2D2D" strokeWidth="3.5" fill="none" strokeLinecap="round"
            />
            {/* Circle around the Q4 bar (x=790, w=36, top=225, h=175) */}
            <ellipse
              cx="808" cy="312" rx="32" ry="100"
              stroke="#FF2D2D" strokeWidth="3" fill="none"
              transform="rotate(-3 808 312)"
            />
            {/* Curvy arrow from handwritten note → top of Q4 bar */}
            <path
              d="M 720 130 C 760 165, 790 195, 808 218"
              stroke="#FF2D2D" strokeWidth="3" fill="none" strokeLinecap="round"
            />
            <path
              d="M 808 218 L 816 198 M 808 218 L 790 211"
              stroke="#FF2D2D" strokeWidth="3" fill="none" strokeLinecap="round"
            />
            {/* Handwritten note — kept inside the SVG so its position scales
                with the same viewBox as the arrow/circle and stays inside
                the slide on narrow viewports. */}
            <text
              x="720" y="100"
              fontSize="34"
              fontFamily="Gowun Dodum, sans-serif"
              fontWeight="700"
              fill="#FF2D2D"
              transform="rotate(-3 720 100)"
            >Q4 가 핵심!</text>
          </svg>
        </div>
      </div>

      {/* Floating GZUK toolbar — actual screenshot for 100% visual fidelity
          (the real app uses SF Symbols, which can't be reproduced exactly
          on the web). */}
      <ToolbarImage />
    </div>
  );
}

/** Real toolbar screenshot, used in DemoScene. Way more accurate than
 *  recreating SF Symbols in SVG. */
function ToolbarImage() {
  return (
    <div
      className="absolute left-1/2 top-[8%] sm:top-[2%] -translate-x-1/2 z-10"
      style={{ width: "min(46%, 340px)" }}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src="/screenshots/toolbar.png"
        alt="그려적어 toolbar"
        className="w-full h-auto drop-shadow-[0_10px_30px_rgba(0,0,0,0.35)]"
      />
    </div>
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

        <p className="opacity-55 mb-3 text-sm">{t(strings.download.brew_label, lang)}</p>
        <CopyableCommand cmd={BREW_CMD} />

        <p className="mt-12 mb-3 opacity-55 text-sm">{t(strings.download.or, lang)}</p>
        <a
          href={RELEASE_ZIP}
          target="_blank"
          rel="noreferrer"
          className="inline-block px-6 py-3 rounded-full border border-black/15 dark:border-white/20 hover:bg-black/5 dark:hover:bg-white/5 transition"
        >
          GitHub Releases →
        </a>

        <p className="mt-12 text-[12px] opacity-45 leading-relaxed max-w-xl mx-auto whitespace-pre-line">
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
    <div className="inline-flex items-center gap-3 px-5 py-3.5 rounded-2xl bg-black/[0.05] dark:bg-white/[0.06] font-mono text-sm">
      <span className="opacity-40">$</span>
      <span>{cmd}</span>
      <button
        onClick={onCopy}
        className="opacity-50 hover:opacity-100 text-[11px] px-2.5 py-1 rounded-full border border-black/15 dark:border-white/15 transition"
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
            <thead className="bg-black/[0.04] dark:bg-white/[0.04] text-left">
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
                      style={{ fontFamily: "-apple-system, BlinkMacSystemFont, system-ui, sans-serif" }}
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
