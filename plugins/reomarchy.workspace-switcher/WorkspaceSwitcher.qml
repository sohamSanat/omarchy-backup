import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool revealed: false
  property bool quickSwitchPending: false
  property int selectedIndex: 0
  property int selectedWindowIndex: 0
  property var workspaceRows: []
  property var recentWorkspaceIds: []
  property var retainedPreviewIds: []

  readonly property int maxWorkspaceCount: 10
  readonly property int maxWindowsPerWorkspace: 24
  readonly property int maxRetainedPreviewCount: maxWorkspaceCount

  // Search and HUD State
  property string searchQuery: ""
  property string hudActionText: "SUPER + TAB"
  property bool cursorBlink: true
  property string currentTimeStr: Qt.formatTime(new Date(), "hh:mm:ss")
  property string currentDateStr: Qt.formatDate(new Date(), "yyyy-MM-dd")

  // Theming & Colors: Dynamically bonded to the active Omarchy OS Theme
  readonly property bool isLightMode: {
    var bg = Color.background
    return (bg.r * 0.299 + bg.g * 0.587 + bg.b * 0.114) > 0.5
  }

  function ensureContrast(c, isLight) {
    var lum = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
    if (isLight && lum > 0.55) return Qt.darker(c, 1.45)
    if (!isLight && lum < 0.22) return Qt.lighter(c, 1.7)
    return c
  }

  readonly property color accentColor: ensureContrast(Color.accent, isLightMode)
  readonly property color dimAccentColor: isLightMode
    ? Qt.darker(accentColor, 1.3)
    : Util.alpha(accentColor, 0.75)
  readonly property color textColor: Color.foreground
  readonly property color mutedColor: {
    if (Color.muted && Color.muted !== Color.foreground) return Color.muted
    return isLightMode ? "#475569" : Util.alpha(Color.foreground, 0.65)
  }
  readonly property color scrimColor: isLightMode
    ? Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.97)
    : Qt.rgba(Color.background.r * 0.22, Color.background.g * 0.22, Color.background.b * 0.22, 0.985)
  readonly property color cardBgColor: isLightMode
    ? Color.background
    : Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.95)
  readonly property color surfaceBgColor: isLightMode
    ? Qt.rgba(Color.background.r * 0.96, Color.background.g * 0.96, Color.background.b * 0.96, 0.85)
    : Qt.rgba(Color.background.r * 1.35, Color.background.g * 1.35, Color.background.b * 1.35, 0.85)
  readonly property string monoFont: Style.fontFamily || "JetBrainsMono Nerd Font, monospace"

  // Geometry
  readonly property int cardWidth: Math.round(Math.min(panel.width * 0.48, Style.space(680)))
  readonly property int previewHeight: Math.round(cardWidth * 0.58)
  readonly property int labelHeight: Style.space(56)

  // Derived counts
  readonly property int totalWindowsCount: {
    var count = 0
    for (var i = 0; i < root.workspaceRows.length; i++) {
      if (root.workspaceRows[i] && root.workspaceRows[i].windows)
        count += root.workspaceRows[i].windows.length
    }
    return count
  }
  readonly property int occupiedCount: root.workspaceRows.length

  // Decorative ambient constellation matrix tiles
  readonly property var matrixTiles: [
    { x: 0.04, y: 0.14, w: 72, h: 46, op: 0.08 },
    { x: 0.11, y: 0.22, w: 96, h: 58, op: 0.12 },
    { x: 0.06, y: 0.36, w: 68, h: 42, op: 0.06 },
    { x: 0.16, y: 0.44, w: 110, h: 72, op: 0.13 },
    { x: 0.03, y: 0.60, w: 84, h: 52, op: 0.09 },
    { x: 0.13, y: 0.72, w: 64, h: 40, op: 0.07 },
    { x: 0.21, y: 0.82, w: 92, h: 60, op: 0.11 },
    { x: 0.86, y: 0.14, w: 82, h: 52, op: 0.10 },
    { x: 0.93, y: 0.26, w: 68, h: 44, op: 0.07 },
    { x: 0.82, y: 0.38, w: 118, h: 74, op: 0.13 },
    { x: 0.89, y: 0.54, w: 64, h: 38, op: 0.08 },
    { x: 0.83, y: 0.68, w: 104, h: 64, op: 0.12 },
    { x: 0.91, y: 0.80, w: 76, h: 48, op: 0.06 },
    { x: 0.76, y: 0.86, w: 88, h: 56, op: 0.09 },
    { x: 0.31, y: 0.15, w: 58, h: 36, op: 0.06 },
    { x: 0.69, y: 0.17, w: 72, h: 46, op: 0.08 },
    { x: 0.32, y: 0.86, w: 80, h: 50, op: 0.09 },
    { x: 0.66, y: 0.87, w: 90, h: 58, op: 0.10 },
    { x: 0.24, y: 0.26, w: 70, h: 45, op: 0.07 },
    { x: 0.75, y: 0.24, w: 85, h: 55, op: 0.09 },
    { x: 0.02, y: 0.48, w: 55, h: 35, op: 0.05 },
    { x: 0.95, y: 0.44, w: 60, h: 38, op: 0.06 },
    { x: 0.28, y: 0.74, w: 65, h: 42, op: 0.08 },
    { x: 0.71, y: 0.74, w: 75, h: 48, op: 0.08 },
    { x: 0.08, y: 0.88, w: 80, h: 52, op: 0.07 },
    { x: 0.88, y: 0.92, w: 70, h: 44, op: 0.07 },
    { x: 0.15, y: 0.05, w: 64, h: 40, op: 0.06 },
    { x: 0.82, y: 0.06, w: 75, h: 48, op: 0.08 }
  ]

  ListModel {
    id: workspaceModel
    dynamicRoles: true
  }

  function friendlyAppName(className) {
    var name = String(className || "App")
    var normalized = name.toLowerCase()
    var terminals = [
      "foot", "footclient", "alacritty", "kitty",
      "org.wezfurlong.wezterm", "com.mitchellh.ghostty"
    ]
    return terminals.indexOf(normalized) >= 0 ? "Terminal" : name
  }

  function rowForWorkspace(workspace) {
    var monitor = workspace.monitor
    var windows = []
    var toplevels = workspace.toplevels.values

    for (var i = 0; i < Math.min(toplevels.length, root.maxWindowsPerWorkspace); i++) {
      var window = toplevels[i]
      var ipc = window.lastIpcObject || ({})
      var waylandAppId = window.wayland ? window.wayland.appId : ""
      var at = ipc.at || [monitor ? monitor.x : 0, monitor ? monitor.y : 0]
      var size = ipc.size || [Style.space(300), Style.space(200)]
      var addr = window.address || (ipc.address ? ipc.address : "")
      windows.push({
        title: window.title || ipc.title || "Window",
        className: root.friendlyAppName(ipc.class || waylandAppId || "App"),
        address: addr,
        rawWindow: window,
        x: at[0],
        y: at[1],
        width: size[0],
        height: size[1]
      })
    }

    return {
      id: workspace.id,
      name: workspace.name,
      workspace: workspace,
      focused: workspace.focused,
      monitorName: monitor ? monitor.name : "",
      monitorX: monitor ? monitor.x : 0,
      monitorY: monitor ? monitor.y : 0,
      monitorWidth: monitor ? monitor.width : panel.width,
      monitorHeight: monitor ? monitor.height : panel.height,
      windows: windows
    }
  }

  function syncWorkspaceModel(rows) {
    for (var i = 0; i < rows.length; i++) {
      var existingIndex = -1
      for (var j = i; j < workspaceModel.count; j++) {
        var existingRow = workspaceModel.get(j).row
        if (existingRow && existingRow.id === rows[i].id) {
          existingIndex = j
          break
        }
      }

      if (existingIndex < 0) {
        workspaceModel.insert(i, { row: rows[i] })
      } else {
        if (existingIndex !== i) workspaceModel.move(existingIndex, i, 1)
        workspaceModel.setProperty(i, "row", rows[i])
      }
    }

    while (workspaceModel.count > rows.length)
      workspaceModel.remove(workspaceModel.count - 1)
  }

  function screenForMonitorName(name) {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++) {
      if (screens[i].name === name) return screens[i]
    }
    return panel.screen
  }

  function rememberWorkspace(id) {
    if (id === undefined || id === null || id <= 0) return

    var next = [id]
    for (var i = 0; i < root.recentWorkspaceIds.length; i++) {
      var existingId = root.recentWorkspaceIds[i]
      if (existingId !== id) next.push(existingId)
    }
    root.recentWorkspaceIds = next.slice(0, root.maxWorkspaceCount)
  }

  function retainPreview(id) {
    var next = [id]
    for (var i = 0; i < root.retainedPreviewIds.length; i++) {
      var existingId = root.retainedPreviewIds[i]
      if (existingId !== id) next.push(existingId)
    }
    root.retainedPreviewIds = next.slice(0, root.maxRetainedPreviewCount)
  }

  function recentWorkspaceRank(id) {
    for (var i = 0; i < root.recentWorkspaceIds.length; i++) {
      if (root.recentWorkspaceIds[i] === id) return i
    }
    return root.maxWorkspaceCount
  }

  function workspaceCandidateBefore(left, right) {
    if (left.recentRank !== right.recentRank)
      return left.recentRank < right.recentRank
    return left.id < right.id
  }

  function retainWorkspaceCandidate(candidates, workspace) {
    var candidate = {
      id: workspace.id,
      recentRank: root.recentWorkspaceRank(workspace.id),
      workspace: workspace
    }
    var insertAt = 0
    while (insertAt < candidates.length
           && !root.workspaceCandidateBefore(candidate, candidates[insertAt]))
      insertAt++

    if (candidates.length < root.maxWorkspaceCount) {
      candidates.splice(insertAt, 0, candidate)
      return
    }
    if (insertAt >= root.maxWorkspaceCount) return

    for (var i = root.maxWorkspaceCount - 1; i > insertAt; i--)
      candidates[i] = candidates[i - 1]
    candidates[insertAt] = candidate
  }

  function rebuild() {
    var values = Hyprland.workspaces.values
    var candidates = []
    var rows = []

    if (Hyprland.focusedWorkspace)
      root.rememberWorkspace(Hyprland.focusedWorkspace.id)

    for (var i = 0; i < values.length; i++) {
      var workspace = values[i]
      if (workspace.id > 0 && workspace.toplevels.values.length > 0)
        root.retainWorkspaceCandidate(candidates, workspace)
    }

    for (var candidateIndex = 0; candidateIndex < candidates.length; candidateIndex++)
      rows.push(root.rowForWorkspace(candidates[candidateIndex].workspace))

    rows.sort(function(left, right) { return left.id - right.id })

    root.syncWorkspaceModel(rows)
    root.workspaceRows = rows

    if (rows.length === 0) {
      root.selectedIndex = 0
      return
    }

    if (root.selectedIndex >= rows.length) root.selectedIndex = rows.length - 1
    if (root.selectedIndex < 0) root.selectedIndex = 0
  }

  function rowIndexForWorkspace(id) {
    for (var i = 0; i < root.workspaceRows.length; i++) {
      if (root.workspaceRows[i].id === id) return i
    }
    return -1
  }

  function focusedIndex() {
    var focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    for (var i = 0; i < workspaceRows.length; i++) {
      if (workspaceRows[i].id === focusedId) return i
    }
    return 0
  }

  function captureFocusedWorkspace() {
    if (root.opened || !Hyprland.focusedWorkspace) return

    root.rebuild()
    var index = root.rowIndexForWorkspace(Hyprland.focusedWorkspace.id)
    if (index < 0) return

    var card = workspaceList.itemAtIndex(index)
    if (card && typeof card.capturePreview === "function")
      card.capturePreview()
  }

  function previousWorkspaceIndex(currentId) {
    for (var i = 0; i < root.recentWorkspaceIds.length; i++) {
      var recentId = root.recentWorkspaceIds[i]
      if (recentId !== currentId) {
        var recentIndex = root.rowIndexForWorkspace(recentId)
        if (recentIndex >= 0) return recentIndex
      }
    }

    return root.workspaceRows.length > 1
      ? (root.focusedIndex() + 1) % root.workspaceRows.length
      : root.focusedIndex()
  }

  function select(direction) {
    if (root.workspaceRows.length < 2) return
    root.selectedIndex = (root.selectedIndex + direction + root.workspaceRows.length) % root.workspaceRows.length
    root.selectedWindowIndex = 0
    workspaceList.positionViewAtIndex(root.selectedIndex, ListView.Center)
  }

  function applyFilter() {
    var q = root.searchQuery.trim().toLowerCase()
    if (q === "") {
      root.selectedWindowIndex = 0
      return
    }

    for (var i = 0; i < root.workspaceRows.length; i++) {
      var row = root.workspaceRows[i]
      if (String(row.name).toLowerCase().indexOf(q) >= 0) {
        root.selectedIndex = i
        root.selectedWindowIndex = 0
        workspaceList.positionViewAtIndex(i, ListView.Center)
        return
      }
      for (var w = 0; w < row.windows.length; w++) {
        var win = row.windows[w]
        if (win.title.toLowerCase().indexOf(q) >= 0 || win.className.toLowerCase().indexOf(q) >= 0) {
          root.selectedIndex = i
          root.selectedWindowIndex = w
          workspaceList.positionViewAtIndex(i, ListView.Center)
          return
        }
      }
    }
  }

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }

    if (payload.commit === true) {
      if (root.opened) root.activate()
      return
    }

    if (payload.windowNav !== undefined) {
      if (root.selectedIndex >= 0 && root.selectedIndex < root.workspaceRows.length) {
        var numWins = root.workspaceRows[root.selectedIndex].windows.length
        if (numWins > 0) {
          root.selectedWindowIndex = (root.selectedWindowIndex + payload.windowNav + numWins) % numWins
          root.hudActionText = (payload.windowNav > 0 ? "↓" : "↑") + " WINDOW [" + (root.selectedWindowIndex + 1) + "/" + numWins + "]"
        }
      }
      return
    }

    if (payload.selectWorkspace !== undefined) {
      if (!root.opened) {
        root.rebuild()
        root.opened = true
        root.revealed = true
        root.quickSwitchPending = false
      }
      var targetId = payload.selectWorkspace
      var idx = root.rowIndexForWorkspace(targetId)
      root.hudActionText = "WORKSPACE 0" + targetId
      if (idx >= 0) {
        if (root.selectedIndex === idx) {
          root.activate()
        } else {
          root.selectedIndex = idx
          root.selectedWindowIndex = 0
          workspaceList.positionViewAtIndex(root.selectedIndex, ListView.Center)
          Qt.callLater(function() { keyCatcher.forceActiveFocus() })
        }
      } else {
        Quickshell.execDetached([
          "hyprctl",
          "dispatch",
          'hl.dsp.focus({ workspace = "' + targetId + '" })'
        ])
        root.dismiss()
      }
      return
    }

    if (payload.immediate === true || payload.direction === 0) {
      console.log("SWITCHER: open immediate called. opened:", root.opened);
      if (!root.opened) {
        root.rebuild();
        console.log("SWITCHER: rebuild finished. rows count:", root.workspaceRows.length);
        if (root.workspaceRows.length === 0) return;
        root.selectedIndex = root.focusedIndex();
        root.selectedWindowIndex = 0;
        root.opened = true;
        root.revealed = true;
        root.quickSwitchPending = false;
        root.searchQuery = "";
        root.hudActionText = "SUPER + TAB";
        console.log("SWITCHER: opened and revealed set to true!");
        workspaceList.positionViewAtIndex(root.selectedIndex, ListView.Center);
        Qt.callLater(function() { keyCatcher.forceActiveFocus(); });
      }
      return;
    }

    var direction = payload.direction === -1 ? -1 : 1

    if (!root.opened) {
      root.rebuild()
      if (root.workspaceRows.length === 0) return
      var currentIndex = root.focusedIndex()
      var currentId = root.workspaceRows[currentIndex].id
      root.selectedIndex = direction < 0
        ? (currentIndex - 1 + root.workspaceRows.length) % root.workspaceRows.length
        : root.previousWorkspaceIndex(currentId)
      root.selectedWindowIndex = 0
      root.opened = true
      root.revealed = false
      root.quickSwitchPending = true
      root.searchQuery = ""
      root.hudActionText = direction > 0 ? "SUPER + TAB" : "SUPER + SHIFT + TAB"
      revealTimer.restart()
    } else {
      if (root.quickSwitchPending) {
        root.selectedIndex = root.focusedIndex()
        root.quickSwitchPending = false
      }
      root.select(direction)
      root.hudActionText = direction > 0 ? "SUPER + TAB" : "SUPER + SHIFT + TAB"
    }

    workspaceList.positionViewAtIndex(root.selectedIndex, ListView.Center)
  }

  function close() {
    root.opened = false
    root.revealed = false
    root.quickSwitchPending = false
    root.searchQuery = ""
    revealTimer.stop()
  }

  function dismiss() {
    root.opened = false
    root.revealed = false
    root.quickSwitchPending = false
    root.searchQuery = ""
    revealTimer.stop()
    Quickshell.execDetached([
      "hyprctl",
      "dispatch",
      'hl.dsp.submap("reset")'
    ])
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "reomarchy.workspace-switcher")
  }

  function activate() {
    if (root.selectedIndex < 0 || root.selectedIndex >= root.workspaceRows.length) {
      root.dismiss()
      return
    }

    var row = root.workspaceRows[root.selectedIndex]
    var workspaceId = row.id

    if (root.selectedWindowIndex >= 0 && root.selectedWindowIndex < row.windows.length) {
      var win = row.windows[root.selectedWindowIndex]
      if (win && win.address) {
        Quickshell.execDetached([
          "hyprctl",
          "dispatch",
          "focuswindow",
          "address:" + win.address
        ])
        root.dismiss()
        return
      }
    }

    Quickshell.execDetached([
      "hyprctl",
      "dispatch",
      'hl.dsp.focus({ workspace = "' + workspaceId + '" })'
    ])
    root.dismiss()
  }

  Component.onCompleted: {
    root.rebuild()
    if (Hyprland.focusedWorkspace)
      root.rememberWorkspace(Hyprland.focusedWorkspace.id)
    initialCaptureTimer.restart()
  }

  Timer {
    id: captureTimer
    interval: 300
    repeat: false
    onTriggered: root.captureFocusedWorkspace()
  }

  Timer {
    id: revealTimer
    interval: 180
    repeat: false
    onTriggered: {
      if (!root.opened) return
      if (root.quickSwitchPending) {
        root.selectedIndex = root.focusedIndex()
        root.quickSwitchPending = false
        workspaceList.positionViewAtIndex(root.selectedIndex, ListView.Center)
      }
      root.revealed = true
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }
  }

  Timer {
    id: initialCaptureTimer
    interval: 1500
    repeat: false
    onTriggered: root.captureFocusedWorkspace()
  }

  Timer {
    interval: 1000
    running: root.revealed
    repeat: true
    onTriggered: {
      root.currentTimeStr = Qt.formatTime(new Date(), "hh:mm:ss")
      root.currentDateStr = Qt.formatDate(new Date(), "yyyy-MM-dd")
    }
  }

  Timer {
    interval: 500
    running: root.revealed
    repeat: true
    onTriggered: root.cursorBlink = !root.cursorBlink
  }

  Connections {
    target: Hyprland

    function onFocusedWorkspaceChanged() {
      if (Hyprland.focusedWorkspace) {
        root.rememberWorkspace(Hyprland.focusedWorkspace.id)
        captureTimer.restart()
      }
    }
  }

  PanelWindow {
    id: panel
    visible: true
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "reomarchy-workspace-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.revealed ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {
      width: (root.revealed || root.opened) ? panel.width : 0
      height: (root.revealed || root.opened) ? panel.height : 0
    }

    // Deep Dark Scrim Overlay
    Rectangle {
      anchors.fill: parent
      visible: opacity > 0
      opacity: root.revealed ? 1 : 0
      color: root.scrimColor

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      // Constellation / Space Matrix Background Tiles
      Item {
        anchors.fill: parent
        visible: !root.isLightMode

        Repeater {
          model: root.matrixTiles

          Rectangle {
            required property var modelData
            x: modelData.x * panel.width
            y: modelData.y * panel.height
            width: Style.space(modelData.w)
            height: Style.space(modelData.h)
            color: Util.alpha(Color.background, Math.min(1.0, modelData.op * 1.5))
            border.width: 1
            border.color: Util.alpha(root.accentColor, modelData.op * 1.6)
            radius: 2

            Column {
              anchors.fill: parent
              anchors.margins: 4
              spacing: 3
              Rectangle { width: parent.width * 0.72; height: 1; color: Util.alpha(Color.foreground, modelData.op * 1.2) }
              Rectangle { width: parent.width * 0.44; height: 1; color: Util.alpha(Color.foreground, modelData.op * 0.9) }
              Rectangle { width: parent.width * 0.86; height: 1; color: Util.alpha(root.accentColor, modelData.op * 0.8) }
            }
          }
        }
      }
    }

    // Dismiss click area
    MouseArea {
      anchors.fill: parent
      enabled: root.revealed
      onClicked: root.dismiss()
    }

    // Key catcher for navigation & typing
    Item {
      id: keyCatcher
      anchors.fill: parent
      visible: root.revealed
      focus: true

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          if (root.searchQuery.length > 0) {
            root.searchQuery = ""
            root.applyFilter()
            root.hudActionText = "CLEAR FILTER"
          } else {
            root.dismiss()
          }
          event.accepted = true
        } else if (event.key === Qt.Key_Tab) {
          var dir = (event.modifiers & Qt.ShiftModifier) ? -1 : 1
          root.select(dir)
          root.hudActionText = dir > 0 ? "SUPER + TAB" : "SUPER + SHIFT + TAB"
          event.accepted = true
        } else if (event.key === Qt.Key_Left) {
          root.select(-1)
          root.hudActionText = "← WORKSPACE"
          event.accepted = true
        } else if (event.key === Qt.Key_Right) {
          root.select(1)
          root.hudActionText = "→ WORKSPACE"
          event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          if (root.selectedIndex >= 0 && root.selectedIndex < root.workspaceRows.length) {
            var numWins = root.workspaceRows[root.selectedIndex].windows.length
            if (numWins > 0) {
              root.selectedWindowIndex = (root.selectedWindowIndex - 1 + numWins) % numWins
              root.hudActionText = "↑ WINDOW [" + (root.selectedWindowIndex + 1) + "/" + numWins + "]"
            }
          }
          event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          if (root.selectedIndex >= 0 && root.selectedIndex < root.workspaceRows.length) {
            var numWins = root.workspaceRows[root.selectedIndex].windows.length
            if (numWins > 0) {
              root.selectedWindowIndex = (root.selectedWindowIndex + 1) % numWins
              root.hudActionText = "↓ WINDOW [" + (root.selectedWindowIndex + 1) + "/" + numWins + "]"
            }
          }
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.activate()
          event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
          if (root.searchQuery.length > 0) {
            root.searchQuery = root.searchQuery.substring(0, root.searchQuery.length - 1)
            root.applyFilter()
            root.hudActionText = root.searchQuery.length > 0 ? ("SORT: " + root.searchQuery.toUpperCase()) : "SUPER + TAB"
          }
          event.accepted = true
        } else if (root.searchQuery === "" && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
          var targetId = event.key - Qt.Key_0
          var idx = root.rowIndexForWorkspace(targetId)
          root.hudActionText = "WORKSPACE 0" + targetId
          if (idx >= 0) {
            if (root.selectedIndex === idx) {
              root.activate()
            } else {
              root.selectedIndex = idx
              root.selectedWindowIndex = 0
              workspaceList.positionViewAtIndex(root.selectedIndex, ListView.Center)
            }
          } else {
            Quickshell.execDetached([
              "hyprctl",
              "dispatch",
              'hl.dsp.focus({ workspace = "' + targetId + '" })'
            ])
            root.dismiss()
          }
          event.accepted = true
        } else if (root.searchQuery === "" && event.key === Qt.Key_0) {
          var targetId = 10
          var idx = root.rowIndexForWorkspace(targetId)
          root.hudActionText = "WORKSPACE 10"
          if (idx >= 0) {
            if (root.selectedIndex === idx) {
              root.activate()
            } else {
              root.selectedIndex = idx
              root.selectedWindowIndex = 0
              workspaceList.positionViewAtIndex(root.selectedIndex, ListView.Center)
            }
          } else {
            Quickshell.execDetached([
              "hyprctl",
              "dispatch",
              'hl.dsp.focus({ workspace = "' + targetId + '" })'
            ])
            root.dismiss()
          }
          event.accepted = true
        } else if (event.text && event.text.length > 0 && !event.modifiers) {
          var ch = event.text
          if (ch >= ' ' && ch <= '~') {
            root.searchQuery += ch
            root.applyFilter()
            root.hudActionText = "SORT: " + root.searchQuery.toUpperCase()
            event.accepted = true
          }
        }
      }
    }

    // ==========================================
    // TOP STATUS HUD
    // ==========================================
    Item {
      anchors.top: parent.top
      anchors.topMargin: Style.space(48)
      anchors.left: parent.left
      anchors.leftMargin: Style.space(38)
      anchors.right: parent.right
      anchors.rightMargin: Style.space(38)
      height: Style.space(64)
      visible: root.revealed
      opacity: root.revealed ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      // Top Left: Workspace numbers & live clock
      Column {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: Style.space(8)

        Row {
          spacing: Style.space(10)

          Row {
            spacing: Style.space(6)
            Repeater {
              model: 9
              Text {
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isCurrentWs: {
                  if (root.selectedIndex >= 0 && root.selectedIndex < root.workspaceRows.length) {
                    return root.workspaceRows[root.selectedIndex].id === wsId
                  }
                  return false
                }
                text: isCurrentWs ? ("[ " + wsId + " ]") : (" " + wsId + " ")
                color: isCurrentWs ? root.accentColor : root.mutedColor
                font.family: root.monoFont
                font.bold: isCurrentWs
                font.pixelSize: Style.space(12)
              }
            }
          }

          Text {
            text: "|"
            color: Util.alpha(Color.foreground, 0.28)
            font.family: root.monoFont
            font.pixelSize: Style.space(12)
          }

          Text {
            text: "SYSTEM // OBSERVING"
            color: root.dimAccentColor
            font.family: root.monoFont
            font.pixelSize: Style.space(12)
            font.letterSpacing: 1.2
          }
        }

        Column {
          spacing: Style.space(2)

          Text {
            text: root.currentTimeStr
            color: root.textColor
            font.family: root.monoFont
            font.bold: true
            font.pixelSize: Style.space(18)
          }

          Text {
            text: root.currentDateStr + " • " + (panel.screen ? panel.screen.name : "DP-1")
            color: root.mutedColor
            font.family: root.monoFont
            font.pixelSize: Style.space(11)
          }
        }
      }

      // Top Center: Window count badge
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          height: Style.space(24)
          width: windowBadgeText.implicitWidth + Style.space(16)
          color: root.surfaceBgColor
          border.width: 1
          border.color: Util.alpha(Color.foreground, 0.22)
          radius: 2

          Text {
            id: windowBadgeText
            anchors.centerIn: parent
            text: root.totalWindowsCount + (root.totalWindowsCount === 1 ? " WINDOW" : " WINDOWS")
            color: root.mutedColor
            font.family: root.monoFont
            font.pixelSize: Style.space(11)
          }
        }
      }

      // Top Right: Occupied, shown & urgent counters
      Column {
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(4)

        Text {
          anchors.right: parent.right
          text: root.occupiedCount + " OCCUPIED • " + root.workspaceRows.length + " SHOWN"
          color: root.mutedColor
          font.family: root.monoFont
          font.pixelSize: Style.space(11)
        }

        Text {
          anchors.right: parent.right
          text: "0 URGENT"
          color: root.mutedColor
          font.family: root.monoFont
          font.pixelSize: Style.space(11)
        }
      }
    }

    // ==========================================
    // MAIN CAROUSEL LISTVIEW
    // ==========================================
    ListView {
      id: workspaceList
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.right: parent.right
      height: root.previewHeight + root.labelHeight + Style.space(24)
      orientation: ListView.Horizontal
      spacing: Style.space(28)
      clip: false
      boundsBehavior: Flickable.StopAtBounds
      preferredHighlightBegin: (panel.width - root.cardWidth) / 2
      preferredHighlightEnd: (panel.width + root.cardWidth) / 2
      highlightRangeMode: ListView.StrictlyEnforceRange
      currentIndex: root.selectedIndex
      highlightMoveDuration: 200
      cacheBuffer: root.maxRetainedPreviewCount * (root.cardWidth + Style.space(28))
      reuseItems: false
      model: workspaceModel

      visible: opacity > 0
      opacity: root.revealed ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      delegate: Item {
        id: workspaceCard
        required property int index
        required property var row

        readonly property bool isCurrent: index === root.selectedIndex
        readonly property bool isHovered: previewMouse.containsMouse
        readonly property bool retainPreview: root.retainedPreviewIds.indexOf(row.id) >= 0

        width: root.cardWidth
        height: root.previewHeight + root.labelHeight
        scale: isCurrent ? 1.0 : (isHovered ? 0.88 : 0.84)
        opacity: isCurrent ? 1.0 : (isHovered ? 0.55 : 0.35)
        z: isCurrent ? 10 : 1

        Behavior on scale {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        function capturePreview() {
          root.retainPreview(row.id)
          var source = root.screenForMonitorName(row.monitorName)
          if (workspaceCapture.captureSource !== source)
            workspaceCapture.captureSource = source

          if (workspaceCapture.hasContent)
            workspaceCapture.captureFrame()
          else
            workspaceCapture.live = true
        }

        onRetainPreviewChanged: {
          if (!retainPreview) {
            workspaceCapture.live = false
            workspaceCapture.captureSource = null
          }
        }

        // Preview Box with Cyber Frame & Corners
        Rectangle {
          id: preview
          width: parent.width
          height: root.previewHeight
          radius: 2
          color: root.cardBgColor
          border.width: 1
          border.color: workspaceCard.isCurrent
            ? Util.alpha(root.accentColor, 0.5)
            : Util.alpha(Color.foreground, 0.22)
          clip: true

          // Screencopy Live Screenshot
          ScreencopyView {
            id: workspaceCapture
            anchors.fill: parent
            anchors.margins: 1
            captureSource: null
            live: false
            paintCursor: false
            visible: hasContent
            onHasContentChanged: {
              if (hasContent && live) live = false
            }
          }

          // Fallback Wireframe Window Layout
          Item {
            anchors.fill: parent
            visible: !workspaceCapture.hasContent

            Repeater {
              model: workspaceCard.row.windows

              Rectangle {
                required property var modelData
                readonly property real availableWidth: preview.width - Style.space(24)
                readonly property real availableHeight: preview.height - Style.space(24)
                x: Style.space(12) + Math.max(0, (modelData.x - workspaceCard.row.monitorX)
                  / Math.max(1, workspaceCard.row.monitorWidth) * availableWidth)
                y: Style.space(12) + Math.max(0, (modelData.y - workspaceCard.row.monitorY)
                  / Math.max(1, workspaceCard.row.monitorHeight) * availableHeight)
                width: Math.max(Style.space(46), Math.min(availableWidth,
                  modelData.width / Math.max(1, workspaceCard.row.monitorWidth) * availableWidth))
                height: Math.max(Style.space(32), Math.min(availableHeight,
                  modelData.height / Math.max(1, workspaceCard.row.monitorHeight) * availableHeight))
                radius: 2
                color: Util.alpha(Color.background, 0.88)
                border.width: 1
                border.color: Util.alpha(root.accentColor, 0.35)

                Text {
                  anchors.fill: parent
                  anchors.margins: Style.space(6)
                  text: modelData.className
                  textFormat: Text.PlainText
                  color: root.textColor
                  font.family: root.monoFont
                  font.pixelSize: Style.space(10)
                  elide: Text.ElideRight
                  verticalAlignment: Text.AlignVCenter
                }
              }
            }
          }

          // Top-Left Inside Badge: Two-digit Workspace Number (e.g. 03)
          Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: Style.space(12)
            text: (row.id < 10 ? "0" + row.id : "" + row.id)
            color: workspaceCard.isCurrent ? root.accentColor : root.mutedColor
            font.family: root.monoFont
            font.bold: true
            font.pixelSize: Style.space(14)
          }

          // Bottom-Right Inside Badge: Window Count (e.g. 1 WINDOW)
          Text {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: Style.space(10)
            text: row.windows.length + (row.windows.length === 1 ? " WINDOW" : " WINDOWS")
            color: workspaceCard.isCurrent ? root.textColor : root.mutedColor
            font.family: root.monoFont
            font.pixelSize: Style.space(10)
            opacity: 0.85
          }

          MouseArea {
            id: previewMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.selectedIndex = index
              root.activate()
            }
          }
        }

        // Four Amber / Gold Corner Brackets Framing Active & Hovered Card
        Item {
          anchors.fill: preview
          anchors.margins: -Style.space(4)
          visible: workspaceCard.isCurrent || workspaceCard.isHovered
          z: 20

          // Top-Left ┌
          Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: Style.space(22); height: 2; color: root.accentColor }
          Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: 2; height: Style.space(22); color: root.accentColor }

          // Top-Right ┐
          Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: Style.space(22); height: 2; color: root.accentColor }
          Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: 2; height: Style.space(22); color: root.accentColor }

          // Bottom-Left └
          Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: Style.space(22); height: 2; color: root.accentColor }
          Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: 2; height: Style.space(22); color: root.accentColor }

          // Bottom-Right ┘
          Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: Style.space(22); height: 2; color: root.accentColor }
          Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: 2; height: Style.space(22); color: root.accentColor }
        }

        // ==========================================
        // BELOW-CARD STATUS PANEL & WINDOW TITLE
        // ==========================================
        Column {
          anchors.top: preview.bottom
          anchors.topMargin: Style.space(12)
          anchors.left: parent.left
          anchors.right: parent.right
          spacing: Style.space(5)

          // Line 1: ■ WORKSPACE 03 ──────────────────────────── 1 WINDOW
          RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Style.space(10)

            Text {
              text: "■ WORKSPACE " + (row.id < 10 ? "0" + row.id : "" + row.id)
              color: workspaceCard.isCurrent ? root.accentColor : root.mutedColor
              font.family: root.monoFont
              font.bold: true
              font.pixelSize: Style.space(12)
            }

            Rectangle {
              Layout.fillWidth: true
              height: 1
              color: workspaceCard.isCurrent
                ? Util.alpha(root.accentColor, 0.35)
                : Util.alpha(Color.foreground, 0.22)
            }

            Text {
              text: row.windows.length + (row.windows.length === 1 ? " WINDOW" : " WINDOWS")
              color: workspaceCard.isCurrent ? root.textColor : root.mutedColor
              font.family: root.monoFont
              font.pixelSize: Style.space(11)
            }
          }

          // Line 2: ▮ Active Window Title
          RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Style.space(8)

            Text {
              text: "▮"
              color: workspaceCard.isCurrent ? root.accentColor : root.mutedColor
              font.family: root.monoFont
              font.pixelSize: Style.space(12)
            }

            Text {
              readonly property int winIdx: (workspaceCard.isCurrent && root.selectedWindowIndex < row.windows.length)
                ? root.selectedWindowIndex : 0
              readonly property var activeWin: (row.windows.length > 0) ? row.windows[winIdx] : null
              text: activeWin ? (activeWin.title || activeWin.className || "Window") : "Desktop"
              color: workspaceCard.isCurrent ? root.textColor : root.mutedColor
              font.family: root.monoFont
              font.pixelSize: Style.space(12)
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }
        }
      }
    }

    // ==========================================
    // BOTTOM NAVIGATION HUD
    // ==========================================
    Item {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(26)
      anchors.leftMargin: Style.space(38)
      anchors.rightMargin: Style.space(38)
      height: Style.space(36)
      visible: root.revealed
      opacity: root.revealed ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      // Bottom Left: Keybind Guide
      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(14)

        Row {
          spacing: Style.space(4)
          Text { text: "← →"; color: root.accentColor; font.family: root.monoFont; font.pixelSize: Style.space(11); font.bold: true }
          Text { text: "workspace"; color: root.mutedColor; font.family: root.monoFont; font.pixelSize: Style.space(11) }
        }
        Row {
          spacing: Style.space(4)
          Text { text: "↑ ↓"; color: root.accentColor; font.family: root.monoFont; font.pixelSize: Style.space(11); font.bold: true }
          Text { text: "window"; color: root.mutedColor; font.family: root.monoFont; font.pixelSize: Style.space(11) }
        }
        Row {
          spacing: Style.space(4)
          Text { text: "1-9"; color: root.accentColor; font.family: root.monoFont; font.pixelSize: Style.space(11); font.bold: true }
          Text { text: "go"; color: root.mutedColor; font.family: root.monoFont; font.pixelSize: Style.space(11) }
        }
        Row {
          spacing: Style.space(4)
          Text { text: "↵"; color: root.accentColor; font.family: root.monoFont; font.pixelSize: Style.space(11); font.bold: true }
          Text { text: "open"; color: root.mutedColor; font.family: root.monoFont; font.pixelSize: Style.space(11) }
        }
        Row {
          spacing: Style.space(4)
          Text { text: "esc"; color: root.accentColor; font.family: root.monoFont; font.pixelSize: Style.space(11); font.bold: true }
          Text { text: "close"; color: root.mutedColor; font.family: root.monoFont; font.pixelSize: Style.space(11) }
        }
      }

      // Bottom Center: Keypress HUD Box with Corner Marks
      Rectangle {
        anchors.centerIn: parent
        height: Style.space(28)
        width: keyHistoryRow.implicitWidth + Style.space(28)
        color: root.surfaceBgColor
        border.width: 1
        border.color: Util.alpha(root.accentColor, 0.4)
        radius: 2

        Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: 6; height: 1; color: root.accentColor }
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: 1; height: 6; color: root.accentColor }
        Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: 6; height: 1; color: root.accentColor }
        Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: 1; height: 6; color: root.accentColor }
        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: 6; height: 1; color: root.accentColor }
        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: 1; height: 6; color: root.accentColor }
        Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: 6; height: 1; color: root.accentColor }
        Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: 1; height: 6; color: root.accentColor }

        Row {
          id: keyHistoryRow
          anchors.centerIn: parent
          spacing: Style.space(10)

          Text {
            text: root.hudActionText
            color: root.accentColor
            font.family: root.monoFont
            font.pixelSize: Style.space(11)
            font.bold: true
          }
        }
      }

      // Bottom Right: Type indicator
      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(6)

        Text {
          text: root.searchQuery !== "" ? ("FILTER: '" + root.searchQuery.toUpperCase() + "'") : "TYPE TO SORT"
          color: root.searchQuery !== "" ? root.accentColor : root.mutedColor
          font.family: root.monoFont
          font.pixelSize: Style.space(11)
          font.bold: root.searchQuery !== ""
        }
      }
    }
  }
}
