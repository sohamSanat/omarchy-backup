/**
 * Offline baker: renders each robot state into a looping atlas PNG per theme.
 *
 * Determinism comes from a fixed-step synthetic clock (see clock.js) and an
 * explicit `seed`/`speed` on the component, so a re-bake with the same inputs
 * produces byte-identical frames.
 *
 * Output layout: assets/heads/<theme>/<state>.png — a single-row atlas of
 * FRAMES frames, each frameW x frameH device pixels (baked at DPR 2).
 */
import { chromium } from 'playwright';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Head outline to bake: rectangle | square | circle | hexagon.
 * Override without editing:  SHAPE=hexagon node bake.mjs
 */
const SHAPE = process.env.SHAPE || 'circle';

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT_ROOT = '/home/soham/.config/omarchy/plugins/soham.omagent/assets/heads';

/** Seconds per captured frame. 1/12 keeps a 3s loop to 36 frames. */
const DT = 1 / 24;
/** Frames captured into one atlas (3s at DT = 1/12). */
const FRAMES = 48;
/** Frames dropped before capture: the component's switch-on reveal + settle. */
const WARMUP = 30;
/** Atlas columns. FRAMES must be a multiple of COLS. */
const COLS = 8;

/**
 * Shell/LED palette per theme, matched to the Omarchy theme that owns the
 * surface the head sits on.
 */
const THEMES = {
  dark: {
    // Harbordark: menu background #1B1B1B, foreground #efebdc, accent #e75a50
    color: '#2c3a55',
    trimColor: '#8f9bb0',
    screenColor: '#e8f2ff',
    /** Backdrop the head is composited over, for the reference contact sheet. */
    backdrop: '#1B1B1B',
  },
  light: {
    // Quattrocento-light: menu background #f0e6d3, foreground #33291b
    color: '#33476b',
    trimColor: '#9aa7bd',
    screenColor: '#dceaf8',
    backdrop: '#f0e6d3',
  },
};

const STATES = ['idle', 'thinking', 'searching', 'working', 'happy', 'error'];

/** Build an atlas PNG from frame data URLs on a shared, reusable page. */
async function buildAtlas(atlasPage, frames, cols) {
  const dim = await atlasPage.evaluate(async (url) => {
    const img = new Image();
    await new Promise((res, rej) => {
      img.onload = res;
      img.onerror = rej;
      img.src = url;
    });
    return { w: img.naturalWidth, h: img.naturalHeight };
  }, frames[0]);

  const rows = Math.ceil(frames.length / cols);
  const dataUrl = await atlasPage.evaluate(
    async ({ frames, w, h, cols, rows }) => {
      const c = document.createElement('canvas');
      c.width = cols * w;
      c.height = rows * h;
      const ctx = c.getContext('2d');
      for (let i = 0; i < frames.length; i++) {
        const img = new Image();
        await new Promise((res, rej) => {
          img.onload = res;
          img.onerror = rej;
          img.src = frames[i];
        });
        ctx.drawImage(img, (i % cols) * w, Math.floor(i / cols) * h, w, h);
      }
      return c.toDataURL('image/png');
    },
    { frames, w: dim.w, h: dim.h, cols, rows }
  );

  const png = Buffer.from(dataUrl.split(',')[1], 'base64');
  return { png, frameW: dim.w, frameH: dim.h, cols, rows };
}

async function main() {
  const browser = await chromium.launch({ args: ['--allow-file-access-from-files'] });
  const context = await browser.newContext({
    viewport: { width: 420, height: 480 },
    deviceScaleFactor: 2,
    reducedMotion: 'no-preference',
  });
  const page = await context.newPage();
  await page.addInitScript({ path: join(HERE, 'clock.js') });
  await page.addInitScript((s) => {
    window.__BAKE_SHAPE = s;
  }, SHAPE);
  await page.goto('file://' + join(HERE, 'index.html'));
  await page.waitForFunction(() => window.__bake && window.__bake.capture);
  // A separate, contentless page reused for every atlas build.
  const atlasPage = await context.newPage();

  const manifest = { generatedBy: 'tools/bake-heads', shape: SHAPE, dt: DT, frames: FRAMES, cols: COLS, states: {} };

  for (const [themeName, palette] of Object.entries(THEMES)) {
    const outDir = join(OUT_ROOT, themeName);
    await mkdir(outDir, { recursive: true });

    for (const state of STATES) {
      await page.evaluate(
        ([s, p]) => {
          window.__bake.setPalette(p);
          window.__bake.setState(s);
        },
        [state, { color: palette.color, trimColor: palette.trimColor, screenColor: palette.screenColor }]
      );

      // Warm up past the switch-on reveal and the pose settle.
      for (let i = 0; i < WARMUP; i++) {
        await page.evaluate((dt) => window.__clock.tick(dt), DT);
      }

      const info = await page.evaluate(() => window.__bake.canvasInfo());
      const frames = [];
      for (let i = 0; i < FRAMES; i++) {
        await page.evaluate((dt) => window.__clock.tick(dt), DT);
        frames.push(await page.evaluate(() => window.__bake.capture()));
      }

      const { png, frameW, frameH, cols, rows } = await buildAtlas(atlasPage, frames, COLS);
      await writeFile(join(outDir, `${state}.png`), png);
      manifest.states[state] = { frameW, frameH, cols, rows, frames: FRAMES };
      console.log(`${themeName}/${state}.png  frame=${frameW}x${frameH}  atlas=${frameW * cols}x${frameH * rows}  ${(png.length / 1024).toFixed(0)}KB`);
    }
  }

  await writeFile(join(OUT_ROOT, 'manifest.json'), JSON.stringify(manifest, null, 2));
  await browser.close();
  console.log(`\nBaked ${Object.keys(THEMES).length} themes x ${STATES.length} states  shape=${SHAPE}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
