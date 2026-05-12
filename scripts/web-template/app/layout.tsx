import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "그려적어 (GZUK) — 화면 위에 바로 그리고 적는 macOS 앱",
  description:
    "회의 중, 강의 중, 데모 중 — 어떤 화면 위에서도 즉시 그리고 적을 수 있는 macOS 오픈소스 어노테이션 앱.",
  metadataBase: new URL("https://gzuk-app.vercel.app"),
  openGraph: {
    title: "그려적어 (GZUK)",
    description: "화면 위에 바로 그리고 적는 macOS 앱",
    locale: "ko_KR",
    type: "website",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <head>
        {/* Pretendard — Korean web font that gives an Apple-SF-Pro feel on
            both Mac and other platforms. Loading the variable build keeps
            bundle weight low while exposing the full weight axis. */}
        <link
          rel="preconnect"
          href="https://cdn.jsdelivr.net"
          crossOrigin=""
        />
        <link
          rel="stylesheet"
          href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable.min.css"
        />
        {/* Gowun Dodum — Korean handwriting font, used only for the 그려/적어
            brand wordmark. We load it via Google Fonts CSS rather than
            next/font so the Korean unicode-range slice is fetched as soon
            as the browser sees the Korean glyphs (next/font's `subsets:
            ["latin"]` was excluding the Korean range, leaving 그려/적어 in
            a system fallback that rendered at a different size). */}
        <link
          rel="preconnect"
          href="https://fonts.googleapis.com"
        />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin=""
        />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Gowun+Dodum&display=swap"
        />
      </head>
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
