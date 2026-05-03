import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        // Pretendard for body — the de-facto Korean web font, mirrors Apple's
        // SF Pro feel on Mac. Loaded via <link> in layout.tsx.
        sans: [
          "Pretendard Variable",
          "Pretendard",
          "-apple-system",
          "BlinkMacSystemFont",
          "system-ui",
          "sans-serif",
        ],
        // Gowun Dodum (Korean handwriting) — used only for the brand wordmark.
        brand: ["var(--font-gowun-dodum)", "system-ui", "sans-serif"],
      },
      colors: {
        accent: {
          DEFAULT: "#FF2D2D",
          dark: "#D11717",
        },
        ink: {
          900: "#0B0B0B",
          700: "#3A3A3A",
          500: "#6E6E73",
          300: "#A1A1A6",
          100: "#F5F5F7",
        },
      },
      letterSpacing: {
        tightest: "-0.04em",
      },
      fontSize: {
        display: ["clamp(3.5rem, 9vw, 7rem)", { lineHeight: "0.95", letterSpacing: "-0.04em", fontWeight: "700" }],
        section: ["clamp(2.25rem, 5vw, 3.75rem)", { lineHeight: "1.05", letterSpacing: "-0.03em", fontWeight: "700" }],
      },
      maxWidth: {
        prose: "42rem",
      },
    },
  },
  plugins: [],
};
export default config;
