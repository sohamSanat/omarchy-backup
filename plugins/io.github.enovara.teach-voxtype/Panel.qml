import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Request.js" as Request

// Teach Voxtype: a bar mic that follows voxtype's status and opens a word
// trainer. Type the word, say it a few times when prompted, review how Whisper
// misheard it, and map the mishearings to the right spelling. The work is done
// by voxwords.py next to this file (also used by the teach-voxtype-word skill).
Panel {
  id: root
  moduleName: "io.github.enovara.teach-voxtype"
  ipcTarget: "io.github.enovara.teach-voxtype"
  manageIpc: false

  readonly property string engine: Qt.resolvedUrl("voxwords.py").toString().replace(/^file:\/\//, "")
  readonly property int takeCount: Math.max(2, Number(setting("takes", 6)) || 6)
  readonly property int takeSeconds: Math.max(2, Number(setting("seconds", 3)) || 3)
  readonly property var takePrompts: [
    "Say just the word",
    "Say it slowly",
    "Say it quickly",
    "Say it in a short sentence",
    "Say just the word again",
    "Say it at the end of a sentence",
    "Say it a little quieter",
    "Say it in a sentence again"
  ]

  // idle -> countdown/recording (per take) -> probing -> review -> applying -> done
  property string phase: "idle"
  property string word: ""
  property int take: 0
  property int countdown: 0
  property real recordProgress: 0
  property var probe: null
  property var chosen: ({})
  property var applied: null
  property string errorText: ""

  // Voxtype status for the bar mic.
  property string micGlyph: ""
  property string micState: "idle"
  property string micTooltip: "Voxtype"

  readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property string slug: word.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "word"
  readonly property string takeDir: Quickshell.env("HOME") + "/.local/state/voxwords/" + slug
  readonly property bool busy: phase === "countdown" || phase === "recording" || phase === "probing" || phase === "applying"
  readonly property var variants: probe && probe.variants ? probe.variants : []
  readonly property int chosenCount: {
    var n = 0
    for (var k in chosen) if (chosen[k]) n++
    return n
  }

  function takeFile(i) { return root.takeDir + "/" + root.slug + "-" + i + ".wav" }

  function takeFiles() {
    var files = []
    for (var i = 1; i <= root.takeCount; i++) files.push(root.takeFile(i))
    return files
  }

  function reset() {
    stopAll()
    root.phase = "idle"
    root.take = 0
    root.probe = null
    root.chosen = ({})
    root.applied = null
    root.errorText = ""
  }

  function stopAll() {
    countdownTimer.stop()
    progressTimer.stop()
    nextTakeTimer.stop()
    if (recordProc.running) recordProc.running = false
    if (probeProc.running) probeProc.running = false
  }

  function start() {
    var w = wordField.text.trim()
    if (!w || root.busy) return
    reset()
    root.word = w
    prepProc.command = ["sh", "-c", "rm -rf \"$1\" && mkdir -p \"$1\"", "sh", root.takeDir]
    prepProc.running = true
  }

  function beginTake(i) {
    root.take = i
    root.countdown = 3
    root.phase = "countdown"
    countdownTimer.restart()
  }

  function recordTake() {
    root.phase = "recording"
    root.recordProgress = 0
    recordProc.command = ["timeout", String(root.takeSeconds), "pw-record", "--rate", "16000",
                          "--channels", "1", "--format", "s16", root.takeFile(root.take)]
    recordProc.running = true
    progressTimer.restart()
  }

  function takeFinished() {
    progressTimer.stop()
    if (root.phase !== "recording") return
    if (root.take < root.takeCount) nextTakeTimer.restart()
    else runProbe()
  }

  function runProbe() {
    root.phase = "probing"
    root.errorText = ""
    probeProc.command = ["python3", root.engine, "probe", root.word].concat(root.takeFiles())
    probeProc.running = true
  }

  function probeFinished(text) {
    var result = null
    try { result = JSON.parse(String(text || "").trim()) } catch (e) {}
    if (!result || result.status !== "ok") {
      root.errorText = result && result.message ? result.message : "Could not transcribe the recordings"
      root.phase = "idle"
      return
    }
    var picks = {}
    for (var i = 0; i < result.variants.length; i++) picks[result.variants[i].heard] = result.variants[i].suggested === true
    root.probe = result
    root.chosen = picks
    root.phase = "review"
  }

  // The bar mounts one copy of this widget per monitor and only one copy owns
  // the IPC target, which is not necessarily the focused monitor's. So IPC
  // leaves the word in Request.js and asks the shell to open the widget the way
  // a hotkey does; the copy that opens takes the request (see onOpenedChanged).
  function requestFromIpc(kind, w) {
    if (!String(w || "").trim()) return
    Request.put(kind, w)
    var shell = root.bar ? root.bar.shell : null
    if (shell && typeof shell.summon === "function") shell.summon(root.moduleName, "")
    else root.open()
    if (root.opened) takeRequest()
  }

  function takeRequest() {
    var request = Request.take()
    if (!request || !request.word || root.busy) return
    wordField.text = request.word
    if (request.kind === "teach") {
      start()
    } else {
      reset()
      root.word = request.word
      runProbe()
    }
  }

  function toggleVariant(heard) {
    var next = Object.assign({}, root.chosen)
    next[heard] = !next[heard]
    root.chosen = next
  }

  function applyChosen() {
    var picks = []
    for (var k in root.chosen) if (root.chosen[k]) picks.push(k)
    root.phase = "applying"
    applyProc.command = ["python3", root.engine, "apply", root.word].concat(picks)
    applyProc.running = true
  }

  function applyFinished(text) {
    var result = null
    try { result = JSON.parse(String(text || "").trim()) } catch (e) {}
    if (!result || result.status === "error") {
      root.errorText = result && result.message ? result.message : "Could not update voxtype"
      root.phase = "review"
      return
    }
    root.applied = result
    root.phase = "done"
  }

  function correctText(result) {
    if (!result || !result.correctByModel) return ""
    var parts = []
    for (var m in result.correctByModel) parts.push(m + " " + result.correctByModel[m] + "/" + result.takes)
    return parts.join("  ·  ")
  }

  onOpenedChanged: {
    if (opened) Qt.callLater(root.takeRequest)
    if (opened && !root.busy) Qt.callLater(function() { wordField.forceActiveFocus(); wordField.selectAll() })
    // Closing mid-recording cancels the takes; transcribing and applying finish.
    if (!opened && (root.phase === "countdown" || root.phase === "recording")) root.reset()
  }

  IpcHandler {
    target: "io.github.enovara.teach-voxtype"

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
    function teach(word: string) { root.requestFromIpc("teach", word) }
    function review(word: string) { root.requestFromIpc("review", word) }

    function setListening(): string {
      root.micState = "recording"
      root.micTooltip = "Omarchy Flow: Recording"
      return "ok"
    }
    function setTranscribing(status: string): string {
      root.micState = "transcribing"
      root.micTooltip = "Omarchy Flow: " + (status || "Transcribing...")
      return "ok"
    }
    function setDone(): string {
      root.micState = "idle"
      root.micTooltip = "Omarchy Flow: Ready"
      return "ok"
    }
    function setPaused(): string {
      root.micState = "paused"
      root.micTooltip = "Omarchy Flow: Paused"
      return "ok"
    }
    function setResumed(): string {
      root.micState = "recording"
      root.micTooltip = "Omarchy Flow: Recording"
      return "ok"
    }
    function setStatus(status: string): string {
      if (status) {
        root.micState = "idle"
        root.micTooltip = "Omarchy Flow: " + status
      }
      return "ok"
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ---- voxtype status for the bar mic
  Process {
    id: statusProc
    running: true
    command: ["voxtype", "status", "--follow", "--format", "json", "--icon-theme", "nerd-font"]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var s = JSON.parse(line)
          if (s.text) root.micGlyph = s.text
          if (root.micState !== "recording" && root.micState !== "transcribing") {
            root.micState = s["class"] || s.alt || "idle"
            root.micTooltip = s.tooltip || "Voxtype"
          }
        } catch (e) {}
      }
    }
    onExited: statusRestart.restart()
  }

  Timer { id: statusRestart; interval: 5000; onTriggered: statusProc.running = true }

  // ---- recording flow
  Process {
    id: prepProc
    onExited: function(code) {
      if (code === 0) root.beginTake(1)
      else { root.errorText = "Could not create " + root.takeDir; root.phase = "idle" }
    }
  }

  Timer {
    id: countdownTimer
    interval: 650
    repeat: true
    onTriggered: {
      root.countdown -= 1
      if (root.countdown <= 0) { stop(); root.recordTake() }
    }
  }

  Process {
    id: recordProc
    onExited: root.takeFinished()
  }

  Timer {
    id: progressTimer
    interval: 100
    repeat: true
    onTriggered: root.recordProgress = Math.min(1, root.recordProgress + interval / (root.takeSeconds * 1000))
  }

  Timer { id: nextTakeTimer; interval: 700; onTriggered: root.beginTake(root.take + 1) }

  Process {
    id: probeProc
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.probeFinished(text) }
  }

  Process {
    id: applyProc
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyFinished(text) }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.micGlyph
    active: root.micState === "recording" || root.phase === "recording"
    tooltipText: root.opened ? "" : (root.micTooltip || "Voice Dictation") + "\nLeft-click: teach a word\nRight-click: toggle voice dictation"
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        var shell = root.bar ? root.bar.shell : null
        if (shell && typeof shell.call === "function") {
          shell.call("io.github.ef-code.omarchy-flow", "toggle", "")
        } else {
          root.bar.run("flowctl toggle")
        }
      } else {
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: wordField
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: wordField.activeFocus
      onCloseRequested: {
        if (root.busy) root.reset()
        else root.close()
      }
      onActivateRequested: {
        if (root.phase === "review" && root.chosenCount > 0) root.applyChosen()
      }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: column
          width: parent.width
          spacing: Style.space(12)

          // ---------- Header
          Row {
            spacing: Style.space(10)
            Text {
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: ""
              color: Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
            Column {
              anchors.verticalCenter: parent.verticalCenter
              Text {
                textFormat: Text.PlainText
                text: "Teach voxtype a word"
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.heading
                font.bold: true
              }
              Text {
                textFormat: Text.PlainText
                text: "Say it " + root.takeCount + " times; map how Whisper mishears it"
                color: root.fg
                opacity: 0.6
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }
          }

          // ---------- Word entry
          Row {
            width: parent.width
            spacing: Style.space(8)

            TextField {
              id: wordField
              width: parent.width - startButton.width - parent.spacing
              placeholderText: "Word as it should be typed, e.g. Enovara"
              foreground: root.fg
              font.family: root.fontFamily
              enabled: !root.busy
              onAccepted: root.start()
              Keys.onEscapePressed: root.close()
            }

            Button {
              id: startButton
              iconText: root.phase === "idle" ? "" : ""
              text: root.phase === "idle" ? "Start" : "Again"
              fontSize: Style.font.bodySmall
              foreground: root.fg
              fontFamily: root.fontFamily
              bordered: true
              enabled: !root.busy && wordField.text.trim().length > 0
              onClicked: root.start()
            }
          }

          Text {
            visible: root.errorText !== ""
            width: parent.width
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: root.errorText
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          // ---------- Recording
          Column {
            visible: root.phase === "countdown" || root.phase === "recording"
            width: parent.width
            spacing: Style.space(8)

            PanelSeparator { foreground: root.fg }

            Text {
              textFormat: Text.PlainText
              text: "Take " + root.take + " of " + root.takeCount + "  ·  " + root.takePrompts[(root.take - 1) % root.takePrompts.length]
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              textFormat: Text.PlainText
              text: root.phase === "countdown" ? String(root.countdown) : "Speak now"
              color: root.phase === "recording" ? Color.accent : root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge
              font.bold: true
            }

            Rectangle {
              width: parent.width
              height: Style.space(6)
              radius: Style.cornerRadius > 0 ? height / 2 : 0
              color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
              Rectangle {
                width: parent.width * (root.phase === "recording" ? root.recordProgress : 0)
                height: parent.height
                radius: parent.radius
                color: Color.accent
              }
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(6)
              Repeater {
                model: root.takeCount
                Rectangle {
                  required property int index
                  width: Style.space(8); height: width; radius: width / 2
                  color: index + 1 < root.take ? Color.accent : (index + 1 === root.take ? root.fg : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.2))
                }
              }
            }
          }

          // ---------- Transcribing / applying
          Text {
            visible: root.phase === "probing" || root.phase === "applying"
            width: parent.width
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: root.phase === "probing"
              ? "Transcribing " + root.takeCount + " takes with your Whisper models…"
              : "Updating voxtype and restarting it…"
            color: root.fg
            opacity: 0.8
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          // ---------- Review
          Column {
            visible: root.phase === "review"
            width: parent.width
            spacing: Style.space(8)

            PanelSeparator { foreground: root.fg }

            PanelSectionHeader {
              text: "HOW WHISPER HEARD \"" + root.word.toUpperCase() + "\""
              foreground: root.fg
              fontFamily: root.fontFamily
            }

            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              textFormat: Text.PlainText
              text: "Spelled right: " + root.correctText(root.probe)
              color: root.fg
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              visible: root.variants.length === 0
              width: parent.width
              wrapMode: Text.WordWrap
              textFormat: Text.PlainText
              text: "No mishearings: voxtype already gets this word right. Apply still adds it to the vocabulary hint."
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            Repeater {
              model: root.variants

              Rectangle {
                id: variantRow
                required property var modelData
                readonly property bool picked: root.chosen[modelData.heard] === true
                width: column.width
                height: Style.space(34)
                radius: Style.cornerRadius
                color: rowMouse.containsMouse ? Style.hoverFillFor(root.fg, Color.accent) : "transparent"

                Rectangle {
                  id: box
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter
                  width: Style.space(16); height: width
                  radius: Style.cornerRadius > 0 ? 3 : 0
                  color: variantRow.picked ? Color.accent : "transparent"
                  border.width: 1
                  border.color: variantRow.picked ? Color.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.5)
                  Text {
                    anchors.centerIn: parent
                    visible: variantRow.picked
                    text: "✓"
                    color: Color.background
                    font.pixelSize: 10
                    font.bold: true
                  }
                }

                Column {
                  anchors.left: box.right
                  anchors.leftMargin: Style.space(10)
                  anchors.right: parent.right
                  anchors.rightMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    width: parent.width
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: "\"" + variantRow.modelData.heard + "\"  →  " + root.word
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: variantRow.picked
                  }
                  Text {
                    width: parent.width
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: "heard " + variantRow.modelData.count + "×  ·  " + variantRow.modelData.models.join(", ")
                      + (variantRow.modelData.realWord === true ? "  ·  REAL WORD, left unchecked" : "")
                      + (variantRow.modelData.alreadyMappedTo ? "  ·  already → " + variantRow.modelData.alreadyMappedTo : "")
                    color: variantRow.modelData.realWord === true ? Color.urgent : root.fg
                    opacity: variantRow.modelData.realWord === true ? 1 : 0.6
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }

                MouseArea {
                  id: rowMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleVariant(variantRow.modelData.heard)
                }
              }
            }

            Row {
              spacing: Style.space(8)
              Button {
                iconText: ""
                text: root.chosenCount > 0 ? "Map " + root.chosenCount + " to " + root.word : "Add to vocabulary"
                fontSize: Style.font.bodySmall
                foreground: root.fg
                fontFamily: root.fontFamily
                bordered: true
                active: true
                onClicked: root.applyChosen()
              }
              Button {
                iconText: ""
                text: "Record again"
                fontSize: Style.font.bodySmall
                foreground: root.fg
                fontFamily: root.fontFamily
                bordered: true
                onClicked: root.start()
              }
            }
          }

          // ---------- Done
          Column {
            visible: root.phase === "done"
            width: parent.width
            spacing: Style.space(8)

            PanelSeparator { foreground: root.fg }

            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              textFormat: Text.PlainText
              text: root.applied
                ? (root.applied.mapped.length > 0
                    ? "Mapped " + root.applied.mapped.length + " to " + root.word + ": " + root.applied.mapped.join(", ")
                    : "No new mappings.")
                  + "\nVocabulary hint: " + root.applied.prompt
                  + (root.applied.restarted ? "\nVoxtype restarted." : "")
                  + (root.applied.failed.length > 0 ? "\nFailed: " + root.applied.failed.map(function(f) { return f.heard }).join(", ") : "")
                : ""
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            Row {
              spacing: Style.space(8)
              Button {
                iconText: ""
                text: "Re-test takes"
                fontSize: Style.font.bodySmall
                foreground: root.fg
                fontFamily: root.fontFamily
                bordered: true
                onClicked: root.runProbe()
              }
              Button {
                iconText: ""
                text: "Another word"
                fontSize: Style.font.bodySmall
                foreground: root.fg
                fontFamily: root.fontFamily
                bordered: true
                onClicked: { root.reset(); wordField.text = ""; wordField.forceActiveFocus() }
              }
            }
          }
        }
      }
    }
  }
}
