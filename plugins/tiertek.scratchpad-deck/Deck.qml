import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Ui
import qs.Commons
import "SlotModel.js" as SlotModel

// The dropdown: one card per scratchpad slot, each showing a live capture of
// the window hiding in it.
//
// The captures come from Quickshell's ScreencopyView, which on Hyprland uses
// hyprland-toplevel-export-v1. That protocol renders a window on demand, so it
// works on windows sitting in a hidden special workspace that have never been
// displayed at all — which is the whole reason this plugin can exist.
//
// Capture is not free, so every ScreencopyView lives inside a Loader gated on
// `opened`. With the deck closed, none of them exist and the plugin costs
// nothing but the bar glyph.
Panel {
  id: root
  moduleName: "tiertek.scratchpad-deck"
  // The bar widget owns the IPC target: it is mounted for the whole session,
  // while this panel is created lazily and must not race it for the name.
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property var barIdentity: hostWidget || root
  readonly property var slots: hostWidget ? hostWidget.slots : []
  readonly property int visibleSlot: hostWidget ? hostWidget.visibleSlot : 0
  readonly property string family: bar ? bar.fontFamily : Style.font.family

  readonly property int cardWidth: Style.space(200)
  readonly property int previewHeight: Style.space(124)

  // ---------------------------------------------------------------- cursor

  // Keyboard cursor over the cards. Hidden until the first arrow press so the
  // selection never appears somewhere the eye was not already looking.
  property bool cursorActive: false
  property int cursorIndex: 0

  function moveCursor(delta) {
    if (root.slots.length === 0) return
    var next = root.cursorIndex + delta
    root.cursorIndex = next < 0 ? 0
      : next > root.slots.length - 1 ? root.slots.length - 1 : next
  }

  function activate(slot) {
    if (!slot || !hostWidget) return
    hostWidget.showSlot(slot.n)
    root.close()
  }

  function activateCursor() {
    if (!root.cursorActive) return
    root.activate(root.slots[root.cursorIndex])
  }

  // Typing a slot number jumps straight to it, matching the global hotkeys.
  function activateNumber(text) {
    var n = parseInt(text, 10)
    if (!SlotModel.isValidSlot(n)) return
    for (var i = 0; i < root.slots.length; i++) {
      if (root.slots[i].n === n) { root.activate(root.slots[i]); return }
    }
  }

  // Best-effort app icon. A desktop entry is the reliable source, but plenty of
  // windows report a class that matches no entry (terminals launched with a
  // custom class, Electron apps, anything started from a script), so fall back
  // to an icon named after the app id before giving up on a generic glyph.
  function iconFor(appId) {
    var id = String(appId || "").trim()
    if (id === "") return ""
    var entry = DesktopEntries.heuristicLookup(id)
    if (entry && entry.icon) {
      var themed = Quickshell.iconPath(entry.icon, true)
      if (themed !== "") return themed
    }
    var direct = Quickshell.iconPath(id, true)
    if (direct !== "") return direct
    return Quickshell.iconPath(id.toLowerCase(), true)
  }

  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function") return bar.switchPanelFrom(barIdentity, direction)
    return false
  }

  onOpenedChanged: {
    if (!opened) return
    root.cursorActive = false
    // Open with the cursor already on the scratchpad that is showing, so
    // arrow keys move relative to what the user can see.
    var index = 0
    for (var i = 0; i < root.slots.length; i++) {
      if (root.slots[i].n === root.visibleSlot) { index = i; break }
    }
    root.cursorIndex = index
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(
      root.slots.length > 0
        ? root.slots.length * (root.cardWidth + Style.space(10)) + Style.space(10)
        : Style.space(280))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        // The cards sit in a row, so left/right is the natural axis — but
        // up/down should not be dead keys on a one-row list.
        if (dx !== 0) root.moveCursor(dx)
        else if (dy !== 0) root.moveCursor(dy)
      }
      onActivateRequested: root.activateCursor()
      onReturnRequested: root.activateCursor()
      onTextKey: function(t) { root.activateNumber(t) }

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(10)

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.slots.length === 0
            ? "No scratchpads"
            : "Scratchpads · press 1–9 or ← →"
          color: Color.foreground
          opacity: 0.6
          font.family: root.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: root.slots.length === 0
          textFormat: Text.PlainText
          text: "Send a window to one with Super+Alt+S, or declare a slot in shell.json."
          color: Color.foreground
          opacity: 0.45
          font.family: root.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.Wrap
        }

        // Every capture lives under here, so closing the deck destroys the
        // lot. Nothing is captured while the panel is shut.
        Loader {
          active: root.opened && root.slots.length > 0
          visible: active
          width: parent.width
          height: active ? root.previewHeight + Style.space(34) : 0

          sourceComponent: Row {
            spacing: Style.space(10)

            Repeater {
              model: root.slots

              delegate: Item {
                id: card
                required property var modelData
                required property int index

                readonly property var slot: card.modelData
                readonly property var firstWindow: slot.windows.length > 0 ? slot.windows[0] : null
                readonly property bool selected: root.cursorActive && root.cursorIndex === card.index
                readonly property bool showing: slot.n === root.visibleSlot

                width: root.cardWidth
                height: root.previewHeight + Style.space(34)

                Rectangle {
                  id: frame
                  anchors.fill: parent
                  radius: Style.cornerRadius
                  color: card.selected ? Style.hoverFill : Style.normalFill
                  border.width: card.selected || card.showing ? Style.selectedBorderWidth : Style.normalBorderWidth
                  border.color: card.showing ? Color.accent
                    : card.selected ? Style.selectedBorderColor : Style.normalBorderColor

                  Behavior on color { ColorAnimation { duration: 120 } }
                  Behavior on border.color { ColorAnimation { duration: 120 } }
                }

                Item {
                  id: previewBox
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.margins: Style.space(6)
                  height: root.previewHeight
                  clip: true

                  // The live window capture. `live` follows the panel so the
                  // preview animates while you are looking at it and stops the
                  // moment you are not.
                  ScreencopyView {
                    id: capture
                    anchors.centerIn: parent
                    visible: card.firstWindow !== null && hasContent
                    captureSource: card.firstWindow && card.firstWindow.toplevel
                      ? card.firstWindow.toplevel.wayland : null
                    live: root.opened
                    paintCursor: false

                    // Letterbox rather than stretch: a portrait terminal and a
                    // landscape browser both have to look like themselves.
                    //
                    // This has to go through constraintSize. ScreencopyView
                    // drives its own implicit size from the C++ side, so
                    // binding implicitWidth/implicitHeight here does not
                    // letterbox the capture — it gets overwritten, and with
                    // constraintSize left at its (-1, -1) default the view
                    // ends up with a negative size and paints nothing.
                    //
                    // Reading sourceSize is deliberate: a scratchpad window is
                    // resized by the compositor the first time it is shown, and
                    // without a dependency on the source dimensions the fit is
                    // only computed once. The stale capture then paints at
                    // native size and gets cropped by the card.
                    constraintSize: {
                      const _ = capture.sourceSize
                      return Qt.size(previewBox.width, previewBox.height)
                    }
                  }

                  // Shown while a capture has not arrived yet, and for a
                  // declared slot with nothing running in it.
                  Column {
                    anchors.centerIn: parent
                    spacing: Style.space(6)
                    visible: !capture.visible

                    Image {
                      anchors.horizontalCenter: parent.horizontalCenter
                      width: Style.space(32)
                      height: Style.space(32)
                      fillMode: Image.PreserveAspectFit
                      visible: source != ""
                      source: {
                        var appId = card.firstWindow ? card.firstWindow.appId : ""
                        // An empty declared slot has no window, so fall back to
                        // the command it would launch. Strip any leading path
                        // and take the binary, not its arguments.
                        if (appId === "" && card.slot.command !== "") {
                          var bin = String(card.slot.command).trim().split(/\s+/)[0]
                          appId = bin.split("/").pop()
                        }
                        return root.iconFor(appId)
                      }
                    }

                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      textFormat: Text.PlainText
                      // On a declared slot the card is a launcher, so name the
                      // action rather than the state: "empty" tells you what
                      // you can already see.
                      text: card.slot.occupied ? "…"
                        : card.slot.command !== "" ? "launch" : "empty"
                      color: Color.foreground
                      opacity: 0.45
                      font.family: root.family
                      font.pixelSize: Style.font.caption
                    }
                  }
                }

                // Slot number badge, top-left over the preview.
                Rectangle {
                  anchors.top: previewBox.top
                  anchors.left: previewBox.left
                  anchors.margins: Style.space(4)
                  width: Style.space(18)
                  height: Style.space(18)
                  radius: height / 2
                  color: card.showing ? Color.accent : Qt.rgba(0, 0, 0, 0.6)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: String(card.slot.n)
                    color: card.showing ? Color.popups.background : "white"
                    font.family: root.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }

                // A slot holding more than one window says so, rather than
                // silently previewing only the first.
                Rectangle {
                  visible: card.slot.count > 1
                  anchors.top: previewBox.top
                  anchors.right: previewBox.right
                  anchors.margins: Style.space(4)
                  width: extra.implicitWidth + Style.space(8)
                  height: Style.space(18)
                  radius: height / 2
                  color: Qt.rgba(0, 0, 0, 0.6)

                  Text {
                    id: extra
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "+" + (card.slot.count - 1)
                    color: "white"
                    font.family: root.family
                    font.pixelSize: Style.font.caption
                  }
                }

                Text {
                  anchors.top: previewBox.bottom
                  anchors.topMargin: Style.space(6)
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.margins: Style.space(8)
                  textFormat: Text.PlainText
                  text: card.slot.name
                  color: Color.foreground
                  opacity: card.slot.occupied ? 0.9 : 0.5
                  font.family: root.family
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: { root.cursorActive = true; root.cursorIndex = card.index }
                  onClicked: root.activate(card.slot)
                }
              }
            }
          }
        }
      }
    }
  }
}
