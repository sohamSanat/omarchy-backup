import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "soham.easyeffects"
  ipcTarget: "soham.easyeffects"

  readonly property string home: Quickshell.env("HOME") || "/home/soham"
  readonly property string pluginDir: home + "/.config/omarchy/plugins/soham.easyeffects"

  property var presets: []
  property string activePreset: ""
  property bool bypassed: false
  property string presetToPurge: ""

  function refresh() {
    if (!statusProc.running) statusProc.running = true
    if (!bypassProc.running) bypassProc.running = true
    if (!presetsProc.running) presetsProc.running = true
  }

  function setPreset(name) {
    if (!name || setPresetProc.running) return
    setPresetProc.command = ["easyeffects", "-l", name]
    setPresetProc.running = true
  }

  function purgePreset(name) {
    if (!name) return
    if (Model.isStockPreset(name)) return
    purgeProc.command = [root.pluginDir + "/purge-preset.sh", name]
    purgeProc.running = true
  }

  function toggleBypass() {
    if (toggleBypassProc.running) return
    toggleBypassProc.running = true
  }

  function openEasyEffects() {
    if (root.bar) {
      root.bar.run("easyeffects")
    }
    root.close()
  }

  onOpenedChanged: {
    if (opened) {
      refresh()
    }
  }

  Component.onCompleted: {
    refresh()
  }

  // Periodic refresh when panel is opened
  Timer {
    interval: 3000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  // Background refresh to catch external changes (e.g. CLI preset switches)
  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  // ------------------------------------------------------------- CLI Processes

  Process {
    id: statusProc
    command: ["easyeffects", "-s"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Model.parseActivePreset(text)
        if (parsed !== null) {
          root.activePreset = parsed || Model.findStockPreset(root.presets)
        }
      }
    }
  }

  Process {
    id: bypassProc
    command: ["easyeffects", "-b", "3"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.bypassed = Model.parseBypass(text)
      }
    }
  }

  Process {
    id: presetsProc
    command: ["easyeffects", "--presets"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var list = Model.parsePresetList(text)
        if (list && list.length > 0) {
          root.presets = list
          if (!root.activePreset) {
            root.activePreset = Model.findStockPreset(list)
          }
        }
      }
    }
  }

  Process {
    id: setPresetProc
    onExited: {
      root.refresh()
    }
  }

  Process {
    id: toggleBypassProc
    command: ["easyeffects", "--bypass-toggle"]
    onExited: {
      root.refresh()
    }
  }

  Process {
    id: purgeProc
    onExited: {
      root.refresh()
    }
  }

  // ------------------------------------------------------------- Bar Button

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰡏"
    slotSize: Style.bar.iconSlot
    active: root.opened
    opacity: root.bypassed ? 0.45 : 1.0
    tooltipText: root.activePreset
      ? ("EasyEffects: " + root.activePreset + (root.bypassed ? " [Bypassed]" : ""))
      : "EasyEffects"

    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.toggleBypass()
      } else {
        root.toggle()
      }
    }
  }

  // ------------------------------------------------------------- Popover Panel

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: {
        if (purgeConfirm.opened) {
          root.presetToPurge = ""
        } else {
          root.close()
        }
      }

      Keys.onPressed: function(event) {
        if (purgeConfirm.opened) {
          if (purgeConfirm.handleKey(event)) {
            event.accepted = true
            return
          }
        }
      }

      Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // Header: Title & Bypass Switch
        Row {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "EASYEFFECTS"
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : ""
            anchors.verticalCenter: parent.verticalCenter
          }

          Item {
            // Spacer to push toggle button to the right
            width: Math.max(Style.space(8), parent.width - (parent.children[0].implicitWidth + parent.children[2].implicitWidth + Style.space(8)))
            height: 1
            anchors.verticalCenter: parent.verticalCenter
          }

          Button {
            id: bypassBtn
            text: root.bypassed ? "Bypassed" : "Active"
            iconText: root.bypassed ? "󰂭" : "󰂯"
            fontSize: Style.font.caption
            foreground: root.bypassed
              ? (root.bar ? root.bar.foreground : Color.foreground)
              : Color.accent
            fontFamily: root.bar ? root.bar.fontFamily : ""
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(4)
            bordered: true
            active: !root.bypassed
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.toggleBypass()
          }
        }

        PanelSeparator {
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        // Subheader: Category label with count
        Text {
          text: root.presets.length > 0
            ? ("OUTPUT PRESETS (" + root.presets.length + ")")
            : "OUTPUT PRESETS"
          color: root.bar ? root.bar.foreground : Color.foreground
          opacity: 0.55
          font.family: root.bar ? root.bar.fontFamily : ""
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        // Scrollable Preset items list (constrained height for 40+ presets)
        Item {
          id: scrollContainer
          width: parent.width
          height: Math.min(presetColumn.implicitHeight, Style.space(260))

          Flickable {
            id: presetFlick
            anchors.fill: parent
            contentWidth: width
            contentHeight: presetColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            WheelHandler {
              target: presetFlick
              onWheel: function(event) {
                if (event.angleDelta.y === 0) return
                var step = Style.space(40)
                var delta = event.angleDelta.y > 0 ? -step : step
                presetFlick.contentY = Math.max(0, Math.min(presetFlick.contentHeight - presetFlick.height, presetFlick.contentY + delta))
              }
            }

            Column {
              id: presetColumn
              width: presetFlick.width - (presetFlick.contentHeight > presetFlick.height ? Style.space(8) : 0)
              spacing: Style.space(4)

              Repeater {
                model: root.presets

                Item {
                  required property var modelData
                  required property int index

                  readonly property bool isStock: Model.isStockPreset(modelData)
                  width: parent.width
                  implicitHeight: presetBtn.implicitHeight
                  height: implicitHeight

                  Row {
                    anchors.fill: parent
                    spacing: Style.space(4)

                    Button {
                      id: presetBtn
                      width: isStock ? parent.width : (parent.width - purgeBtn.width - parent.spacing)
                      text: String(modelData)
                      iconText: (root.activePreset === modelData) ? "✓" : " "
                      iconSize: Style.font.bodySmall
                      fontSize: Style.font.bodySmall
                      foreground: (root.activePreset === modelData)
                        ? Color.accent
                        : (root.bar ? root.bar.foreground : Color.foreground)
                      fontFamily: root.bar ? root.bar.fontFamily : ""
                      horizontalPadding: Style.space(10)
                      verticalPadding: Style.space(6)
                      bordered: true
                      active: root.activePreset === modelData

                      onClicked: {
                        root.setPreset(modelData)
                      }
                    }

                    Button {
                      id: purgeBtn
                      visible: !isStock
                      width: Style.space(32)
                      iconText: "󰆴"
                      iconSize: Style.font.bodySmall
                      fontSize: Style.font.bodySmall
                      foreground: Color.urgent
                      fontFamily: root.bar ? root.bar.fontFamily : ""
                      horizontalPadding: 0
                      verticalPadding: Style.space(6)
                      bordered: true
                      active: false
                      tooltipText: "Purge preset from system"

                      onClicked: {
                        root.presetToPurge = String(modelData)
                      }
                    }
                  }
                }
              }

              Text {
                visible: root.presets.length === 0
                text: "No presets found in EasyEffects output directory."
                color: root.bar ? root.bar.foreground : Color.foreground
                opacity: 0.6
                font.family: root.bar ? root.bar.fontFamily : ""
                font.pixelSize: Style.font.caption
              }
            }
          }

          // Native scroll bar indicator (floating above flickable)
          Rectangle {
            id: scrollIndicator
            visible: presetFlick.contentHeight > presetFlick.height
            anchors.right: parent.right
            y: presetFlick.visibleArea.yPosition * scrollContainer.height
            width: Style.space(3)
            height: Math.max(Style.space(16), presetFlick.visibleArea.heightRatio * scrollContainer.height)
            radius: width / 2
            color: root.bar ? root.bar.foreground : Color.foreground
            opacity: 0.35
            z: 10
          }
        }

        PanelSeparator {
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        // Footer: Launcher Button
        Button {
          width: parent.width
          text: "Open EasyEffects App"
          iconText: "󰝚"
          fontSize: Style.font.bodySmall
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : ""
          horizontalPadding: Style.space(10)
          verticalPadding: Style.space(6)
          bordered: false
          onClicked: root.openEasyEffects()
        }
      }

      ConfirmDialog {
        id: purgeConfirm
        anchors.fill: parent
        opened: root.presetToPurge !== ""
        z: 30
        message: "Purge preset '" + root.presetToPurge + "' and all associated AutoEQ files from the system?"
        confirmText: "Purge"
        cancelText: "Cancel"
        background: Color.popups.background
        foreground: Color.popups.text
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        onCanceled: {
          root.presetToPurge = ""
        }
        onConfirmed: {
          var target = root.presetToPurge
          root.presetToPurge = ""
          root.purgePreset(target)
        }
      }
    }
  }
}
