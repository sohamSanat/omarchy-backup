.pragma library
// One word request shared by every per-monitor copy of the widget. IPC reaches
// whichever copy claimed the target; that copy leaves the request here and asks
// the shell to open the widget, and the copy that opens (the focused monitor's)
// takes it.

var pending = null

function put(kind, word) {
  pending = { kind: kind, word: String(word || "").trim() }
}

function take() {
  var request = pending
  pending = null
  return request
}
