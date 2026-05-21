import { ImageResponse } from "next/og";

export const runtime = "edge";
export const alt = "그려적어 (GZUK)";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

async function loadGoogleFont(family: string, text: string) {
  const url = `https://fonts.googleapis.com/css2?family=${family}&text=${encodeURIComponent(
    text,
  )}`;
  const css = await (await fetch(url)).text();
  const match = css.match(
    /src: url\((.+?)\) format\('(opentype|truetype)'\)/,
  );
  if (!match) throw new Error(`font not found: ${family}`);
  return await (await fetch(match[1])).arrayBuffer();
}

export default async function OpengraphImage() {
  const gowunDodum = await loadGoogleFont("Gowun+Dodum", "그려적어");

  return new ImageResponse(
    (
      <div
        style={{
          display: "flex",
          width: "100%",
          height: "100%",
          background: "#ffffff",
          alignItems: "center",
          justifyContent: "center",
          flexDirection: "column",
          fontFamily: "Gowun Dodum",
          lineHeight: 1,
        }}
      >
        <div
          style={{
            display: "flex",
            fontSize: 200,
            color: "#FF3B30",
            textShadow:
              "1px 0 #FF3B30, -1px 0 #FF3B30, 0 1px #FF3B30, 0 -1px #FF3B30",
          }}
        >
          그려
        </div>
        <div
          style={{
            display: "flex",
            fontSize: 200,
            color: "#1a1a1a",
            marginTop: 32,
          }}
        >
          적어
        </div>
      </div>
    ),
    {
      ...size,
      fonts: [
        { name: "Gowun Dodum", data: gowunDodum, style: "normal", weight: 400 },
      ],
    },
  );
}
