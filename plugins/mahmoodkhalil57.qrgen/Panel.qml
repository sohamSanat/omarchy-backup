import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "renderer.js" as Renderer

// One bar icon and one dropdown: paste a link, get a QR code.
//
// The generator is the qrgen app's own, bundled into renderer.js and loaded
// straight into QML's JavaScript engine — same shape registries, same colour
// handling, same centre-asset geometry. It runs in process: no subprocess, no
// temporary files, about twenty milliseconds a code, and nothing to install.
//
// The one exception is link compression. ha.mr's compressor is arbitrary
// precision arithmetic built on BigInt, which QML's engine does not have, so
// that alone shells out — and only when the option is on. Without a JavaScript
// runtime the panel says so and everything else carries on working.
Panel {
  id: root
  moduleName: "mahmoodkhalil57.qrgen"
  ipcTarget: "mahmoodkhalil57.qrgen"
  // manageIpc: false so this file can own the single handler the target
  // permits, and add its own methods to it.
  manageIpc: false

  // ---- where things live -------------------------------------------------

  // The scripts ship beside this file, so the plugin stays movable: their path
  // comes off the QML source rather than a hard-coded directory.
  readonly property string pluginDir: {
    var here = String(Qt.resolvedUrl("."))
    return here.indexOf("file://") === 0 ? here.substring(7) : here
  }
  readonly property string home: Quickshell.env("HOME") || ""
  // Only the asset picker needs a scratch file now; codes never touch disk.
  readonly property string workDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/qrgen-panel"

  // Where a site-hosted redirect would point, for anyone running their own copy
  // of qrgen's resolver. Empty by default and deliberately so: a plugin should
  // not quietly route other people's links through somebody's personal domain.
  readonly property string siteRoot: setting("siteRoot", "")

  readonly property string assetDirs: setting("assetDirs",
    [home + "/Pictures", home + "/Downloads", home + "/.local/share/icons/hicolor/256x256/apps"].join("\n"))

  // ---- what goes in the code ---------------------------------------------

  property string link: ""

  // Customize
  property string bodyShape: setting("body", "square")
  property string eyeFrameShape: setting("eyeFrame", "square")
  property string eyeBallShape: setting("eyeBall", "square")
  readonly property string themeForeground: Model.colorToHex(Color.foreground)
  readonly property string themeBackground: Model.colorToHex(Color.background)

  property string foreground: {
    var val = setting("foreground", "")
    return (val === "#111827") ? "" : val
  }
  property string background: {
    var val = setting("background", "")
    return (val === "#ffffff") ? "" : val
  }
  readonly property string effectiveForeground: foreground !== "" ? foreground : themeForeground
  readonly property string effectiveBackground: background !== "" ? background : themeBackground
  property bool transparentBackground: setting("transparentBackground", false) === true
  property string eyeFrameColour: setting("eyeFrameColour", "")
  property string eyeBallColour: setting("eyeBallColour", "")
  property string assetPath: setting("assetPath", "")
  property real assetScale: Model.clamp(setting("assetScale", 0.22), 0.05, 0.4)
  property real assetPadding: Model.clamp(setting("assetPadding", 0.6), 0, 3)
  property bool assetClear: setting("assetClear", true) === true
  property bool assetBackdrop: setting("assetBackdrop", true) === true

  // Advanced. Each automatic flag hands one decision to the renderer; the
  // manual value underneath is kept, so turning automatic off returns to it.
  property bool correctionAuto: setting("correctionAuto", true) === true
  property bool marginAuto: setting("marginAuto", true) === true
  property bool compressAuto: setting("compressAuto", false) === true

  property string level: Model.normalizedLevel(setting("level", "M"), "M")
  property int margin: Math.round(Model.clamp(setting("margin", 4), 0, 16))
  property bool compress: setting("compress", false) === true
  property string compressTarget: setting("compressTarget", "hamr")
  property bool compressEmoji: setting("compressEmoji", false) === true

  // Which sections were open is remembered too: someone who works in
  // Customize every time should not have to open it every time.
  property bool customizeOpen: setting("customizeOpen", false) === true
  property bool advancedOpen: setting("advancedOpen", false) === true

  onCustomizeOpenChanged: persistDebounce.restart()
  onAdvancedOpenChanged: persistDebounce.restart()

  function optionState() {
    return {
      link: root.link,
      level: root.level,
      margin: root.margin,
      body: root.bodyShape,
      eyeFrame: root.eyeFrameShape,
      eyeBall: root.eyeBallShape,
      foreground: root.effectiveForeground,
      background: root.effectiveBackground,
      transparentBackground: root.transparentBackground,
      eyeFrameColour: root.eyeFrameColour,
      eyeBallColour: root.eyeBallColour,
      assetPath: root.assetPath,
      assetScale: root.assetScale,
      assetPadding: root.assetPadding,
      assetClear: root.assetClear,
      assetBackdrop: root.assetBackdrop,
      compress: root.compress,
      compressTarget: root.compressTarget,
      compressEmoji: root.compressEmoji,
      correctionAuto: root.correctionAuto,
      marginAuto: root.marginAuto,
      compressAuto: root.compressAuto
    }
  }
  // One binding that every option feeds into, so a new control needs no new
  // change handler — adding it to optionState() is enough to make it both
  // re-render and persist.
  readonly property string fingerprint: JSON.stringify(optionState())

  onFingerprintChanged: {
    root.status = ""
    renderDebounce.restart()
    persistDebounce.restart()
  }

  // ---- render state ------------------------------------------------------

  property var registries: null
  property var result: null
  property var resolved: null
  property string currentSvg: ""
  property string previewSource: ""
  property string error: ""
  property string status: ""
  // Set when the rendered code could not be read back. The options under
  // Customize can produce one that looks right and does not scan, and nothing
  // about the picture says so.
  property string scanWarning: ""

  // The asset, inlined. Reading a file is the one thing QML cannot do for
  // itself here, so it is done once per asset rather than once per render.
  //
  // bin/qrgen-asset caps what it will read at 2 MiB; base64 is four thirds of
  // that, plus the "data:image/…;base64," it arrives with.
  readonly property int assetDataUriLimit: Math.ceil(2 * 1024 * 1024 / 3) * 4 + 64
  property string assetDataUri: ""
  property string assetLoadedFor: ""

  // Compressed payloads for the current link. They depend on the link alone, so
  // they are fetched once and reused while the styling is fiddled with.
  property var compressCandidates: []
  property string compressCandidatesFor: ""
  property string compressUnavailable: ""

  readonly property bool hasCode: previewSource !== "" && error === ""
  readonly property bool wantsCompression: compress === true || compressAuto === true
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property color contentMuted: Qt.rgba(contentForeground.r, contentForeground.g, contentForeground.b, 0.55)
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  // The dropdowns are built from the app's own registries, so a shape added
  // there turns up here without this file changing.
  readonly property var bodyOptions: registries && registries.body ? registries.body : []
  readonly property var eyeFrameOptions: registries && registries.eyeFrame ? registries.eyeFrame : []
  readonly property var eyeBallOptions: registries && registries.eyeBall ? registries.eyeBall : []

  // ha.mr is always on offer; a site redirect only when one is configured.
  readonly property var targetOptions: {
    var options = [{ value: "hamr", label: "ha.mr" }]
    if (root.siteRoot !== "") {
      var label = root.siteRoot
      try { label = new URL(root.siteRoot).host } catch (e) {}
      options.push({ value: "site", label: label })
    }
    return options
  }

  function targetLabel(value) {
    var options = root.targetOptions
    for (var i = 0; i < options.length; i++) {
      if (options[i] && String(options[i].value) === String(value)) return String(options[i].label)
    }
    return String(value || "")
  }

  // ---- lifecycle ---------------------------------------------------------

  function open() {
    loadRegistries()
    root.controller.show()
    // The field is the point of the panel, so it takes the keyboard as soon as
    // the surface is mapped — paste and the code is there.
    Qt.callLater(function() {
      if (root.opened) linkField.forceActiveFocus()
    })
  }

  function close() {
    root.controller.hide()
    root.status = ""
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function encode(text) {
    root.link = String(text || "")
    linkField.text = root.link
    root.open()
    Qt.callLater(function() { linkField.selectAll() })
  }

  function loadRegistries() {
    if (root.registries) return
    try {
      root.registries = Renderer.QrGenCore.registries()
    } catch (e) {
      root.error = "The generator did not load: " + e
    }
  }

  // Applied locally first so the panel redraws on the change itself; the
  // shell.json write comes back through the bar as the same values.
  function persistSettings() {
    var entry = { id: root.moduleName }
    for (var existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]

    var state = optionState()
    // The link is what you are encoding right now, not a preference.
    delete state.link
    for (var key in state) entry[key] = state[key]

    entry.foreground = root.foreground
    entry.background = root.background

    entry.customizeOpen = root.customizeOpen
    entry.advancedOpen = root.advancedOpen

    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  // ---- rendering ---------------------------------------------------------

  function clearPreview() {
    root.previewSource = ""
    root.currentSvg = ""
    root.result = null
    root.resolved = null
    root.error = ""
    root.scanWarning = ""
  }

  // The largest payload any QR version and mode can hold — numeric, version 40,
  // level L. Past this no code exists at all, so nothing downstream should be
  // asked to try: not the encoder, and not the compressor, which would happily
  // spend a second on a megabyte of pasted text before anyone could use it.
  readonly property int maxPayload: 7089

  function render() {
    loadRegistries()

    var link = String(root.link).trim()
    if (link === "") { clearPreview(); return }

    if (link.length > root.maxPayload) {
      clearPreview()
      root.error = "That is longer than any QR code can hold (" + link.length
        + " characters, limit " + root.maxPayload + ")"
      return
    }

    // Both of these answer asynchronously and re-enter here when they land.
    if (root.assetPath !== "" && root.assetLoadedFor !== root.assetPath) { loadAsset(); return }
    if (root.wantsCompression && root.compressCandidatesFor !== link
        && root.compressUnavailable === "") { loadCandidates(link); return }

    var state = root.optionState()
    var candidates = root.compressCandidatesFor === link ? root.compressCandidates : []
    var planned = Model.plan(state, candidates, Renderer.QrGenCore.versionOf)
    if (!planned) { clearPreview(); return }
    if (planned.pending === true) return // waiting on something; keep what is up

    var out = Renderer.QrGenCore.render(
      planned.text,
      Model.renderOptions(state, planned, root.assetPath !== "" ? root.assetDataUri : ""),
      planned.alphanumeric
    )

    if (!out || out.ok !== true) {
      // No stale code left under an error: what is on screen must always be the
      // link that is in the field.
      root.error = out && out.error ? String(out.error) : "Could not make a code"
      root.previewSource = ""
      root.currentSvg = ""
      root.result = null
      root.scanWarning = ""
      return
    }

    root.error = ""
    root.result = out
    root.resolved = planned
    root.currentSvg = out.svg
    // Straight from memory into the image: an SVG the size of a QR code fits a
    // data URI comfortably, and nothing has to be written down to show it.
    root.previewSource = "data:image/svg+xml;utf8," + encodeURIComponent(out.svg)
    root.scanWarning = ""

    // The scan check is the only thing the common path spawns, so it waits for
    // the typing to stop rather than running once per keystroke.
    verifyDebounce.restart()
  }

  function loadAsset() {
    if (assetProc.running) return
    assetProc.wanted = root.assetPath
    // Never base64 the path directly: it can come from a stored setting as
    // easily as from the picker, and this shell process is shared with the bar
    // and everything else on it. qrgen-asset does the judging, bounds the read,
    // and hands back a finished data URI or a reason.
    assetProc.command = [root.pluginDir + "bin/qrgen-asset", root.assetPath]
    assetProc.running = true
  }

  function loadCandidates(link) {
    if (compressProc.running) return
    compressProc.wanted = link
    var command = [root.pluginDir + "bin/qrgen-compress", "--link", link]
    if (root.siteRoot !== "") {
      command.push("--site-root", root.siteRoot)
      command.push("--targets", "hamr,site")
    }
    compressProc.command = command
    compressProc.running = true
  }

  function runExport(action) {
    if (!root.hasCode || root.currentSvg === "" || exportProc.running) return
    exportProc.payload = root.currentSvg
    exportProc.stdinEnabled = true
    exportProc.command = [root.pluginDir + "bin/qrgen-export", action]
    exportProc.running = true
  }

  // ---- the centre asset --------------------------------------------------

  property string assetSelectionFile: ""
  property string assetDoneFile: ""

  function chooseAsset() {
    if (!root.bar || !root.bar.shell || typeof root.bar.shell.summon !== "function") {
      root.status = "The image picker is not available"
      return
    }
    root.assetSelectionFile = root.workDir + "/asset-selection"
    root.assetDoneFile = root.workDir + "/asset-done"
    // Clear both first: a previous run's answer still sitting there would be
    // read as this run's the moment polling starts.
    assetResetProc.command = ["mkdir", "-p", root.workDir]
    assetResetProc.running = true
  }

  function summonAssetPicker() {
    root.bar.shell.summon("omarchy.image-picker", JSON.stringify({
      imageDirs: root.assetDirs,
      selectedImage: root.assetPath,
      selectionFile: root.assetSelectionFile,
      doneFile: root.assetDoneFile,
      showLabels: true,
      filterable: true
    }))
    // The picker is a fullscreen overlay, so this panel goes away while it is
    // up. Every option is a property on this object, which outlives the popup
    // surface, so reopening afterwards comes back to exactly this state.
    root.close()
    assetPoll.attempts = 0
    assetPoll.restart()
  }

  function clearAsset() {
    root.assetPath = ""
    root.assetDataUri = ""
    root.assetLoadedFor = ""
  }

  onLinkChanged: {
    root.status = ""
    renderDebounce.restart()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ---- processes ---------------------------------------------------------

  Timer {
    id: renderDebounce
    // Rendering is in process and takes about twenty milliseconds, so this is
    // short: long enough to coalesce a burst of typing, not long enough to feel
    // like waiting.
    interval: 90
    onTriggered: root.render()
  }

  Timer {
    id: verifyDebounce
    interval: 400
    onTriggered: {
      if (!root.hasCode || root.currentSvg === "" || !root.resolved) return
      if (verifyProc.running) { verifyDebounce.restart(); return }
      verifyProc.expected = root.resolved.text
      verifyProc.decoded = ""
      verifyProc.running = true
    }
  }

  Timer {
    id: persistDebounce
    // Dragging a slider walks through dozens of values; only where it comes to
    // rest is worth writing to shell.json.
    interval: 600
    onTriggered: root.persistSettings()
  }

  // The asset as a data URI. An SVG that carries its own image renders the same
  // everywhere it is opened — the preview, the exported PNG, and anything the
  // file is later handed to.
  // Exit and stream-finished have no guaranteed order, so neither one alone can
  // act on a result: the exit may arrive before the output it describes. Each
  // of the three readers below records its half and settles once both are in.
  Process {
    id: assetProc
    property string wanted: ""
    property string encoded: ""
    property string reason: ""
    property bool streamed: false
    property bool exited: false
    property int code: -1

    function settle() {
      if (!streamed || !exited) return
      streamed = false
      exited = false

      var path = assetProc.wanted
      var data = assetProc.encoded
      var why = assetProc.reason
      assetProc.encoded = ""
      assetProc.reason = ""

      if (assetProc.code !== 0 || data === "") {
        root.error = why !== "" ? why : "Could not read that asset"
        return
      }

      // The reader caps what it emits, so this only ever fires if that cap has
      // been changed without this one: a belt to its braces, not a substitute.
      if (data.length > root.assetDataUriLimit || data.indexOf("data:image/") !== 0) {
        root.error = "That asset came back malformed or too large"
        return
      }

      root.assetDataUri = data
      root.assetLoadedFor = path
      root.render()
    }

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        assetProc.encoded = String(text || "").trim()
        assetProc.streamed = true
        assetProc.settle()
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: assetProc.reason = String(text || "").trim().split("\n")[0]
    }

    onExited: function(exitCode) {
      assetProc.code = exitCode
      assetProc.exited = true
      assetProc.settle()
    }
  }

  Process {
    id: compressProc
    property string wanted: ""
    property string output: ""
    property bool streamed: false
    property bool exited: false
    property int code: -1

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        compressProc.output = String(text || "").trim()
        compressProc.streamed = true
        compressProc.settle()
      }
    }

    onExited: function(exitCode) {
      compressProc.code = exitCode
      compressProc.exited = true
      compressProc.settle()
    }

    function settle() {
      if (!streamed || !exited) return
      streamed = false
      exited = false

      var link = compressProc.wanted
      var raw = compressProc.output
      compressProc.output = ""

      var parsed = null
      try { parsed = JSON.parse(raw) } catch (e) { parsed = null }

      if (compressProc.code === 127) {
        // No JavaScript runtime. Remember it: retrying per keystroke would
        // spawn a process a second to be told the same thing.
        root.compressUnavailable = parsed && parsed.error
          ? String(parsed.error) : "Link compression needs Node.js or Bun on PATH"
        root.render()
        return
      }

      root.compressCandidatesFor = link
      if (parsed && parsed.ok === true && parsed.candidates) {
        // Normalised at the boundary: the script speaks in qrText, the planner
        // weighs candidates that all look the same shape as an uncompressed one.
        root.compressCandidates = parsed.candidates.map(function(candidate) {
          return {
            compress: true,
            target: candidate.target,
            emoji: candidate.emoji === true,
            text: String(candidate.qrText || ""),
            alphanumeric: candidate.alphanumeric === true,
            shareURL: String(candidate.shareURL || ""),
            payload: String(candidate.payload || "")
          }
        })
        root.compressUnavailable = ""
      } else {
        root.compressCandidates = []
        root.compressUnavailable = parsed && parsed.error
          ? String(parsed.error) : "Could not compress the link"
      }
      root.render()
    }
  }

  Process {
    id: exportProc
    property string payload: ""
    stdinEnabled: true

    onStarted: {
      write(exportProc.payload)
      exportProc.payload = ""
      stdinEnabled = false
    }

    onExited: {
      stdinEnabled = true
    }

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var message = String(text || "").trim()
        if (message !== "") root.status = message
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var message = String(text || "").trim()
        if (message !== "") root.status = message
      }
    }
  }

  // Reads the rendered code back and says so when it does not come out again.
  // Silent when there is no decoder on the system: an unchecked code is the
  // normal state everywhere else, and a warning nobody can act on is noise.
  Process {
    id: verifyProc
    property string expected: ""
    property string decoded: ""
    stdinEnabled: true

    onStarted: {
      write(root.currentSvg)
      stdinEnabled = false
    }

    property bool streamed: false
    property bool exited: false
    property int code: -1

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        verifyProc.decoded = String(text || "").trim()
        verifyProc.streamed = true
        verifyProc.settle()
      }
    }

    onExited: function(exitCode) {
      verifyProc.code = exitCode
      verifyProc.exited = true
      verifyProc.settle()
    }

    function settle() {
      if (!streamed || !exited) return
      streamed = false
      exited = false

      var expected = verifyProc.expected
      var decoded = verifyProc.decoded
      verifyProc.expected = ""
      verifyProc.decoded = ""

      if (verifyProc.code === 3) return
      // A check for a render that has already been superseded says nothing
      // about the code now on screen.
      if (!root.resolved || expected !== String(root.resolved.text || "")) return

      root.scanWarning = (decoded !== "" && decoded === expected)
        ? ""
        : "This code did not read back. Try a smaller asset, a wider quiet zone, or a shorter link."
    }
  }

  Process {
    id: assetResetProc
    onExited: {
      assetClearProc.command = ["rm", "-f", root.assetSelectionFile, root.assetDoneFile]
      assetClearProc.running = true
    }
  }

  Process {
    id: assetClearProc
    onExited: root.summonAssetPicker()
  }

  Timer {
    id: assetPoll
    property int attempts: 0
    interval: 250
    repeat: true
    onTriggered: {
      attempts += 1
      // Two minutes of picking is generous; past that the answer is not coming.
      if (attempts > 480) { assetPoll.stop(); return }
      if (assetPickedProc.running) return
      assetPickedProc.command = [root.pluginDir + "bin/qrgen-picked", root.assetDoneFile, root.assetSelectionFile]
      assetPickedProc.running = true
    }
  }

  Process {
    id: assetPickedProc
    property string picked: ""
    property bool streamed: false
    property bool exited: false
    property int code: -1

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        assetPickedProc.picked = String(text || "").trim()
        assetPickedProc.streamed = true
        assetPickedProc.settle()
      }
    }

    onExited: function(exitCode) {
      assetPickedProc.code = exitCode
      assetPickedProc.exited = true
      assetPickedProc.settle()
    }

    function settle() {
      if (!streamed || !exited) return
      streamed = false
      exited = false

      if (assetPickedProc.code === 3) return // still choosing
      assetPoll.stop()
      if (assetPickedProc.code === 0 && assetPickedProc.picked !== "") {
        root.assetPath = assetPickedProc.picked
      }
      assetPickedProc.picked = ""
      root.open()
    }
  }

  IpcHandler {
    target: "mahmoodkhalil57.qrgen"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function encode(text: string): void { root.encode(text) }
    function copy(): void { root.runExport("copy") }
    function save(): void { root.runExport("save") }
    function level(value: string): void { root.level = Model.normalizedLevel(value, root.level) }
  }

  // ---- the bar button ----------------------------------------------------

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf029"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "QR code generator"
    onPressed: root.toggle()
  }

  // ---- the dropdown ------------------------------------------------------

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      // Whichever field is being typed into owns the keyboard; each handles
      // Escape itself so the panel still closes from inside one.
      blocked: linkField.activeFocus || assetField.activeFocus
        || foregroundField.editing || backgroundField.editing
        || eyeFrameField.editing || eyeBallField.editing
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      // Expanded sections can outgrow the screen, and the card is capped to
      // it, so the content scrolls rather than being cut off.
      Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        ColumnLayout {
          id: column
          width: parent.width
          spacing: Style.space(10)

          // ---- link ------------------------------------------------------

          PanelSectionHeader {
            text: "LINK"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            Layout.fillWidth: true
          }

          TextField {
            id: linkField
            placeholderText: "https://example.com"
            foreground: root.contentForeground
            font.family: root.contentFontFamily
            Layout.fillWidth: true

            onTextChanged: root.link = text
            Keys.onEscapePressed: function(event) {
              root.close()
              event.accepted = true
            }
          }

          // ---- the code --------------------------------------------------

          Rectangle {
            id: canvas
            readonly property int side: Math.min(Style.space(224), column.width)

            visible: root.hasCode
            implicitWidth: side
            implicitHeight: side
            radius: Style.cornerRadius
            // The rendered code carries its own background unless it was asked
            // not to; a transparent one gets a neutral card so dark modules
            // stay visible against a dark panel.
            color: root.transparentBackground ? "#d4d4d8" : "transparent"
            Layout.alignment: Qt.AlignHCenter

            Image {
              anchors.fill: parent
              source: root.previewSource
              sourceSize.width: canvas.side * 2
              sourceSize.height: canvas.side * 2
              fillMode: Image.PreserveAspectFit
              smooth: true
              cache: false
            }
          }

          Text {
            visible: !root.hasCode
            text: root.error !== "" ? root.error : "Paste a link to make a code"
            color: root.error !== "" ? Color.urgent : root.contentMuted
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.topMargin: Style.space(14)
            Layout.bottomMargin: Style.space(14)
          }

          Text {
            visible: root.hasCode && root.scanWarning !== ""
            text: root.scanWarning
            color: Color.urgent
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
          }

          Text {
            visible: root.hasCode
            text: Model.describe(root.result, root.resolved)
            color: root.contentMuted
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
          }

          PanelSeparator {
            foreground: root.contentForeground
            Layout.fillWidth: true
          }

          // ---- customize -------------------------------------------------

          Section {
            title: "CUSTOMIZE"
            expanded: root.customizeOpen
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            Layout.fillWidth: true
            onToggleRequested: root.customizeOpen = !root.customizeOpen

            Dropdown {
              label: "Body"
              value: root.bodyShape
              options: root.bodyOptions
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.bodyShape = value }
            }

            Dropdown {
              label: "Eye frame"
              value: root.eyeFrameShape
              options: root.eyeFrameOptions
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.eyeFrameShape = value }
            }

            Dropdown {
              label: "Eye ball"
              value: root.eyeBallShape
              options: root.eyeBallOptions
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.eyeBallShape = value }
            }

            ColourField {
              id: foregroundField
              label: "Foreground"
              value: root.foreground
              placeholder: "theme"
              allowEmpty: true
              swatchFallback: root.themeForeground
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.foreground = value }
            }

            ColourField {
              id: backgroundField
              label: "Background"
              value: root.background
              placeholder: "theme"
              allowEmpty: true
              swatchFallback: root.themeBackground
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.background = value }
            }

            SwitchRow {
              label: "Transparent background"
              checked: root.transparentBackground
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onToggled: function(value) { root.transparentBackground = value }
            }

            ColourField {
              id: eyeFrameField
              label: "Eye frame colour"
              value: root.eyeFrameColour
              placeholder: "inherit"
              allowEmpty: true
              swatchFallback: root.effectiveForeground
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.eyeFrameColour = value }
            }

            ColourField {
              id: eyeBallField
              label: "Eye ball colour"
              value: root.eyeBallColour
              placeholder: "inherit"
              allowEmpty: true
              swatchFallback: root.effectiveForeground
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.eyeBallColour = value }
            }

            PanelSeparator {
              foreground: root.contentForeground
              Layout.fillWidth: true
            }

            TextField {
              id: assetField
              text: root.assetPath
              placeholderText: "Asset — image path"
              foreground: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true

              onEditingFinished: root.assetPath = text
              onAccepted: root.assetPath = text
              Keys.onEscapePressed: function(event) {
                root.close()
                event.accepted = true
              }
            }

            RowLayout {
              spacing: Style.space(8)
              Layout.fillWidth: true

              Button {
                text: "Choose"
                bordered: true
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                Layout.fillWidth: true
                onClicked: root.chooseAsset()
              }

              Button {
                text: "Clear"
                bordered: true
                enabled: root.assetPath !== ""
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                Layout.fillWidth: true
                onClicked: root.clearAsset()
              }
            }

            SliderRow {
              visible: root.assetPath !== ""
              bar: root.bar
              scrollTarget: flick
              label: "Asset size"
              readout: Math.round(root.assetScale * 100) + "%"
              value: root.assetScale
              minimum: 0.05
              maximum: 0.4
              step: 0.01
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onMoved: function(value) { root.assetScale = value }
            }

            SliderRow {
              visible: root.assetPath !== ""
              bar: root.bar
              scrollTarget: flick
              label: "Asset padding"
              readout: root.assetPadding.toFixed(1) + " modules"
              value: root.assetPadding
              minimum: 0
              maximum: 3
              step: 0.1
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onMoved: function(value) { root.assetPadding = value }
            }

            SwitchRow {
              visible: root.assetPath !== ""
              label: "Punch out modules"
              checked: root.assetClear
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onToggled: function(value) { root.assetClear = value }
            }

            SwitchRow {
              visible: root.assetPath !== ""
              label: "Backdrop behind it"
              checked: root.assetBackdrop
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onToggled: function(value) { root.assetBackdrop = value }
            }
          }

          PanelSeparator {
            foreground: root.contentForeground
            Layout.fillWidth: true
          }

          // ---- advanced --------------------------------------------------

          Section {
            title: "ADVANCED"
            expanded: root.advancedOpen
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            Layout.fillWidth: true
            onToggleRequested: root.advancedOpen = !root.advancedOpen

            // ---- error correction ----------------------------------

            SwitchRow {
              label: "Automatic error correction"
              checked: root.correctionAuto
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onToggled: function(value) { root.correctionAuto = value }
            }

            Text {
              visible: root.correctionAuto && root.hasCode && Model.describeCorrection(root.resolved) !== ""
              text: Model.describeCorrection(root.resolved)
              color: root.contentMuted
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }

            Dropdown {
              visible: !root.correctionAuto
              label: "Error correction"
              value: root.level
              options: Model.correctionLevels()
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.level = value }
            }

            // ---- quiet zone ----------------------------------------

            SwitchRow {
              label: "Automatic quiet zone"
              checked: root.marginAuto
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onToggled: function(value) { root.marginAuto = value }
            }

            Text {
              visible: root.marginAuto && root.hasCode && Model.describeMargin(root.resolved) !== ""
              text: Model.describeMargin(root.resolved)
              color: root.contentMuted
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }

            Stepper {
              visible: !root.marginAuto
              label: "Quiet zone"
              value: root.margin
              minimum: 0
              maximum: 16
              suffix: root.margin === 1 ? "module" : "modules"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.margin = value }
            }

            // ---- link compression ----------------------------------

            SwitchRow {
              label: "Automatic link compression"
              checked: root.compressAuto
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onToggled: function(value) { root.compressAuto = value }
            }

            Text {
              visible: root.compressAuto && root.hasCode
                && Model.describeCompression(root.resolved, root.targetLabel(root.resolved ? root.resolved.compressTarget : "")) !== ""
              text: Model.describeCompression(root.resolved, root.targetLabel(root.resolved ? root.resolved.compressTarget : ""))
              color: root.contentMuted
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }

            // The only part of the plugin that needs anything on PATH, so it
            // says which thing rather than just refusing.
            Text {
              visible: root.compressUnavailable !== "" && root.wantsCompression
              text: root.compressUnavailable
              color: Color.urgent
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }

            SwitchRow {
              visible: !root.compressAuto
              label: "Compress the link"
              checked: root.compress
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onToggled: function(value) { root.compress = value }
            }

            Dropdown {
              visible: !root.compressAuto && root.compress
              label: "Redirect through"
              value: root.compressTarget
              options: root.targetOptions
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onChanged: function(value) { root.compressTarget = value }
            }

            SwitchRow {
              visible: !root.compressAuto && root.compress
              label: "Emoji payload"
              checked: root.compressEmoji
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onToggled: function(value) { root.compressEmoji = value }
            }

            // Emoji is a way to make a link look short, not a way to make a
            // code small — it is worth saying so where the switch is. Automatic
            // reaches the same conclusion by measuring, and leaves it off.
            Text {
              visible: !root.compressAuto && root.compress && root.compressEmoji
              text: "Emoji is UTF-8, so the code gets bigger even though the link reads shorter."
              color: root.contentMuted
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }

            Text {
              visible: root.compress && root.hasCode && root.result && root.result.shareURL
              text: root.result && root.result.shareURL ? root.result.shareURL : ""
              color: root.contentMuted
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WrapAnywhere
              Layout.fillWidth: true
            }
          }

          PanelSeparator {
            foreground: root.contentForeground
            Layout.fillWidth: true
          }

          // ---- export ----------------------------------------------------

          RowLayout {
            spacing: Style.space(8)
            Layout.fillWidth: true

            Button {
              text: "Copy PNG"
              bordered: true
              enabled: root.hasCode
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onClicked: root.runExport("copy")
            }

            Button {
              text: "Save PNG"
              bordered: true
              enabled: root.hasCode
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              Layout.fillWidth: true
              onClicked: root.runExport("save")
            }
          }

          Text {
            visible: root.status !== ""
            text: root.status
            color: root.contentMuted
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}
