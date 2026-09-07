import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var manifest: null
  property var shell: null
  property bool opened: false
  property string dictationState: "idle"

  property string runState: "idle"
  property bool autoMode: false
  property bool sawAgent: false
  property bool sawError: false
  property bool expectedStop: false
  property bool pendingExpand: false
  property bool pendingNewSession: false
  property string agentName: ""
  property string agentLabel: ""
  property string sessionId: ""
  property string agentCwd: ""
  property string resumeLabel: "Expand"
  property var resumeArgv: []
  property bool followTail: true

  property int priorTokens: 0
  property real priorCost: 0
  property int runTokens: 0
  property real runCost: 0
  property bool sawCost: false
  property double runStartedAt: 0
  property int elapsedMs: 0
  property bool copied: false
  property bool showingHistory: false
  property bool historyLoading: false
  property int historySelectedIndex: 0

  ListModel { id: historyListModel }
  ListModel { id: filteredHistoryModel }

  property bool restored: false
  property int runPid: 0

  property int dragX: 0
  property int dragY: 0

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omagent"
  readonly property string statePath: root.stateDir + "/last.json"

  readonly property bool busy: runner.running || root.runState === "running" || root.runState === "detached"
  readonly property bool stoppable: root.busy

  readonly property bool hasSession: root.agentName !== "" && root.sessionId !== ""
  readonly property bool canResume: root.resumeArgv && root.resumeArgv.length > 0

  function formatTokens(count) {
    if (count <= 0) return ""
    if (count < 1000) return String(count)
    if (count < 1000000) return (count / 1000).toFixed(count < 10000 ? 1 : 0) + "k"
    return (count / 1000000).toFixed(1) + "M"
  }

  function formatCost(value) {
    if (!root.sawCost) return ""
    return "$" + (value < 0.01 ? value.toFixed(4) : value.toFixed(2))
  }

  function formatElapsed(ms) {
    var seconds = Math.round(ms / 1000)
    if (seconds <= 0) return ""
    if (seconds < 60) return seconds + "s"
    return Math.floor(seconds / 60) + "m " + ("0" + (seconds % 60)).slice(-2) + "s"
  }

  readonly property string meterText: {
    var parts = []
    var elapsed = root.formatElapsed(root.elapsedMs)
    if (elapsed !== "") parts.push(elapsed)
    var tokens = root.formatTokens(root.priorTokens + root.runTokens)
    if (tokens !== "") parts.push(tokens)
    var cost = root.formatCost(root.priorCost + root.runCost)
    if (cost !== "") parts.push(cost)
    return parts.join(" \u00b7 ")
  }

  function snapshot() {
    var rows = []
    var firstPrompt = ""
    for (var i = 0; i < entries.count; i++) {
      var row = entries.get(i)
      if (!firstPrompt && row.rowKind === "you") {
        firstPrompt = row.rowText
      }
      if (i >= Math.max(0, entries.count - 120)) {
        rows.push({ "rowKind": row.rowKind, "rowText": row.rowText,
                    "rowCount": row.rowCount, "rowLines": row.rowLines,
                    "rowAuto": row.rowAuto })
      }
    }
    return {
      "version": 1,
      "entries": rows,
      "title": firstPrompt || "New Chat",
      "updatedAt": Date.now(),
      "agentName": root.agentName,
      "agentLabel": root.agentLabel,
      "sessionId": root.sessionId,
      "agentCwd": root.agentCwd,
      "resumeLabel": root.resumeLabel,
      "resumeArgv": root.resumeArgv,
      "runState": root.runState,
      "runPid": root.runPid,
      "dragX": root.dragX,
      "dragY": root.dragY,
      "priorTokens": root.priorTokens + root.runTokens,
      "priorCost": root.priorCost + root.runCost,
      "sawCost": root.sawCost,
      "elapsedMs": root.elapsedMs
    }
  }

  function save() {
    if (!root.restored) return
    var snap = root.snapshot()
    var raw = JSON.stringify(snap, null, 2) + "\n"
    stateFile.setText(raw)
    if (root.sessionId !== "" && entries.count > 0) {
      sessionSaveFile.setText(raw)
    }
  }

  function restore(raw) {
    root.restored = true
    var data
    try {
      data = JSON.parse(raw)
    } catch (error) {
      return
    }
    if (!data) return
    root.dragX = Number(data.dragX || 0)
    root.dragY = Number(data.dragY || 0)
    if (!data.entries || data.entries.length === 0) return

    entries.clear()
    for (var i = 0; i < data.entries.length; i++) {
      entries.append({
        "rowKind": String(data.entries[i].rowKind || "text"),
        "rowText": String(data.entries[i].rowText || ""),
        "rowCount": Number(data.entries[i].rowCount || 1),
        "rowLines": String(data.entries[i].rowLines || ""),
        "rowExpanded": false,
        "rowAuto": !!data.entries[i].rowAuto
      })
    }
    root.agentName = String(data.agentName || "")
    root.agentLabel = String(data.agentLabel || "")
    root.sessionId = String(data.sessionId || "")
    root.agentCwd = String(data.agentCwd || "")
    root.resumeLabel = String(data.resumeLabel || "Expand")
    root.resumeArgv = data.resumeArgv || []
    root.priorTokens = Number(data.priorTokens) || 0
    root.priorCost = Number(data.priorCost) || 0
    root.sawCost = !!data.sawCost
    root.elapsedMs = Number(data.elapsedMs) || 0
    root.runPid = Number(data.runPid) || 0
    root.sawAgent = root.agentName !== ""
    root.followTail = true

    if ((String(data.runState) === "running" || String(data.runState) === "detached") && root.runPid > 0) {
      root.runState = "interrupted"
      probe.command = ["kill", "-0", String(root.runPid)]
      probe.running = true
    } else {
      root.runState = String(data.runState || "idle")
      if (root.runState === "running" || root.runState === "detached") root.runState = "interrupted"
    }
    Qt.callLater(root.scrollToEnd)
    Qt.callLater(function() { panel.keepInBounds(); root.save() })
  }

  function emphasizeKeys(text) {
    var safe = String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    return safe.replace(/(Shift\+Tab|Ctrl\+[A-Z])/g, "<b>$1</b>")
  }

  function copyText(text) {
    if (!text) return
    Quickshell.execDetached(["wl-copy", "--", String(text)])
    root.copied = true
    copyFlash.restart()
  }

  function copyLast() {
    for (var i = entries.count - 1; i >= 0; i--) {
      var row = entries.get(i)
      if (row.rowKind === "text" || row.rowKind === "error") {
        root.copyText(row.rowText)
        return
      }
    }
    root.pushRow("status", "Nothing to copy yet")
  }

  readonly property string pluginDir: manifest && manifest["__sourceDir"]
    ? String(manifest["__sourceDir"])
    : Quickshell.env("HOME") + "/.config/omarchy/plugins/io.github.ellion369.omagent"
  readonly property string routerPath: pluginDir + "/omagent-route"

  function open(payloadJson) {
    var payload = null
    try {
      payload = JSON.parse(payloadJson || "{}")
    } catch (error) {
      payload = null
    }
    if (payload && payload.auto === true) root.autoMode = true
    root.opened = true
    if (payload && payload.history === true) {
      root.openHistory()
    } else {
      root.showingHistory = false
    }
    prompt.text = ""
    Qt.callLater(function() { panel.keepInBounds() })
    Qt.callLater(function() { prompt.forceActiveFocus() })
  }

  function close() {
    root.showingHistory = false
    root.opened = false
  }

  function dismiss() {
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "io.github.ellion369.omagent")
    else root.close()
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function pushRow(kind, text, auto) {
    if (!text) return
    var last = entries.count > 0 ? entries.get(entries.count - 1) : null
    if (kind === "text" && last && last.rowKind === "text") {
      var combined = last.rowText + String(text)
      entries.setProperty(entries.count - 1, "rowText", combined)
      entries.setProperty(entries.count - 1, "rowLines", combined)
    } else if (kind === "tool" && last && last.rowKind === "tool") {
      var steps = last.rowLines.split("\n")
      steps.push(String(text))
      while (steps.length > 40) steps.shift()
      entries.set(entries.count - 1, {
        "rowKind": "tool",
        "rowText": String(text),
        "rowCount": last.rowCount + 1,
        "rowLines": steps.join("\n")
      })
    } else {
      entries.append({
        "rowKind": kind,
        "rowText": String(text),
        "rowCount": 1,
        "rowLines": String(text),
        "rowExpanded": false,
        "rowAuto": auto === true
      })
    }
    while (entries.count > 300) entries.remove(0)
    if (root.followTail) Qt.callLater(root.scrollToEnd)
    saveDebounce.restart()
  }

  function scrollToEnd() {
    list.contentY = Math.max(0, list.contentHeight - list.height)
  }

  function submit() {
    var request = prompt.text.trim()
    if (!request) return
    if (root.busy) {
      root.pushRow("status", "Still working. Ctrl+C stops it")
      return
    }
    if (!root.hasSession) entries.clear()
    root.pushRow("you", request, root.autoMode)

    root.sawAgent = false
    root.sawError = false
    root.expectedStop = false
    root.pendingExpand = false
    root.followTail = true
    root.runTokens = 0
    root.runCost = 0
    root.runStartedAt = Date.now()
    root.elapsedMs = 0
    root.runState = "running"

    var argv = [root.routerPath]
    if (root.autoMode) argv.push("--auto")
    if (root.hasSession) argv = argv.concat(["--agent", root.agentName, "--session", root.sessionId])
    argv.push("--", request)
    runner.command = argv
    runner.running = true
    prompt.text = ""
  }

  function handleLine(line) {
    var event
    try {
      event = JSON.parse(String(line))
    } catch (error) {
      root.pushRow("error", "Unreadable router output: " + String(line).substring(0, 120))
      root.sawError = true
      return
    }
    var kind = event.kind
    if (kind === "agent") {
      root.sawAgent = true
      root.agentName = String(event.name || "")
      root.agentLabel = String(event.label || "")
      root.sessionId = String(event.session || "")
      root.agentCwd = String(event.cwd || "")
      root.resumeLabel = String(event.resumeLabel || "Expand")
      root.resumeArgv = event.resume || []
      root.runPid = Number(event.pid) || 0
      root.save()
    } else if (kind === "usage") {
      root.runTokens = Number(event.tokens) || 0
      if (event.cost !== null && event.cost !== undefined) {
        root.runCost = Number(event.cost) || 0
        root.sawCost = true
      }
    } else if (kind === "done") {
      root.markElapsed()
      root.runState = event.stopped ? "stopped" : (event.ok ? "done" : "failed")
    } else if (kind === "error") {
      root.sawError = true
      root.pushRow("error", event.text)
    } else if (kind === "status" || kind === "text" || kind === "tool") {
      root.pushRow(kind, event.text)
    }
  }

  function markElapsed() {
    if (root.runStartedAt > 0) root.elapsedMs = Date.now() - root.runStartedAt
  }

  function finish(code) {
    if (root.pendingNewSession) {
      root.pendingNewSession = false
      root.newSession()
      return
    }
    root.markElapsed()
    root.priorTokens += root.runTokens
    root.priorCost += root.runCost
    root.runTokens = 0
    root.runCost = 0
    root.runPid = 0
    if (root.runState === "running") {
      if (root.expectedStop) {
        root.runState = "stopped"
        root.pushRow("status", "Stopped")
      } else {
        root.pushRow("error", "Router exited unexpectedly (code " + code + ")")
        root.sawError = true
        root.runState = "failed"
      }
    }
    var wasStopped = root.expectedStop || root.runState === "stopped"
    root.expectedStop = false

    if (root.pendingExpand) {
      root.pendingExpand = false
      root.launchResume()
      return
    }
    if (!root.opened && !wasStopped && (root.sawAgent || root.sawError))
      Quickshell.execDetached(["omarchy", "notification", "send", "Omagent", root.lastMessage()])
    root.save()
  }

  function lastMessage() {
    for (var i = entries.count - 1; i >= 0; i--) {
      var row = entries.get(i)
      if (row.rowKind === "text" || row.rowKind === "error")
        return row.rowText.substring(0, 140)
    }
    return root.runState === "failed" ? "Request failed" : "Request finished"
  }

  onRunStateChanged: if (root.followTail) Qt.callLater(root.scrollToEnd)

  function stopRun() {
    if (root.runState === "detached") {
      if (root.runPid > 0)
        Quickshell.execDetached(["sh", "-c", "kill -TERM -- -" + root.runPid + " 2>/dev/null"])
      root.pushRow("status", "Stopped")
      root.runState = "stopped"
      root.runPid = 0
      root.save()
      return
    }
    if (root.runState !== "running") return
    root.expectedStop = true
    runner.running = false
  }

  function launchResume() {
    if (!root.canResume) return
    var home = Quickshell.env("HOME")
    var cwd = root.agentCwd || home
    if (root.resumeLabel === "Expand") {
      var appId = "org.omarchy.omagent." + (root.sessionId || "session").replace(/[^A-Za-z0-9_.-]/g, "_")
      Quickshell.execDetached({
        command: ["omarchy-launch-or-focus-tui", "--app-id=" + appId].concat(
          root.resumeArgv.map(function(arg) {
            return "'" + String(arg).replace(/'/g, "'\\''") + "'"
          })),
        workingDirectory: cwd
      })
    } else {
      Quickshell.execDetached({ command: root.resumeArgv.slice(), workingDirectory: cwd })
    }
  }

  function expand() {
    if (!root.canResume) {
      root.pushRow("status", root.runState === "running"
        ? "Session not ready yet"
        : "Nothing to expand yet")
      return
    }
    root.dismiss()
    if (root.runState === "running") {
      root.pendingExpand = true
      root.stopRun()
    } else {
      root.launchResume()
    }
  }

  function newSession() {
    if (runner.running) {
      root.pendingNewSession = true
      root.pendingExpand = false
      root.stopRun()
      return
    }
    root.stopRun()
    if (root.sessionId !== "" && entries.count > 0) {
      sessionSaveFile.setText(JSON.stringify(root.snapshot(), null, 2) + "\n")
    }
    entries.clear()
    root.agentName = ""
    root.agentLabel = ""
    root.sessionId = ""
    root.agentCwd = ""
    root.resumeLabel = "Expand"
    root.resumeArgv = []
    root.sawAgent = false
    root.sawError = false
    root.runState = "idle"
    root.autoMode = false
    root.followTail = true
    root.priorTokens = 0
    root.priorCost = 0
    root.runTokens = 0
    root.runCost = 0
    root.sawCost = false
    root.runStartedAt = 0
    root.elapsedMs = 0
    root.runPid = 0
    root.showingHistory = false
    root.save()
    prompt.text = ""
    prompt.forceActiveFocus()
  }

  function toggleHistory() {
    if (root.busy) {
      root.pushRow("status", "Still working. Ctrl+C stops it")
      return
    }
    if (root.showingHistory) {
      root.showingHistory = false
      prompt.text = ""
      prompt.forceActiveFocus()
      return
    }
    root.openHistory()
  }

  function openHistory() {
    console.log("Omagent: openHistory() called with routerPath: " + root.routerPath)
    if (root.sessionId !== "" && entries.count > 0) {
      root.save()
    }
    root.showingHistory = true
    root.historyLoading = true
    root.historySelectedIndex = 0
    historyListModel.clear()
    filteredHistoryModel.clear()
    prompt.text = ""
    prompt.forceActiveFocus()
    historyLister.command = [root.routerPath, "--list-sessions"]
    historyLister.running = false
    historyLister.running = true
  }

  function applyHistoryFilter() {
    filteredHistoryModel.clear()
    var query = prompt.text.trim().toLowerCase()
    for (var i = 0; i < historyListModel.count; i++) {
      var item = historyListModel.get(i)
      var t = String(item.title || "").toLowerCase()
      var p = String(item.preview || "").toLowerCase()
      var a = String(item.agentLabel || "").toLowerCase()
      if (!query || t.indexOf(query) !== -1 || p.indexOf(query) !== -1 || a.indexOf(query) !== -1) {
        filteredHistoryModel.append({
          "id": item.id,
          "title": item.title,
          "agentLabel": item.agentLabel,
          "agentName": item.agentName,
          "timeAgo": item.timeAgo,
          "preview": item.preview,
          "messageCount": item.messageCount
        })
      }
    }
    if (root.historySelectedIndex >= filteredHistoryModel.count) {
      root.historySelectedIndex = Math.max(0, filteredHistoryModel.count - 1)
    }
  }

  function populateHistory(raw) {
    console.log("Omagent: populateHistory() raw text length: " + (raw ? raw.length : 0))
    root.historyLoading = false
    historyListModel.clear()
    var list = []
    try {
      list = JSON.parse(String(raw || ""))
    } catch (e) {
      console.warn("Omagent: failed to parse history JSON:", e, "raw:", raw)
      return
    }
    if (!list || !Array.isArray(list)) {
      console.warn("Omagent: history list is not an array:", list)
      return
    }
    console.log("Omagent: successfully parsed " + list.length + " history chats")
    for (var i = 0; i < list.length; i++) {
      historyListModel.append(list[i])
    }
    root.applyHistoryFilter()
  }

  function loadSession(id) {
    if (!id) return
    if (root.sessionId !== "" && root.sessionId !== id && entries.count > 0) {
      root.save()
    }
    root.historyLoading = true
    sessionFetcher.command = [root.routerPath, "--get-session", id]
    sessionFetcher.running = false
    sessionFetcher.running = true
  }

  function finishLoadSession(raw) {
    root.historyLoading = false
    root.restore(raw)
    root.showingHistory = false
    prompt.text = ""
    prompt.forceActiveFocus()
  }

  function deleteSession(id) {
    if (!id) return
    Quickshell.execDetached([root.routerPath, "--delete-session", id])
    for (var i = 0; i < historyListModel.count; i++) {
      if (historyListModel.get(i).id === id) {
        historyListModel.remove(i)
        break
      }
    }
    root.applyHistoryFilter()
    if (root.sessionId === id) {
      root.newSession()
      root.showingHistory = true
    }
  }

  function clearAllHistory() {
    Quickshell.execDetached([root.routerPath, "--clear-history"])
    historyListModel.clear()
    filteredHistoryModel.clear()
    root.newSession()
    root.showingHistory = false
  }

  function toggleAuto() {
    root.autoMode = !root.autoMode
    prompt.forceActiveFocus()
  }

  function toggleDictation() {
    prompt.forceActiveFocus()
    Quickshell.execDetached(["voxtype", "record", "toggle"])
  }

  function updateDictation(raw) {
    var text = String(raw || "")
    var match = text.match(/\"(?:alt|class)\"\s*:\s*\"([^\"]+)\"/)
    root.dictationState = match ? match[1] : "idle"
  }

  ListModel { id: entries }

  Timer {
    interval: 500
    repeat: true
    running: root.runState === "running"
    onTriggered: root.markElapsed()
  }

  Timer {
    id: copyFlash
    interval: 1200
    onTriggered: root.copied = false
  }

  Timer {
    id: saveDebounce
    interval: 800
    onTriggered: root.save()
  }

  Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.stateDir + "/sessions"])

  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: root.restore(text())
    onLoadFailed: root.restored = true
  }

  FileView {
    id: sessionSaveFile
    path: root.sessionId !== "" ? (root.stateDir + "/sessions/" + root.sessionId + ".json") : ""
    atomicWrites: true
    printErrors: false
  }

  Process {
    id: historyLister
    command: [root.routerPath, "--list-sessions"]
    stdout: StdioCollector {
      id: historyCollector
      waitForEnd: true
      onStreamFinished: root.populateHistory(historyCollector.text)
    }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        if (historyListModel.count === 0) {
          root.populateHistory(historyCollector.text)
        }
      } else {
        root.historyLoading = false
        console.warn("Omagent: historyLister exited with code", exitCode)
      }
    }
  }

  Process {
    id: sessionFetcher
    stdout: StdioCollector {
      id: sessionCollector
      waitForEnd: true
      onStreamFinished: root.finishLoadSession(sessionCollector.text)
    }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        if (root.historyLoading) {
          root.finishLoadSession(sessionCollector.text)
        }
      } else {
        root.historyLoading = false
        console.warn("Omagent: sessionFetcher exited with code", exitCode)
      }
    }
  }

  Process {
    id: probe
    onExited: function(exitCode) {
      root.runState = exitCode === 0 ? "detached" : "interrupted"
      if (exitCode !== 0) root.runPid = 0
      root.save()
    }
  }

  Process {
    id: runner
    stdout: SplitParser {
      onRead: function(line) { root.handleLine(line) }
    }
    stderr: SplitParser {
      onRead: function(line) {
        if (String(line).trim() === "") return
        root.sawError = true
        root.pushRow("error", line)
      }
    }
    onExited: function(exitCode) { root.finish(exitCode) }
  }

  Process {
    command: ["omarchy-voxtype-status"]
    running: true
    stdout: SplitParser {
      onRead: function(data) { root.updateDictation(data) }
    }
  }

  PanelWindow {
    id: panel

    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omarchy-omagent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened
      ? WlrKeyboardFocus.Exclusive
      : WlrKeyboardFocus.None

    readonly property int gap: Style.space(12)
    readonly property int surfaceWidth: Math.min(Style.space(520), panel.width - Style.space(32))
    readonly property int pillTop: (entries.count > 0 || root.showingHistory)
      ? Math.round(panel.height * 0.13)
      : Math.round(panel.height * 0.28)
    readonly property int cardTop: pillTop + pill.height + gap
    readonly property int cardMax: Math.max(
      Style.space(80),
      Math.min(Math.round(panel.height * 0.68),
               panel.height - cardTop - panel.clampY(root.dragY) - Style.space(24)))

    function clampX(value) {
      var slack = Math.round((panel.width - panel.surfaceWidth) / 2) - Style.space(8)
      return Math.max(-slack, Math.min(slack, value))
    }

    function clampY(value) {
      return Math.max(Style.space(8) - panel.pillTop,
                      Math.min(panel.height - Style.space(8) - panel.pillTop - pill.height,
                               value))
    }

    function keepInBounds() {
      if (!root.opened) return
      if (panel.width < 200 || panel.height < 200) return
      root.dragX = panel.clampX(root.dragX)
      root.dragY = panel.clampY(root.dragY)
    }

    onPillTopChanged: panel.keepInBounds()
    onWidthChanged: panel.keepInBounds()
    onHeightChanged: panel.keepInBounds()

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(Color.menu.scrim.r, Color.menu.scrim.g, Color.menu.scrim.b, 1)
      opacity: root.opened ? 0.5 : 0
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: pill

      width: panel.surfaceWidth
      height: Style.space(76)
      x: Math.round((panel.width - width) / 2) + panel.clampX(root.dragX)
      y: panel.pillTop + panel.clampY(root.dragY)
      radius: height / 2
      color: Qt.rgba(Color.menu.background.r,
                     Color.menu.background.g,
                     Color.menu.background.b, 0.86)

      readonly property var borderBase: Border.surfaceSpec(
        "menu",
        "border",
        Color.menu.border,
        Math.max(1, Style.space(1)))
      readonly property color borderTint: Border.color(pill.borderBase)

      borderSpec: (prompt.activeFocus || pill.borderBase.gradient)
        ? pill.borderBase
        : ({
            "color": Qt.rgba(pill.borderTint.r, pill.borderTint.g,
                             pill.borderTint.b, pill.borderTint.a * 0.4),
            "widths": pill.borderBase.widths,
            "gradient": pill.borderBase.gradient
          })
      padding: Style.space(4)
      scale: root.opened ? 1 : 0.96
      opacity: root.opened ? 1 : 0

      Behavior on y {
        enabled: !mover.active
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
      }

      Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
      }

      Behavior on opacity {
        NumberAnimation { duration: 100 }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: prompt.forceActiveFocus()
      }

      DragHandler {
        id: mover

        target: null
        cursorShape: Qt.SizeAllCursor

        property int fromX: 0
        property int fromY: 0

        onActiveChanged: {
          if (mover.active) {
            mover.fromX = root.dragX
            mover.fromY = root.dragY
          } else {
            root.save()
          }
        }

        onActiveTranslationChanged: {
          if (!mover.active) return
          root.dragX = panel.clampX(mover.fromX + Math.round(mover.activeTranslation.x))
          root.dragY = panel.clampY(mover.fromY + Math.round(mover.activeTranslation.y))
        }
      }

      Row {
        anchors.fill: parent
        anchors.leftMargin: Style.space(20)
        anchors.rightMargin: Style.space(10)
        spacing: Style.space(14)

        Item {
          width: Style.space(54)
          height: parent.height

          Image {
            id: logoMask
            anchors.centerIn: parent
            width: Style.space(42)
            height: width
            source: "omarchy-logo.svg"
            fillMode: Image.PreserveAspectFit
            smooth: false
            visible: false
            layer.enabled: true
          }

          MultiEffect {
            anchors.fill: logoMask
            source: logoMask
            colorization: 1.0
            colorizationColor: Color.menu.text
            opacity: 0.78
          }
        }

        Item {
          width: parent.width - Style.space(54) - Style.space(42) * 2 - parent.spacing * 3
            - (autoBadge.visible ? autoBadge.width + parent.spacing : 0)
          height: parent.height

          TextInput {
            id: prompt
            anchors.fill: parent
            color: Color.menu.text
            selectionColor: Color.menu.selectedBackground
            selectedTextColor: Color.menu.selectedText
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.heading
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            clip: true
            maximumLength: 2000

            cursorDelegate: Rectangle {
              width: Math.max(1, Style.space(1))
              color: Color.accent
            }

            onTextChanged: {
              if (root.showingHistory) {
                root.applyHistoryFilter()
              }
            }

            Keys.priority: Keys.BeforeItem

            Keys.onPressed: function(event) {
              if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_H) {
                  root.toggleHistory()
                  event.accepted = true
                  return
                } else if (event.key === Qt.Key_E) {
                  root.expand()
                  event.accepted = true
                  return
                } else if (event.key === Qt.Key_C && prompt.selectedText.length === 0) {
                  root.stopRun()
                  event.accepted = true
                  return
                } else if (event.key === Qt.Key_N) {
                  root.newSession()
                  event.accepted = true
                  return
                } else if (event.key === Qt.Key_Y) {
                  root.copyLast()
                  event.accepted = true
                  return
                }
              }

              if (root.showingHistory) {
                if (event.key === Qt.Key_Down) {
                  root.historySelectedIndex = Math.min(filteredHistoryModel.count - 1, root.historySelectedIndex + 1)
                  event.accepted = true
                  return
                } else if (event.key === Qt.Key_Up) {
                  root.historySelectedIndex = Math.max(0, root.historySelectedIndex - 1)
                  event.accepted = true
                  return
                } else if (event.key === Qt.Key_Delete) {
                  if (root.historySelectedIndex >= 0 && root.historySelectedIndex < filteredHistoryModel.count) {
                    root.deleteSession(filteredHistoryModel.get(root.historySelectedIndex).id)
                  }
                  event.accepted = true
                  return
                }
              }

              if (event.key === Qt.Key_Backtab
                  || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                root.toggleAuto()
                event.accepted = true
                return
              }
              if (event.key === Qt.Key_PageUp) {
                root.followTail = false
                list.contentY = Math.max(0, list.contentY - list.height * 0.8)
                event.accepted = true
              } else if (event.key === Qt.Key_PageDown) {
                list.contentY = Math.min(
                  Math.max(0, list.contentHeight - list.height),
                  list.contentY + list.height * 0.8)
                root.followTail = list.atYEnd
                event.accepted = true
              }
            }

            Keys.onEscapePressed: function(event) {
              if (root.showingHistory) {
                root.showingHistory = false
                prompt.text = ""
                event.accepted = true
                return
              }
              root.dismiss()
              event.accepted = true
            }

            Keys.onReturnPressed: function(event) {
              if (root.showingHistory) {
                if (filteredHistoryModel.count > 0 && root.historySelectedIndex >= 0 && root.historySelectedIndex < filteredHistoryModel.count) {
                  root.loadSession(filteredHistoryModel.get(root.historySelectedIndex).id)
                  event.accepted = true
                  return
                } else if (prompt.text.trim().length > 0) {
                  root.showingHistory = false
                  root.submit()
                  event.accepted = true
                  return
                }
              }
              root.submit()
              event.accepted = true
            }

            Keys.onEnterPressed: function(event) {
              if (root.showingHistory) {
                if (filteredHistoryModel.count > 0 && root.historySelectedIndex >= 0 && root.historySelectedIndex < filteredHistoryModel.count) {
                  root.loadSession(filteredHistoryModel.get(root.historySelectedIndex).id)
                  event.accepted = true
                  return
                } else if (prompt.text.trim().length > 0) {
                  root.showingHistory = false
                  root.submit()
                  event.accepted = true
                  return
                }
              }
              root.submit()
              event.accepted = true
            }
          }

          Text {
            anchors.fill: parent
            visible: prompt.text.length === 0
            text: root.dictationState === "recording"
              ? "Listening…"
              : (root.dictationState === "transcribing"
                ? "Transcribing…"
                : (root.showingHistory
                  ? "Search past chats…"
                  : (root.hasSession ? "Follow up…" : "Personal Assistance Active")))
            color: Color.menu.text
            opacity: root.dictationState === "idle" ? 0.44 : 0.72
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.heading
            verticalAlignment: Text.AlignVCenter
          }
        }

        Item {
          id: autoBadge

          visible: root.autoMode
          width: autoLabel.implicitWidth + Style.space(16)
          height: parent.height

          Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: autoLabel.implicitHeight + Style.space(8)
            radius: height / 2
            color: Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b,
                           badgeArea.containsMouse ? 0.3 : 0.18)

            Text {
              id: autoLabel

              anchors.centerIn: parent
              text: "AUTO"
              color: Color.urgent
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
            }

            MouseArea {
              id: badgeArea

              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleAuto()
            }
          }
        }

        Item {
          width: Style.space(42)
          height: parent.height

          Rectangle {
            anchors.centerIn: parent
            width: Style.space(38)
            height: width
            radius: width / 2
            color: root.showingHistory
              ? Color.menu.selectedBackground
              : (historyBtnArea.containsMouse ? Color.menu.selectedBackground : "transparent")

            Text {
              anchors.centerIn: parent
              text: "󰋚"
              color: root.showingHistory ? Color.accent : Color.menu.text
              opacity: root.showingHistory ? 1.0 : 0.62
              font.family: Style.font.family
              font.pixelSize: Style.font.iconLarge
            }

            MouseArea {
              id: historyBtnArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleHistory()
            }
          }
        }

        Item {
          width: Style.space(42)
          height: parent.height

          Rectangle {
            anchors.centerIn: parent
            width: Style.space(38)
            height: width
            radius: width / 2
            color: micArea.containsMouse
              ? Color.menu.selectedBackground
              : "transparent"

            Text {
              anchors.centerIn: parent
              text: root.dictationState === "transcribing" ? "󰔟" : "󰍬"
              color: root.dictationState === "idle" ? Color.menu.text : Color.bar.active
              opacity: root.dictationState === "idle" ? 0.62 : 1
              font.family: Style.font.family
              font.pixelSize: Style.font.iconLarge
            }

            MouseArea {
              id: micArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleDictation()
            }
          }
        }
      }
    }

    BorderSurface {
      id: card

      visible: entries.count > 0 || root.showingHistory
      width: panel.surfaceWidth
      x: Math.round((panel.width - width) / 2) + panel.clampX(root.dragX)
      y: panel.cardTop + panel.clampY(root.dragY)
      height: root.showingHistory
        ? Math.min(Style.space(380), panel.cardMax)
        : Math.min(
            card.contentTopInset + card.contentBottomInset
              + header.height + Style.space(12)
              + rows.height + Style.space(12)
              + footer.height,
            panel.cardMax)
      radius: Style.space(20)
      color: Qt.rgba(Color.menu.background.r,
                     Color.menu.background.g,
                     Color.menu.background.b, 0.86)
      borderSpec: Border.none()
      padding: Style.space(14)
      opacity: root.opened ? 1 : 0

      Behavior on height {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
      }

      Behavior on opacity {
        NumberAnimation { duration: 100 }
      }

      MouseArea { anchors.fill: parent; onClicked: prompt.forceActiveFocus() }

      Item {
        anchors.fill: parent
        anchors.margins: card.contentTopInset

        Item {
          id: chatView
          anchors.fill: parent
          visible: !root.showingHistory

          Item {
            id: header
          width: parent.width
          height: Style.space(20)

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              text: root.agentLabel !== "" ? root.agentLabel : "Omagent"
              color: Color.menu.text
              opacity: 0.86
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              visible: stateLabel.text !== ""
              text: "\u00b7"
              color: Color.muted
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              id: stateLabel

              text: root.runState === "running" ? "Working…"
                : (root.runState === "detached" ? "Still running"
                : (root.runState === "interrupted" ? "Ended while away"
                : (root.runState === "failed" ? "Failed"
                : (root.runState === "stopped" ? "Stopped"
                : (root.runState === "done" ? "Done" : "")))))
              color: root.runState === "failed" ? Color.urgent : Color.muted
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.bodySmall
            }
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.meterText
            visible: text !== ""
            color: Color.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.caption
          }
        }

        Flickable {
          id: list

          anchors.top: header.bottom
          anchors.topMargin: Style.space(12)
          anchors.bottom: footer.top
          anchors.bottomMargin: Style.space(12)
          width: parent.width
          clip: true
          contentWidth: width
          contentHeight: rows.height
          boundsBehavior: Flickable.StopAtBounds

          onMovementEnded: root.followTail = list.atYEnd
          onContentHeightChanged: if (root.followTail) root.scrollToEnd()
          onHeightChanged: if (root.followTail) root.scrollToEnd()

          Column {
            id: rows

            width: list.width
            spacing: Style.space(8)

            Repeater {
              model: entries

              delegate: Item {
                id: row

                required property string rowKind
                required property string rowText
                required property int rowCount
                required property string rowLines
                required property bool rowExpanded
                required property bool rowAuto
                required property int index

                readonly property bool isYou: row.rowKind === "you"
                readonly property bool isError: row.rowKind === "error"
                readonly property bool isNote: row.rowKind === "tool" || row.rowKind === "status"
                readonly property bool boxed: row.isYou
                readonly property bool copyable: !row.isNote
                readonly property bool expandable: row.isNote
                  && (row.rowCount > 1 || row.rowExpanded || label.truncated)
                readonly property int padX: row.boxed ? Style.space(10) : 0
                readonly property int padY: row.boxed ? Style.space(7) : 0
                readonly property int leadIn: (row.isYou && row.index > 0) ? Style.space(14) : 0
                readonly property int tagSpace: (row.isYou && row.rowAuto)
                  ? autoTag.implicitWidth + Style.space(8) : 0
                readonly property int opticalShift: row.isYou
                  ? Math.round((metrics.descent - (metrics.ascent - metrics.capHeight)) / 2)
                  : 0

                readonly property bool isProse: !row.isYou && !row.isNote
                readonly property real leading: 1.35
                readonly property int trailing: row.isProse
                  ? Math.round(metrics.height * (row.leading - 1)) : 0

                width: rows.width
                height: row.leadIn + label.contentHeight - row.trailing + row.padY * 2

                readonly property int chipWidth:
                  Math.min(label.contentWidth + row.padX * 2 + row.tagSpace, rows.width)

                FontMetrics {
                  id: metrics
                  font: label.font
                }

                Rectangle {
                  visible: row.isYou
                  y: row.leadIn
                  width: row.chipWidth
                  height: parent.height - row.leadIn
                  radius: Style.cornerRadius
                  color: Color.menu.selectedBackground
                }

                Rectangle {
                  visible: row.isError
                  x: -Style.space(9)
                  y: row.leadIn + Style.space(1)
                  width: Math.max(2, Style.space(2))
                  height: parent.height - row.leadIn - Style.space(2)
                  radius: width / 2
                  color: Color.urgent
                }

                Rectangle {
                  y: row.leadIn + (row.boxed ? 0 : -Style.space(2))
                  x: row.boxed ? 0 : -Style.space(5)
                  width: row.isYou ? row.chipWidth : rows.width + Style.space(10)
                  height: parent.height - row.leadIn + (row.boxed ? 0 : Style.space(4))
                  radius: Style.cornerRadius
                  color: Color.menu.text
                  opacity: hover.hovered && (row.copyable || row.expandable) ? 0.06 : 0

                  Behavior on opacity {
                    NumberAnimation { duration: 100 }
                  }
                }

                Text {
                  id: label

                  x: row.padX
                  y: row.leadIn + row.padY + row.opticalShift
                  width: rows.width - row.padX * 2 - row.tagSpace
                  wrapMode: (row.isNote && !row.rowExpanded) ? Text.NoWrap : Text.WordWrap
                  elide: (row.isNote && !row.rowExpanded) ? Text.ElideRight : Text.ElideNone
                  textFormat: {
                    if (row.isError || row.rowKind === "status") return Text.StyledText
                    if (row.isProse) return Text.MarkdownText
                    return Text.PlainText
                  }
                  lineHeightMode: Text.ProportionalHeight
                  lineHeight: row.isProse ? row.leading : 1.0
                  linkColor: Color.accent
                  onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                  font.family: Style.font.menuFamily
                  font.pixelSize: row.isNote ? Style.font.caption : Style.font.body
                  color: row.isNote ? Color.muted : Color.menu.text
                  opacity: row.isNote ? 1 : 0.95
                  text: {
                    if (row.rowExpanded) {
                      var expanded = "\u2304 " + row.rowLines.split("\n").join("\n\u00b7 ")
                      return row.rowKind === "status" ? root.emphasizeKeys(expanded) : expanded
                    }
                    if (row.rowCount > 1)
                      return "\u203a " + row.rowCount + " steps \u00b7 " + row.rowText
                    if (row.isError) return root.emphasizeKeys(row.rowText)
                    if (row.rowKind === "status") return "\u00b7 " + root.emphasizeKeys(row.rowText)
                    return (row.isNote ? "\u00b7 " : "") + row.rowText
                  }
                }

                Text {
                  id: autoTag

                  visible: row.isYou && row.rowAuto
                  x: row.chipWidth - row.padX - width
                  y: row.leadIn + row.padY + Math.round((metrics.height - height) / 2)
                  text: "auto"
                  color: Color.urgent
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.caption
                }

                HoverHandler {
                  id: hover
                  cursorShape: (row.copyable || row.expandable)
                    ? Qt.PointingHandCursor : Qt.ArrowCursor
                }

                TapHandler {
                  enabled: row.copyable || row.expandable
                  onTapped: {
                    if (row.expandable)
                      entries.set(row.index, { "rowExpanded": !row.rowExpanded })
                    else
                      root.copyText(row.rowText)
                  }
                }
              }
            }

            Item {
              id: waiting

              width: rows.width
              height: visible ? Style.space(14) : 0
              visible: root.busy

              Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(5)

                Repeater {
                  model: 3

                  delegate: Rectangle {
                    required property int index

                    width: Style.space(5)
                    height: width
                    radius: width / 2
                    color: Color.menu.text
                    opacity: 0.25

                    SequentialAnimation on opacity {
                      running: waiting.visible
                      loops: Animation.Infinite
                      PauseAnimation { duration: index * 160 }
                      NumberAnimation { to: 0.85; duration: 300; easing.type: Easing.OutCubic }
                      NumberAnimation { to: 0.25; duration: 300; easing.type: Easing.InCubic }
                      PauseAnimation { duration: 480 - index * 160 }
                    }
                  }
                }
              }
            }
          }
        }

        Rectangle {
          anchors { left: list.left; right: list.right; top: list.top }
          height: Style.space(16)
          opacity: list.contentY > 1 ? 1 : 0

          gradient: Gradient {
            GradientStop { position: 0; color: card.color }
            GradientStop {
              position: 1
              color: Qt.rgba(Color.menu.background.r, Color.menu.background.g,
                             Color.menu.background.b, 0)
            }
          }

          Behavior on opacity {
            NumberAnimation { duration: 120 }
          }
        }

        Rectangle {
          anchors { left: list.left; right: list.right; bottom: list.bottom }
          height: Style.space(16)
          opacity: list.atYEnd ? 0 : 1

          gradient: Gradient {
            GradientStop {
              position: 0
              color: Qt.rgba(Color.menu.background.r, Color.menu.background.g,
                             Color.menu.background.b, 0)
            }
            GradientStop { position: 1; color: card.color }
          }

          Behavior on opacity {
            NumberAnimation { duration: 120 }
          }
        }

        Rectangle {
          readonly property real scrollable: list.contentHeight - list.height

          anchors.right: list.right
          visible: scrollable > 1
          width: Math.max(2, Style.space(2))
          radius: width / 2
          height: Math.max(Style.space(18), list.height * (list.height / list.contentHeight))
          y: list.y + (list.height - height)
            * Math.min(1, Math.max(0, list.contentY / Math.max(1, scrollable)))
          color: Color.menu.text
          opacity: list.moving ? 0.4 : 0.16

          Behavior on opacity {
            NumberAnimation { duration: 200 }
          }
        }

        Item {
          id: footer

          anchors.bottom: parent.bottom
          width: parent.width
          height: Style.space(24)

          Row {
            anchors.left: parent.left
            anchors.leftMargin: -Style.space(7)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Button {
              text: root.resumeLabel + " ^E"
              tooltipText: "Ctrl+E \u2014 open this session in the terminal"
              visible: root.canResume
              fontSize: Style.font.caption
              foreground: Color.muted
              horizontalPadding: Style.space(7)
              verticalPadding: Style.space(3)
              onClicked: root.expand()
            }

            Button {
              text: "Stop ^C"
              tooltipText: "Ctrl+C \u2014 stop the running agent"
              visible: root.stoppable
              fontSize: Style.font.caption
              foreground: Color.muted
              horizontalPadding: Style.space(7)
              verticalPadding: Style.space(3)
              onClicked: root.stopRun()
            }

            Button {
              text: "Copy ^Y"
              tooltipText: "Ctrl+Y \u2014 copy the last answer, or click any row"
              visible: entries.count > 0
              fontSize: Style.font.caption
              foreground: Color.muted
              horizontalPadding: Style.space(7)
              verticalPadding: Style.space(3)
              onClicked: root.copyLast()
            }

            Button {
              text: "New ^N"
              tooltipText: "Ctrl+N \u2014 start a fresh session"
              visible: entries.count > 0
              fontSize: Style.font.caption
              foreground: Color.muted
              horizontalPadding: Style.space(7)
              verticalPadding: Style.space(3)
              onClicked: root.newSession()
            }

            Button {
              text: "History ^H"
              tooltipText: "Ctrl+H \u2014 browse past chat sessions"
              fontSize: Style.font.caption
              foreground: Color.muted
              horizontalPadding: Style.space(7)
              verticalPadding: Style.space(3)
              onClicked: root.toggleHistory()
            }
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Copied"
            visible: root.copied
            color: Color.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      Item {
        id: historyView
        anchors.fill: parent
        visible: root.showingHistory

        Item {
          id: historyHeader
          width: parent.width
          height: Style.space(20)

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              text: "󰋚"
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              text: "Chat History"
              color: Color.menu.text
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.bodySmall
              font.weight: Font.DemiBold
            }

            Text {
              visible: filteredHistoryModel.count > 0
              text: "\u00b7 " + filteredHistoryModel.count + (filteredHistoryModel.count === 1 ? " chat" : " chats")
              color: Color.muted
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.bodySmall
            }
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Esc to close"
            color: Color.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.caption
          }
        }

        ListView {
          id: historyList
          anchors.top: historyHeader.bottom
          anchors.topMargin: Style.space(10)
          anchors.bottom: historyFooter.top
          anchors.bottomMargin: Style.space(10)
          width: parent.width
          clip: true
          model: filteredHistoryModel
          spacing: Style.space(6)
          boundsBehavior: Flickable.StopAtBounds

          currentIndex: root.historySelectedIndex
          onCurrentIndexChanged: {
            if (currentIndex >= 0) root.historySelectedIndex = currentIndex
          }

          Item {
            anchors.fill: parent
            visible: !root.historyLoading && filteredHistoryModel.count === 0

            Column {
              anchors.centerIn: parent
              spacing: Style.space(8)

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰋚"
                color: Color.muted
                opacity: 0.45
                font.family: Style.font.family
                font.pixelSize: Style.space(32)
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: prompt.text.trim().length > 0 ? "No matching chats" : "No saved chats yet"
                color: Color.menu.text
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.body
                font.weight: Font.Medium
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: prompt.text.trim().length > 0
                  ? "Try a different search term"
                  : "Conversations are saved automatically"
                color: Color.muted
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.caption
              }
            }
          }

          Item {
            anchors.fill: parent
            visible: root.historyLoading

            Text {
              anchors.centerIn: parent
              text: "Loading history…"
              color: Color.muted
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.bodySmall
            }
          }

          delegate: Item {
            id: historyRow
            width: historyList.width
            height: Style.space(58)

            required property string id
            required property string title
            required property string agentLabel
            required property string agentName
            required property string timeAgo
            required property string preview
            required property int messageCount
            required property int index

            readonly property bool isCurrent: historyRow.id === root.sessionId
            readonly property bool isSelected: historyRow.index === root.historySelectedIndex

            Rectangle {
              id: bg
              anchors.fill: parent
              radius: Style.cornerRadius
              color: (historyRow.isSelected || rowHover.hovered)
                ? Color.menu.selectedBackground
                : (historyRow.isCurrent ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.08) : "transparent")
              opacity: (historyRow.isSelected || rowHover.hovered) ? 0.9 : 1.0

              border.width: historyRow.isCurrent ? 1 : 0
              border.color: historyRow.isCurrent ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.4) : "transparent"

              Behavior on color {
                ColorAnimation { duration: 80 }
              }
            }

            Item {
              anchors.fill: parent
              anchors.leftMargin: Style.space(12)
              anchors.rightMargin: Style.space(10)
              anchors.topMargin: Style.space(8)
              anchors.bottomMargin: Style.space(8)

              Row {
                id: topRow
                anchors.left: parent.left
                anchors.right: delBtn.visible ? delBtn.left : parent.right
                anchors.rightMargin: Style.space(8)
                anchors.top: parent.top
                spacing: Style.space(6)

                Rectangle {
                  visible: historyRow.isCurrent
                  width: Style.space(6)
                  height: Style.space(6)
                  radius: width / 2
                  color: Color.accent
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  width: parent.width - (historyRow.isCurrent ? Style.space(12) : 0) - timeText.implicitWidth - Style.space(8)
                  text: historyRow.title || "Untitled Chat"
                  color: Color.menu.text
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.bodySmall
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                  maximumLineCount: 1
                }

                Text {
                  id: timeText
                  text: historyRow.timeAgo || ""
                  color: Color.muted
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.caption
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              Row {
                anchors.left: parent.left
                anchors.right: delBtn.visible ? delBtn.left : parent.right
                anchors.rightMargin: Style.space(8)
                anchors.bottom: parent.bottom
                spacing: Style.space(6)

                Rectangle {
                  width: agentTag.implicitWidth + Style.space(8)
                  height: agentTag.implicitHeight + Style.space(2)
                  radius: Style.space(4)
                  color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.14)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    id: agentTag
                    anchors.centerIn: parent
                    text: historyRow.agentLabel || "Jarvis"
                    color: Color.accent
                    font.family: Style.font.menuFamily
                    font.pixelSize: Style.font.caption
                    font.weight: Font.Medium
                  }
                }

                Text {
                  width: parent.width - (agentTag.implicitWidth + Style.space(14))
                  text: historyRow.preview || ""
                  color: Color.muted
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  maximumLineCount: 1
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              Rectangle {
                id: delBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(24)
                height: Style.space(24)
                radius: width / 2
                color: delHover.hovered ? Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.2) : "transparent"
                visible: rowHover.hovered || historyRow.isSelected

                Text {
                  anchors.centerIn: parent
                  text: "󰆴"
                  color: delHover.hovered ? Color.urgent : Color.muted
                  font.family: Style.font.family
                  font.pixelSize: Style.font.bodySmall
                }

                HoverHandler {
                  id: delHover
                  cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                  onTapped: root.deleteSession(historyRow.id)
                }
              }
            }

            HoverHandler {
              id: rowHover
              cursorShape: Qt.PointingHandCursor
              onHoveredChanged: {
                if (rowHover.hovered) root.historySelectedIndex = historyRow.index
              }
            }

            TapHandler {
              onTapped: root.loadSession(historyRow.id)
            }
          }
        }

        Item {
          id: historyFooter
          anchors.bottom: parent.bottom
          width: parent.width
          height: Style.space(24)

          Row {
            anchors.left: parent.left
            anchors.leftMargin: -Style.space(7)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Button {
              text: "Back Esc"
              tooltipText: "Esc \u2014 return to current chat"
              fontSize: Style.font.caption
              foreground: Color.muted
              horizontalPadding: Style.space(7)
              verticalPadding: Style.space(3)
              onClicked: root.toggleHistory()
            }

            Button {
              text: "Clear All"
              tooltipText: "Delete all chat history"
              visible: filteredHistoryModel.count > 0
              fontSize: Style.font.caption
              foreground: Color.urgent
              horizontalPadding: Style.space(7)
              verticalPadding: Style.space(3)
              onClicked: root.clearAllHistory()
            }
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Enter to open \u00b7 Del to remove"
            color: Color.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }

  }
}
}

