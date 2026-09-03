# ha.mr, vendored

`compress.js` and `alphabets.js` are copied **verbatim** from ha.mr. They are
not modified and not reimplemented — `bin/qrgen-compress.mjs` only decides what
the payload they produce gets wrapped in.

| | |
| --- | --- |
| Upstream | <https://github.com/p2r3/ha.mr> |
| Licence | MIT, © p2r3 — see `LICENSE` beside this file |
| Used by | `bin/qrgen-compress.mjs`, when link compression is on |

They are the reason link compression needs node or bun: the algorithm is
arbitrary-precision arithmetic built on BigInt, and QML's JavaScript engine has
no BigInt. Nothing else in the plugin needs a runtime.
