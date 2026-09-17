import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Ui
import qs.Commons
import "SlotModel.js" as SlotModel

// Bar entry for the scratchpad deck: a glyph, an occupancy count, and the
// popup that does the actual work.
//
// This widget owns the slot model rather than the panel because the hotkeys
// have to work whether or not the deck has ever been opened — the panel is
// created lazily, the widget is mounted for the whole session.
BarWidget {
  id: root
  moduleName: "tiertek.scratchpad-deck"

  // Deliberately always visible, dimmed when empty.
  //
  // A status widget should hide when it has nothing to report, but this one is
  // a control surface: hiding it on an empty machine means a new user installs
  // the plugin, sees nothing in the bar, and concludes it is broken. The
  // dimmed glyph is the only affordance telling them the deck is there and
  // that stashing a window will fill it.

  readonly property bool opened: deckLoader.item ? deckLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: deckLoader.item
    ? deckLoader.item.popoutSwitchClosing === true : false
  readonly property real openPanelIndicatorWidth: button.labelWidth

  // ---------------------------------------------------------------- model

  // Quickshell keeps these live off Hyprland's event socket, so the deck
  // reflects a window opening or closing without polling anything.
  readonly property var workspaceValues: Hyprland.workspaces ? Hyprland.workspaces.values : []

  readonly property var occupancy: {
    var rows = []
    var list = root.workspaceValues
    for (var i = 0; i < list.length; i++) {
      var ws = list[i]
      if (!ws || SlotModel.slotNumberFromWorkspace(ws.name) === 0) continue
      var windows = []
      var tops = ws.toplevels ? ws.toplevels.values : []
      for (var j = 0; j < tops.length; j++) {
        var t = tops[j]
        if (!t) continue
        var ipc = t.lastIpcObject || {}
        windows.push({
          address: t.address || "",
          title: t.title || "",
          // Hyprland calls it `class`; SlotModel normalizes it to appId.
          "class": ipc["class"] || "",
          toplevel: t
        })
      }
      rows.push({ name: ws.name, windows: windows })
    }
    return rows
  }

  readonly property var declaredSlots: root.setting("slots", [])
  readonly property var slots: SlotModel.buildSlots(root.occupancy, root.declaredSlots)
  readonly property int occupiedCount: {
    var n = 0
    for (var i = 0; i < root.slots.length; i++) if (root.slots[i].occupied) n++
    return n
  }

  // Which special workspace is currently showing, per monitor.
  //
  // This has to be event-driven. Hyprland does not re-emit a monitor's IPC
  // object when a special workspace is toggled, so reading
  // `monitor.lastIpcObject.specialWorkspace` returns whatever was true when the
  // monitor was last refreshed — which made cycling jump to the wrong slot and
  // the bar glyph miss its highlight. The `activespecial` event is immediate
  // and authoritative.
  property var specialByMonitor: ({})

  // Each monitor keeps its own special workspace, so the answer depends on
  // where the user is looking; that is also the monitor a hotkey acts on.
  readonly property string visibleWorkspace: {
    var mon = Hyprland.focusedMonitor
    if (!mon) return ""
    return String(root.specialByMonitor[mon.name] || "")
  }

  function noteSpecial(monitorName, workspaceName) {
    if (!monitorName) return
    // Reassign rather than mutate: QML only re-evaluates dependent bindings
    // when the property itself changes.
    var next = {}
    for (var k in root.specialByMonitor) next[k] = root.specialByMonitor[k]
    if (workspaceName === "") delete next[monitorName]
    else next[monitorName] = workspaceName
    root.specialByMonitor = next
  }

  Connections {
    target: Hyprland

    // `activespecial>>special:scratch-2,eDP-1`, and `activespecial>>,eDP-1`
    // when the last special workspace on that monitor closes.
    function onRawEvent(event) {
      if (!event || event.name !== "activespecial") return
      var parts = String(event.data || "").split(",")
      // A monitor name cannot contain a comma, but a workspace name can, so
      // the monitor is the last field and the workspace is everything before.
      var monitorName = parts.length > 1 ? parts[parts.length - 1] : ""
      var workspaceName = parts.slice(0, parts.length - 1).join(",")
      root.noteSpecial(monitorName, workspaceName)
    }
  }

  // Seed from the monitor objects at startup: they are accurate when first
  // fetched, and without this a shell restart while a scratchpad is showing
  // would leave the deck believing nothing is up.
  Component.onCompleted: {
    var mons = Hyprland.monitors ? Hyprland.monitors.values : []
    for (var i = 0; i < mons.length; i++) {
      var ipc = mons[i].lastIpcObject || {}
      var special = ipc.specialWorkspace || {}
      if (special.name) root.noteSpecial(mons[i].name, String(special.name))
    }
  }

  readonly property int visibleSlot: SlotModel.slotNumberFromWorkspace(root.visibleWorkspace)

  function slotFor(n) {
    for (var i = 0; i < root.slots.length; i++) if (root.slots[i].n === n) return root.slots[i]
    return null
  }

  // ---------------------------------------------------------------- actions

  // Hyprland 0.56 parses `hyprctl dispatch` as Lua, so the legacy
  // `dispatch togglespecialworkspace ...` form (and Quickshell's
  // Hyprland.dispatch, which speaks it) fails with a parse error. Everything
  // here goes through dispatch_lua_expression instead.
  function dispatch(expr) {
    Quickshell.execDetached(["hyprctl", "dispatch_lua_expression", expr])
  }

  function quoteLua(value) {
    // Long-bracket literals need no escaping and cannot be terminated by a
    // quote in a window title or a user's command string.
    return "[[" + String(value) + "]]"
  }

  // Show slot n, hiding whatever special workspace is currently up. Hyprland's
  // toggle_special already swaps cleanly when a *different* special workspace
  // is visible, so there is no hide-then-show dance to do here.
  function showSlot(n) {
    if (!SlotModel.isValidSlot(n)) return
    var slot = root.slotFor(n)
    if (slot && !slot.occupied) {
      // A declared slot with nothing in it launches its command straight into
      // the workspace. `silent` keeps focus where it is until the user asks
      // for the slot, which the toggle below does.
      if (slot.command === "") return
      var targetWs = (slot && slot.workspace) ? slot.workspace : ("special:scratch-" + n)
      root.dispatch("hl.dsp.exec_cmd(" + root.quoteLua(
        "[workspace " + targetWs + " silent] " + slot.command) + ")")
      pendingSlot.number = n
      pendingSlot.restart()
      return
    }
    var target = ""
    if (root.visibleSlot === n && root.visibleWorkspace !== "") {
      target = root.visibleWorkspace
    } else if (slot && slot.workspace) {
      target = slot.workspace
    } else {
      target = "special:scratch-" + n
    }
    var specialName = target.indexOf("special:") === 0 ? target.slice(8) : target
    root.dispatch("hl.dsp.workspace.toggle_special(" + root.quoteLua(specialName) + ")")
  }

  // Send the focused window into slot n. `follow = false` keeps the user where
  // they are — stashing a window should not teleport you away from your work.
  function sendToSlot(n) {
    if (!SlotModel.isValidSlot(n)) return
    var slot = root.slotFor(n)
    var target = (slot && slot.workspace) ? slot.workspace : ("special:scratch-" + n)
    root.dispatch("hl.dsp.window.move({ workspace = " + root.quoteLua(target)
      + ", follow = false })")
  }

  function cycle(direction) {
    var n = SlotModel.cycleSlot(root.slots, root.visibleWorkspace, direction)
    if (n > 0) root.showSlot(n)
  }

  function toggleDefault() {
    var n = SlotModel.defaultSlot(root.slots, root.visibleWorkspace)
    if (n > 0) root.showSlot(n)
  }

  // A freshly launched app needs a moment to map before its workspace exists.
  // Toggling immediately would create an empty workspace and show a blank
  // screen, so wait for the window and then reveal it.
  Timer {
    id: pendingSlot
    property int number: 0
    property int attempts: 0
    interval: 150
    repeat: true
    onRunningChanged: if (running) attempts = 0
    onTriggered: {
      attempts++
      var slot = root.slotFor(number)
      if (slot && slot.occupied) {
        stop()
        var target = (slot && slot.workspace) ? slot.workspace : ("special:scratch-" + number)
        var specialName = target.indexOf("special:") === 0 ? target.slice(8) : target
        root.dispatch("hl.dsp.workspace.toggle_special(" + root.quoteLua(specialName) + ")")
      } else if (attempts > 40) {
        // ~6s. The command was wrong, or the app refuses to start; give up
        // rather than toggling an empty workspace over the user's screen.
        stop()
      }
    }
  }

  function open() { if (deckLoader.item) deckLoader.item.open() }
  function close() { if (deckLoader.item) deckLoader.item.close() }
  function toggle() { if (deckLoader.item) deckLoader.item.toggle() }
  function closeForPopoutSwitch() { if (deckLoader.item) deckLoader.item.closeForPopoutSwitch() }

  function injectDeck() {
    var target = deckLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectDeck()
  onSettingsChanged: injectDeck()

  Loader {
    id: deckLoader
    active: true
    source: Qt.resolvedUrl("Deck.qml")
    visible: false
    onLoaded: {
      root.injectDeck()
      Qt.callLater(root.injectDeck)
    }
  }

  // The keybind path. `bin/scratchpad-deck` calls these; see hypr/README or
  // the snippet in hypr/scratchpad-deck.lua.
  IpcHandler {
    target: "tiertek.scratchpad-deck"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function slot(n: int): void { root.showSlot(n) }
    function send(n: int): void { root.sendToSlot(n) }
    function next(): void { root.cycle(1) }
    function prev(): void { root.cycle(-1) }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // U+F2D2, Nerd Font "window-restore": two stacked windows, which is what a
    // scratchpad holds. Verify any replacement by actually rendering it — the
    // first glyph picked here, U+F0593, turns out to be a cloud with a
    // lightning bolt, so the widget sat in the bar looking like a weather
    // applet.
    text: root.occupiedCount > 0 ? "\uF2D2 " + root.occupiedCount : "\uF2D2"
    active: root.visibleSlot > 0
    dimmed: root.occupiedCount === 0
    tooltipText: {
      if (root.occupiedCount === 0) return "Scratchpad Deck · nothing stashed"
      if (root.visibleSlot > 0) return "Scratchpad " + root.visibleSlot + " showing"
      return root.occupiedCount === 1
        ? "1 scratchpad stashed"
        : root.occupiedCount + " scratchpads stashed"
    }
    onPressed: function(mouseButton) {
      // Left opens the deck; middle cycles without opening anything, for the
      // user who just wants to flip between two stashed windows.
      if (mouseButton === Qt.MiddleButton) root.cycle(1)
      else if (mouseButton === Qt.RightButton) root.toggleDefault()
      else root.toggle()
    }
    onWheelMoved: function(delta) { root.cycle(delta > 0 ? -1 : 1) }
  }
}
