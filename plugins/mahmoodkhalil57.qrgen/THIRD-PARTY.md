# Third-party code

This plugin ships other people's work. All of it is MIT, which asks only that
the copyright notice travels with the code — so here it is, and each licence
file is kept alongside the code it covers.

## qrgen — MIT, © Mahmood Ihab Khalil

<https://github.com/mahmoodkhalil57/qrgen>

`renderer.js` is a build artefact, not source. It bundles qrgen's generator —
`src/lib/qrcode.ts`, `render.ts`, `shapes.ts`, `options.ts` — so the panel draws
codes with the app's own shape registries, colour handling and centre-asset
geometry rather than a reimplementation that would drift from them.

The script that builds it lives in the qrgen repository under `tools/`, beside
the source it bundles — this repository ships the built file and nothing that
builds it, so installing the plugin never involves a toolchain.

## lean-qr — MIT, © David Evans

<https://github.com/davidje13/lean-qr>

The QR encoder itself, bundled into `renderer.js` along with qrgen. Its licence
text is in the published package and at the link above.

Two things are done to it at build time, both because QML's JavaScript engine is
not a browser:

- The bundle is downlevelled to ES2017. QML rejects object rest in a
  destructuring pattern, which lean-qr's `generate` uses.
- `TextEncoder` is provided by `renderer.js` (a real UTF-8 encoder) and
  `TextDecoder` is stubbed. The stub is only consulted to decide whether
  Shift-JIS mode would make a smaller code, and it always declines: Japanese
  text still encodes correctly, as UTF-8, in a slightly larger code.

## ha.mr — MIT, © p2r3

<https://github.com/p2r3/ha.mr> · licence at `vendor/hamr/LICENSE`

`vendor/hamr/compress.js` and `vendor/hamr/alphabets.js` are copied verbatim
from ha.mr, and are used only when link compression is turned on. They are the
reason that one feature needs node or bun: the algorithm is arbitrary-precision
arithmetic built on BigInt, which QML's engine does not have.

Compressed links resolve through <https://ha.mr>, a third-party service. A code
made with compression turned off depends on nothing.
