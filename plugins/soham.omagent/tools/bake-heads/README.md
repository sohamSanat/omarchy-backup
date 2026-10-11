# bake-heads

Offline baker for the omagent status head. Renders the [robot-heads](https://github.com/fayazara/robot-heads)
library to looping atlas PNGs, one per robot state per theme. The overlay plays
these as textures; nothing here runs at runtime.

## Output

```text
assets/heads/<theme>/<state>/frame_NN.png   # one PNG per frame
assets/heads/manifest.json                  # frame count per state
```

One file per frame. The overlay swaps `source` between frames, so Qt's pixmap
cache holds them and a tick is a source change only — no clip-rect math.

An atlas-per-state layout was tried first and rejected: with
`sourceClipRect`, Qt6 letterboxes the *whole atlas* as the natural size unless
`sourceSize` is set, and setting `sourceSize` to the frame size then makes the
clip cover the entire squeezed atlas. The result flashes between a
correctly-clipped frame and a grid of shrunken heads. Individual frames remove
the ambiguity entirely.

## Themes

Palettes are keyed to the Omarchy theme that owns the surface the head sits on.
Edit `THEMES` in `bake.mjs` to re-tune.

| Theme | Palette source | Shell | Trim | Screen |
|---|---|---|---|---|
| `dark` | Harbordark (`#1B1B1B` menu background) | `#2c3a55` | `#8f9bb0` | `#e8f2ff` |
| `light` | Quattrocento-light (`#f0e6d3` menu background) | `#33476b` | `#9aa7bd` | `#dceaf8` |

Adding a theme means adding one entry to `THEMES` and one matching branch in the
overlay's theme resolution.

## Shape

The head outline is a **build-time** choice — a one-word parameter, not a code
change:

```sh
SHAPE=circle    node bake.mjs   # round porthole (current)
SHAPE=hexagon   node bake.mjs   # nut, flat on top
SHAPE=square    node bake.mjs   # boxy TV
SHAPE=rectangle node bake.mjs   # the classic wide TV
```

Anything `robot-heads` accepts as `shape` works. The overlay player is
shape-agnostic — it plays numbered frames and never learns the shape — so
switching is a re-bake plus the split step below, with no QML edit. The chosen
shape is recorded in `assets/heads/manifest.json`.

Note the frame size changes with the shape (circle is `116x164`, rectangle was
`128x158`), so read the dimensions from the manifest rather than hardcoding them.

## Re-bake

The baker needs node and a one-time install. Install outside this directory so
`node_modules` never lands in the deployed plugin (the plugin ships assets only).

```sh
d=$(mktemp -d "${TMPDIR:-/tmp}/robot-bake-XXXXXX")
cp "$PWD"/*.js "$PWD"/*.jsx "$PWD"/*.html "$PWD/package.json" "$d"/
cd "$d"
npm install
npx esbuild entry.jsx --bundle --format=iife --outfile=bundle.js --loader:.jsx=jsx --jsx=automatic
OUT_ROOT="$(cd ../../../.. && pwd)/assets/heads" node bake.mjs
```

If the install pulls a different Chromium revision than the one already on disk,
run `npx playwright install chromium` (a one-time ~170 MB download) or pin a
`playwright` version whose bundled Chromium matches your cache.

## Determinism

The library advances its simulation from the animation-frame timestamp delta.
`clock.js` replaces that clock with a fixed step (`DT` seconds per frame), and the
component takes an explicit `seed` and `speed`. With those pinned, a re-bake
reproduces byte-identical assets, so refreshing them never shimmers.

Verify it with:

```sh
md5sum ../../assets/heads/*/*.png    # before
node bake.mjs
md5sum ../../assets/heads/*/*.png    # after — identical
```

## Tuning

| Constant | Meaning |
|---|---|
| `DT` | Seconds per captured frame (1/24). |
| `FRAMES` | Frames per loop (48 = a 2 s loop at `DT`). |
| `WARMUP` | Frames dropped first, past the switch-on reveal and pose settle. |
| `COLS` | Atlas columns before splitting; `FRAMES` must be a multiple. |

Lower `FRAMES` or `DT` for smaller assets; raise them for smoother motion. The
head renders at `size=56` with `deviceScaleFactor: 2`, so each frame is
`128x158` device pixels and displays crisply at half that (`56x79` CSS px).

After re-baking, split the atlases into frames:

```sh
cd assets/heads
python3 - <<'PY'
import pathlib, subprocess
FW, FH, N = 128, 158, 48
for theme in ("dark", "light"):
    for atlas in sorted((pathlib.Path(theme)).glob("*.png")):
        d = pathlib.Path(theme) / atlas.stem
        d.mkdir(exist_ok=True)
        subprocess.run(["magick", str(atlas), "-crop", f"{FW}x{FH}", "+repage",
                        "+adjoin", str(d / "frame_%02d.png")], check=True)
        atlas.unlink()
PY
```
