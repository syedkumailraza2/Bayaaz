import { ImageResponse } from "next/og";

export const alt = "BAYAAZ — The poetry bayaaz you remember.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: "80px",
          background: "#003119",
          color: "#ffffff",
        }}
      >
        <div style={{ fontSize: 120, fontWeight: 800, letterSpacing: -4 }}>BAYAAZ</div>
        <div style={{ fontSize: 44, marginTop: 16, color: "#b1f1c3" }}>
          The poetry bayaaz you remember.
        </div>
        <div style={{ fontSize: 30, marginTop: 40, color: "#96d5a8" }}>
          Nauha · Marsiya · Qasida · Qata lyrics — read, recite, and sync your majlis.
        </div>
      </div>
    ),
    size,
  );
}
