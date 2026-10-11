import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "soham.hogreaper"

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
  property bool isSampling: false

  function refresh() {
    if (!statusProc.running) {
      statusProc.running = true
    }
  }

  function runKillHogs() {
    if (!killHogsProc.running) {
      killHogsProc.running = true
    }
  }

  function openTop() {
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run("ghostty -e hogreaper top")
    } else {
      openTopProc.running = true
    }
  }

  function restartDaemon() {
    if (!restartProc.running) {
      restartProc.running = true
    }
  }

  Component.onCompleted: {
    refresh()
  }

  // Periodic poll of zero-overhead hogreaper status (finishes in <2ms)
  Timer {
    interval: 2500
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

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
  }

  Process {
    id: openTopProc
    command: ["ghostty", "-e", "hogreaper", "top"]
  }

  Process {
    id: restartProc
    command: ["hogreaper", "service", "restart"]
    onExited: {
      root.refresh()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf0e7"
    slotSize: Style.bar.iconSlot
    active: root.ramUsedPercent >= 85.0 || root.psiMem >= 20.0
    dimmed: !root.daemonActive
    tooltipText: ""

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        root.runKillHogs()
      } else {
        root.openTop()
      }
    }
  }
}
