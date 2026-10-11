import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "soham.hogreaper"
  ipcTarget: "soham.hogreaper"

  readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFam: root.bar ? root.bar.fontFamily : Style.font.family

  property real ramUsedPercent: 0
  property int ramUsedMb: 0
  property int ramTotalMb: 0
  property int ramAvailableMb: 0
  property real swapUsedPercent: 0
  property int swapUsedMb: 0
  property int swapTotalMb: 0
  property real psiMem: 0.0
  property real psiCpu: 0.0
  property string activeApp: ""
  property int activePid: 0
  property bool daemonActive: true
  property bool reaping: false
  property bool justKilled: false
  property string lastKillOutput: ""

  function refresh() {
    if (!statusProc.running) {
      statusProc.running = true
    }
  }

  function runKillHogs() {
    if (!killHogsProc.running) {
      root.reaping = true
      killHogsProc.running = true
    }
  }

  function openTop() {
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run("ghostty -e hogreaper top")
    } else {
      topProc.running = true
    }
    root.close()
  }

  function openConfig() {
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run("ghostty -e nvim " + (Quickshell.env("HOME") || "/home/soham") + "/.config/hogreaper/config.toml")
    } else {
      configProc.running = true
    }
    root.close()
  }

  function restartDaemon() {
    if (!restartProc.running) {
      restartProc.running = true
    }
  }

  onOpenedChanged: {
    if (opened) {
      refresh()
    }
  }

  Component.onCompleted: {
    refresh()
  }

  // Rapid refresh while panel is opened (snappy UI)
  Timer {
    interval: 1500
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  // Periodic low-frequency background poll (<2ms execution time)
  Timer {
    interval: 3500
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: feedbackTimer
    interval: 6000
    repeat: false
    onTriggered: {
      root.justKilled = false
    }
  }

  // ------------------------------------------------------------- Processes

  Process {
    id: statusProc
    command: ["hogreaper", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          if (!text || text.trim() === "") return
          var data = JSON.parse(text)
          root.ramUsedPercent = data.ram_used_percent || 0
          root.ramUsedMb = data.ram_used_mb || 0
          root.ramTotalMb = data.ram_total_mb || 0
          root.ramAvailableMb = data.ram_available_mb || 0
          root.swapUsedPercent = data.swap_used_percent || 0
          root.swapUsedMb = data.swap_used_mb || 0
          root.swapTotalMb = data.swap_total_mb || 0
          root.psiMem = data.psi_memory_avg10 || 0.0
          root.psiCpu = data.psi_cpu_avg10 || 0.0
          root.activeApp = data.active_app || "none"
          root.activePid = data.active_pid || 0
          root.daemonActive = data.daemon_active === true
        } catch (e) {
          // Ignore transient JSON parse errors
        }
      }
    }
  }

  Process {
    id: killHogsProc
    command: ["hogreaper", "kill-hogs"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.reaping = false
        var cleaned = text.trim()
        if (cleaned.length > 0) {
          root.lastKillOutput = cleaned
          root.justKilled = true
          feedbackTimer.restart()
        }
        root.refresh()
      }
    }
    onExited: {
      root.reaping = false
      root.refresh()
    }
  }

  Process {
    id: topProc
    command: ["ghostty", "-e", "hogreaper", "top"]
  }

  Process {
    id: configProc
    command: ["ghostty", "-e", "nvim", (Quickshell.env("HOME") || "/home/soham") + "/.config/hogreaper/config.toml"]
  }

  Process {
    id: restartProc
    command: ["hogreaper", "service", "restart"]
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
    text: "\uf0e7"
    slotSize: Style.bar.iconSlot
    active: root.opened || root.ramUsedPercent >= 85.0 || root.psiMem >= 20.0
    dimmed: !root.daemonActive
    tooltipText: ""

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        root.runKillHogs()
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
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // 1. Header Row
        Row {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "HOGREAPER GOVERNOR"
            foreground: root.fg
            fontFamily: root.fontFam
            anchors.verticalCenter: parent.verticalCenter
          }

          Item {
            width: Math.max(Style.space(8), parent.width - (parent.children[0].implicitWidth + parent.children[2].implicitWidth + Style.space(8)))
            height: 1
            anchors.verticalCenter: parent.verticalCenter
          }

          Button {
            id: daemonBadge
            text: root.daemonActive ? "Running" : "Stopped"
            iconText: root.daemonActive ? "󰄬" : "󰅚"
            fontSize: Style.font.caption
            foreground: root.daemonActive ? Color.accent : Color.urgent
            fontFamily: root.fontFam
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(4)
            bordered: true
            active: root.daemonActive
            anchors.verticalCenter: parent.verticalCenter
            tooltipText: "Daemon service status. Click to restart."
            onClicked: root.restartDaemon()
          }
        }

        PanelSeparator {
          foreground: root.fg
        }

        // 2. RAM Memory Gauge
        Column {
          width: parent.width
          spacing: Style.space(4)

          Row {
            width: parent.width
            Text {
              text: "RAM " + Math.round(root.ramUsedPercent) + "%"
              color: root.fg
              font.family: root.fontFam
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Item {
              width: Math.max(Style.space(8), parent.width - (parent.children[0].implicitWidth + parent.children[2].implicitWidth))
              height: 1
            }

            Text {
              text: (root.ramUsedMb / 1024).toFixed(1) + " / " + (root.ramTotalMb / 1024).toFixed(1) + " GB (" + (root.ramAvailableMb / 1024).toFixed(1) + " GB free)"
              color: root.fg
              opacity: 0.7
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Item {
            width: parent.width
            height: Style.space(8)

            Rectangle {
              id: ramTrack
              anchors.fill: parent
              radius: height / 2
              color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
            }

            Rectangle {
              id: ramFill
              anchors.left: ramTrack.left
              anchors.top: ramTrack.top
              anchors.bottom: ramTrack.bottom
              radius: ramTrack.radius
              width: Math.max(height, ramTrack.width * (root.ramUsedPercent / 100.0))
              color: root.ramUsedPercent >= 85 ? Color.urgent : Color.accent

              Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
              Behavior on color { ColorAnimation { duration: 200 } }
            }
          }
        }

        // 3. Swap Gauge (if swap exists)
        Column {
          visible: root.swapTotalMb > 0
          width: parent.width
          spacing: Style.space(4)

          Row {
            width: parent.width
            Text {
              text: "SWAP " + Math.round(root.swapUsedPercent) + "%"
              color: root.fg
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Item {
              width: Math.max(Style.space(8), parent.width - (parent.children[0].implicitWidth + parent.children[2].implicitWidth))
              height: 1
            }

            Text {
              text: root.swapUsedMb + " MB / " + (root.swapTotalMb / 1024).toFixed(1) + " GB"
              color: root.fg
              opacity: 0.65
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Item {
            width: parent.width
            height: Style.space(6)

            Rectangle {
              id: swapTrack
              anchors.fill: parent
              radius: height / 2
              color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
            }

            Rectangle {
              anchors.left: swapTrack.left
              anchors.top: swapTrack.top
              anchors.bottom: swapTrack.bottom
              radius: swapTrack.radius
              width: Math.max(height, swapTrack.width * (root.swapUsedPercent / 100.0))
              color: root.swapUsedPercent >= 70 ? Color.urgent : Color.accent

              Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }
          }
        }

        // 4. Linux Kernel PSI Pressure Stall Row
        Row {
          width: parent.width
          spacing: Style.space(8)

          Rectangle {
            width: (parent.width - Style.space(8)) / 2
            height: Style.space(52)
            radius: Style.cornerRadius
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)
            border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
            border.width: 1

            Column {
              anchors.centerIn: parent
              spacing: Style.space(2)
              Text {
                text: "PSI MEM STALL"
                font.bold: true
                font.pixelSize: Style.font.caption
                font.family: root.fontFam
                color: root.fg
                opacity: 0.65
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                text: root.psiMem.toFixed(1) + "%"
                font.bold: true
                font.pixelSize: Style.font.body
                font.family: root.fontFam
                color: root.psiMem > 15.0 ? Color.urgent : (root.psiMem > 5.0 ? Color.accent : root.fg)
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }

          Rectangle {
            width: (parent.width - Style.space(8)) / 2
            height: Style.space(52)
            radius: Style.cornerRadius
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)
            border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
            border.width: 1

            Column {
              anchors.centerIn: parent
              spacing: Style.space(2)
              Text {
                text: "PSI CPU STALL"
                font.bold: true
                font.pixelSize: Style.font.caption
                font.family: root.fontFam
                color: root.fg
                opacity: 0.65
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                text: root.psiCpu.toFixed(1) + "%"
                font.bold: true
                font.pixelSize: Style.font.body
                font.family: root.fontFam
                color: root.psiCpu > 25.0 ? Color.urgent : (root.psiCpu > 10.0 ? Color.accent : root.fg)
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
        }

        // 5. Protected Foreground Window Card
        Rectangle {
          width: parent.width
          height: Style.space(48)
          radius: Style.cornerRadius
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)
          border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
          border.width: 1

          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space(12)
            anchors.rightMargin: Style.space(12)
            spacing: Style.space(10)

            Text {
              text: "󰖲"
              font.pixelSize: Style.font.title
              font.family: root.fontFam
              color: Color.accent
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(1)
              Text {
                text: "SHIELDED ACTIVE APP"
                font.bold: true
                font.pixelSize: Style.font.caption
                font.family: root.fontFam
                color: root.fg
                opacity: 0.65
              }
              Text {
                text: (root.activeApp && root.activeApp !== "none" ? root.activeApp : "No focused window") + (root.activePid > 0 ? " (PID " + root.activePid + ")" : "")
                font.bold: true
                font.pixelSize: Style.font.bodySmall
                font.family: root.fontFam
                color: Color.accent
                elide: Text.ElideRight
                width: Style.space(280)
              }
            }
          }
        }

        // 6. Kill Output Feedback Banner (if active)
        Rectangle {
          visible: root.justKilled && root.lastKillOutput !== ""
          width: parent.width
          height: feedbackCol.implicitHeight + Style.space(16)
          radius: Style.cornerRadius
          color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)
          border.color: Color.accent
          border.width: 1

          Column {
            id: feedbackCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Style.space(8)
            spacing: Style.space(2)

            Text {
              text: "󰄬 Reaper Mitigation Pass Complete"
              font.bold: true
              font.pixelSize: Style.font.caption
              font.family: root.fontFam
              color: Color.accent
            }
            Text {
              width: parent.width
              text: root.lastKillOutput
              font.pixelSize: Style.font.caption
              font.family: root.fontFam
              color: root.fg
              wrapMode: Text.Wrap
            }
          }
        }

        PanelSeparator {
          foreground: root.fg
        }

        // 7. Primary Action: Instant Reap Button
        Button {
          width: parent.width
          text: root.reaping ? "Scanning & Reaping..." : "Reap Background Hogs Now"
          iconText: root.reaping ? "󱍛" : "\uf0e7"
          fontSize: Style.font.body
          fontFamily: root.fontFam
          foreground: Color.accent
          horizontalPadding: Style.space(12)
          verticalPadding: Style.space(8)
          bordered: true
          active: true
          tooltipText: "Instantly scan and kill idle runaway memory hogs"
          onClicked: root.runKillHogs()
        }

        // 8. Secondary Row: Dashboard, Config, Restart
        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: (parent.width - Style.space(16)) / 3
            text: "Top"
            iconText: "󰮄"
            fontSize: Style.font.caption
            fontFamily: root.fontFam
            foreground: root.fg
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(6)
            bordered: true
            tooltipText: "Open live interactive Top dashboard"
            onClicked: root.openTop()
          }

          Button {
            width: (parent.width - Style.space(16)) / 3
            text: "Config"
            iconText: "󰒓"
            fontSize: Style.font.caption
            fontFamily: root.fontFam
            foreground: root.fg
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(6)
            bordered: true
            tooltipText: "Edit HogReaper configuration file"
            onClicked: root.openConfig()
          }

          Button {
            width: (parent.width - Style.space(16)) / 3
            text: "Restart"
            iconText: "󰑐"
            fontSize: Style.font.caption
            fontFamily: root.fontFam
            foreground: root.fg
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(6)
            bordered: true
            tooltipText: "Restart background daemon service"
            onClicked: root.restartDaemon()
          }
        }
      }
    }
  }
}
