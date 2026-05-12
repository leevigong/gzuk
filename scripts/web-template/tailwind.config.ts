import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        // Gowun Dodum (Korean handwriting) used as the default body font
        // throughout the site. Loaded via Google Fonts <link> in layout.tsx.
        sans: [
          "Gowun Dodum",
          "Pretendard Variable",
          "Pretendard",
          "-apple-system",
          "BlinkMacSystemFont",
          "system-ui",
          "sans-serif",
        ],
        // Same family — kept as an alias for the wordmark.
        brand: ["Gowun Dodum", "system-ui", "sans-serif"],
        // Sharp Pretendard, used to opt small UI labels (e.g. the shortcuts
        // table header with its gray background) out of the handwriting
        // font when the handwriting feels too soft for tabular labels.
        ui: [
          "Pretendard Variable",
          "Pretendard",
          "-apple-system",
          "BlinkMacSystemFont",
          "system-ui",
          "sans-serif",
        ],
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
        display: ["clamp(1.125rem, 2vw, 1.75rem)", { lineHeight: "1.25", letterSpacing: "-0.02em", fontWeight: "700" }],
        section: ["clamp(1.5rem, 3vw, 2.25rem)", { lineHeight: "1.15", letterSpacing: "-0.02em", fontWeight: "700" }],
      },
      maxWidth: {
        prose: "42rem",
      },
    },
  },
  plugins: [],
};
export default config;
