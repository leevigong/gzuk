import "./globals.css";
import type { Metadata } from "next";
import { Gowun_Dodum } from "next/font/google";

// Korean handwriting font — only used for the 그려/적어 brand wordmark so the
// rest of the page can lean on a clean modern sans (Pretendard) for that
// Apple-marketing-page feel.
const gowun = Gowun_Dodum({
  subsets: ["latin"],
  weight: "400",
  variable: "--font-gowun-dodum",
  display: "swap",
});

export const metadata: Metadata = {
  title: "그려적어 (GZUK) — 화면 위에 바로 그리고 적는 macOS 앱",
  description:
    "회의 중, 강의 중, 데모 중 — 어떤 화면 위에서도 즉시 그리고 적을 수 있는 macOS 오픈소스 어노테이션 앱.",
  metadataBase: new URL("https://gzuk.app"),
  openGraph: {
    title: "그려적어 (GZUK)",
    description: "화면 위에 바로 그리고 적는 macOS 앱",
    locale: "ko_KR",
    type: "website",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko" className={gowun.variable}>
      <head>
        {/* Pretendard — Korean web font that gives an Apple-SF-Pro feel on
            both Mac and other platforms. Loading the variable build keeps
            bundle weight low while exposing the full weight axis. */}
        <link
          rel="stylesheet"
          href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable.min.css"
        />
      </head>
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
