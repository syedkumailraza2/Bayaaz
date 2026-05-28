// Composes library.png + recite.png into a single 4:5 portrait mockup
// for the "How it works" section. Re-run with: node scripts/build-showcase-mockup.mjs
import sharp from "sharp";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MOCKUPS = path.join(__dirname, "..", "public", "mockups");

const libBuf = fs.readFileSync(path.join(MOCKUPS, "library.png"));
const recBuf = fs.readFileSync(path.join(MOCKUPS, "recite.png"));

// 4:5 canvas, sized large enough to leave room for tilt + shadow bleed.
const W = 1200;
const H = 1500;

// Each phone at 460 wide → ~1000 tall (1206×2622 source aspect).
const PHONE_W = 460;
const PHONE_H = Math.round((PHONE_W * 2622) / 1206);
const RADIUS = 80;

const libB64 = libBuf.toString("base64");
const recB64 = recBuf.toString("base64");

const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <filter id="phoneShadow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="40" stdDeviation="45" flood-color="#0A2818" flood-opacity="0.28"/>
    </filter>
    <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="70"/>
    </filter>
    <clipPath id="round">
      <rect x="0" y="0" width="${PHONE_W}" height="${PHONE_H}" rx="${RADIUS}" ry="${RADIUS}"/>
    </clipPath>
  </defs>

  <!-- ambient green glows behind the phones -->
  <circle cx="320" cy="430" r="220" fill="#B1F1C3" opacity="0.55" filter="url(#glow)"/>
  <circle cx="900" cy="1000" r="240" fill="#62DF7D" opacity="0.45" filter="url(#glow)"/>

  <!-- Back phone (library), tilted left -->
  <g transform="translate(120 200) rotate(-7 ${PHONE_W / 2} ${PHONE_H / 2})" filter="url(#phoneShadow)">
    <g clip-path="url(#round)">
      <image href="data:image/png;base64,${libB64}" x="0" y="0" width="${PHONE_W}" height="${PHONE_H}" preserveAspectRatio="xMidYMid slice"/>
    </g>
    <rect x="0" y="0" width="${PHONE_W}" height="${PHONE_H}" rx="${RADIUS}" ry="${RADIUS}" fill="none" stroke="#000" stroke-opacity="0.12" stroke-width="3"/>
  </g>

  <!-- Front phone (recite), tilted right, overlapping -->
  <g transform="translate(540 290) rotate(7 ${PHONE_W / 2} ${PHONE_H / 2})" filter="url(#phoneShadow)">
    <g clip-path="url(#round)">
      <image href="data:image/png;base64,${recB64}" x="0" y="0" width="${PHONE_W}" height="${PHONE_H}" preserveAspectRatio="xMidYMid slice"/>
    </g>
    <rect x="0" y="0" width="${PHONE_W}" height="${PHONE_H}" rx="${RADIUS}" ry="${RADIUS}" fill="none" stroke="#000" stroke-opacity="0.12" stroke-width="3"/>
  </g>
</svg>
`;

const out = path.join(MOCKUPS, "showcase.png");
await sharp(Buffer.from(svg), { density: 200 })
  .png({ compressionLevel: 9 })
  .toFile(out);

const stat = fs.statSync(out);
console.log(`wrote ${out} (${(stat.size / 1024).toFixed(0)} KB)`);
