import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property string state: "idle" // "idle", "recording", "transcribing", "success", "paused", "status"
  property string stateSource: "" // "ipc" or "voxtype"
  property int animationFrame: 0
  property var audioSamples: []
  property string customStatus: ""

  readonly property bool active: state === "recording" || state === "transcribing" || state === "success" || state === "paused" || state === "status"
  readonly property color successColor: Qt.hsla(0.33, Math.max(0.35, Color.accent.hslSaturation), Color.accent.hslLightness, 1)
  readonly property color stateColor: {
    if (state === "recording") return Color.urgent
    if (state === "success") return successColor
    if (state === "paused") return Color.warning || "#F59E0B"
    if (state === "status") return Color.warning || "#F59E0B"
    return Color.accent
  }
  readonly property string stateIcon: {
    if (state === "success") return "\uf00c"
    if (state === "paused") return "\uf04c"
    if (state === "status") return "\uf071"
    return "\uf130"
  }
  readonly property string label: {
    if (state === "recording") return "LISTENING"
    if (state === "transcribing") return "TRANSCRIBING"
    if (state === "success") return "TRANSCRIBED"
    if (state === "paused") return "PAUSED"
    if (state === "status") return root.customStatus ? root.customStatus.toUpperCase() : "STATUS"
    return ""
  }
  readonly property string focusedScreenName: Hyprland.focusedMonitor
    ? String(Hyprland.focusedMonitor.name || "") : ""
  readonly property var activeScreen: {
    for (var i = 0; i < Quickshell.screens.length; i++) {
      if (Quickshell.screens[i].name === focusedScreenName) return Quickshell.screens[i]
    }
    return Quickshell.screens.length ? Quickshell.screens[0] : null
  }

  function update(raw) {
    if (root.stateSource === "ipc" && root.active) return
    try {
      var data = JSON.parse(String(raw || "{}"))
      var nextState = String(data.alt || data.class || "idle")
      if (nextState === "recording" || nextState === "transcribing") {
        root.stateSource = "voxtype"
        if (nextState === "recording" && state !== "recording") audioSamples = []
        if (nextState === "transcribing" && state !== "transcribing") animationFrame = 0
        state = nextState
      } else if (state === "transcribing") {
        state = "success"
      } else if (state !== "success" && state !== "status" && state !== "paused") {
        state = "idle"
      }
    } catch (error) {
      if (root.stateSource !== "ipc") state = "idle"
    }
  }

  function updateAudio(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      if (state !== "recording" || typeof data.peak !== "number") return

      var next = audioSamples.slice()
      next.push(Math.max(0, Math.min(1, data.peak)))
      while (next.length > 40) next.shift()
      audioSamples = next
    } catch (error) {
    }
  }

  function barHeight(index) {
    if (state === "success" || state === "paused" || state === "status") return 5

    if (state === "recording" && audioSamples.length) {
      var sampleIndex = Math.min(audioSamples.length - 1,
        Math.floor(index * (audioSamples.length - 1) / 7))
      return 5 + Math.min(1, audioSamples[sampleIndex] * 20) * 16
    }

    if (state === "recording") {
      var phase = (animationFrame * 0.25) + (index * 0.75)
      var wave = (Math.sin(phase) + 1.0) * 0.5
      return 5 + wave * 16
    }

    var distance = Math.abs(index - (animationFrame % 15))
    distance = Math.min(distance, 15 - distance)
    return 5 + Math.max(0, 16 - distance * 5)
  }

  IpcHandler {
    id: auraIpc
    target: "io.github.adamcbrewer.voxtype-aura"

    function setListening(): string {
      root.stateSource = "ipc"
      root.state = "recording"
      root.audioSamples = []
      root.customStatus = ""
      return "ok"
    }

    function setPaused(): string {
      root.stateSource = "ipc"
      root.state = "paused"
      return "ok"
    }

    function setResumed(): string {
      root.stateSource = "ipc"
      root.state = "recording"
      return "ok"
    }

    function setTranscribing(text: string): string {
      root.stateSource = "ipc"
      root.animationFrame = 0
      root.state = "transcribing"
      root.customStatus = ""
      return "ok"
    }

    function setDone(): string {
      root.stateSource = "ipc"
      root.state = "success"
      successTimer.restart()
      return "ok"
    }

    function setStatus(text: string): string {
      root.stateSource = "ipc"
      var s = String(text || "").trim()
      if (s === "Done") {
        root.state = "success"
        successTimer.restart()
      } else if (s.length > 0) {
        root.customStatus = s
        root.state = "status"
        statusTimeout.restart()
      } else {
        root.state = "idle"
      }
      return "ok"
    }

    function hide(): string {
      root.state = "idle"
      root.stateSource = ""
      return "ok"
    }
  }

  IpcHandler {
    target: "voxtype-aura"

    function setListening(): string { return auraIpc.setListening() }
    function setPaused(): string { return auraIpc.setPaused() }
    function setResumed(): string { return auraIpc.setResumed() }
    function setTranscribing(text: string): string { return auraIpc.setTranscribing(text) }
    function setDone(): string { return auraIpc.setDone() }
    function setStatus(text: string): string { return auraIpc.setStatus(text) }
    function hide(): string { return auraIpc.hide() }
  }

  Process {
    id: statusProcess

    command: ["omarchy-voxtype-status"]
    running: true
    stdout: SplitParser {
      onRead: function(data) { root.update(data) }
    }
    onExited: function() {
      if (root.stateSource !== "ipc") {
        root.state = "idle"
      }
      statusRetry.restart()
    }
  }

  Process {
    id: audioBridge

    command: ["voxtype-audio-bridge"]
    running: true
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) { root.updateAudio(data) }
    }
    onExited: function() {
      audioRetry.restart()
    }
  }

  Timer {
    id: audioRetry

    interval: 1000
    onTriggered: audioBridge.running = true
  }

  Timer {
    id: statusRetry

    interval: 1000
    onTriggered: statusProcess.running = true
  }

  Timer {
    interval: 60
    repeat: true
    running: root.state === "transcribing" || (root.state === "recording" && root.audioSamples.length === 0)
    onTriggered: root.animationFrame = (root.animationFrame + 1) % 120
  }

  Timer {
    id: successTimer
    interval: 1300
    running: root.state === "success"
    onTriggered: {
      root.state = "idle"
      root.stateSource = ""
    }
  }

  Timer {
    id: statusTimeout
    interval: 1800
    running: root.state === "status"
    onTriggered: {
      root.state = "idle"
      root.stateSource = ""
    }
  }

  PanelWindow {
    id: surface

    screen: root.activeScreen
    visible: root.active && root.activeScreen !== null
    implicitWidth: 340
    implicitHeight: 76
    anchors.top: true
    margins.top: Style.gapsOut
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "voxtype-aura"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      id: glowSource

      visible: false
      width: 312
      height: 50
      anchors.centerIn: parent
      radius: Math.min(height / 2, Style.cornerRadius)
      color: root.stateColor
    }

    MultiEffect {
      anchors.fill: glowSource
      source: glowSource
      autoPaddingEnabled: true
      blurEnabled: true
      blur: 0.9
      blurMax: 18
      blurMultiplier: 1
      opacity: 0.42
      scale: 1.02
    }

    Rectangle {
      width: 312
      height: 50
      anchors.centerIn: parent
      radius: Math.min(height / 2, Style.cornerRadius)
      color: Util.alpha(Color.background, 0.94)
      border.width: 1
      border.color: root.stateColor

      Row {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 16

        Text {
          width: 24
          height: parent.height
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          text: root.stateIcon
          color: root.stateColor
          font.family: Style.font.family
          font.pixelSize: 20
          renderType: Text.NativeRendering
        }

        Item {
          width: 80
          height: parent.height

          Row {
            anchors.centerIn: parent
            spacing: 5

            Repeater {
              model: 8

              Rectangle {
                required property int index

                width: 3
                height: root.barHeight(index)
                anchors.verticalCenter: parent.verticalCenter
                radius: 1.5
                color: root.stateColor

                Behavior on height {
                  NumberAnimation { duration: 85; easing.type: Easing.OutCubic }
                }
              }
            }
          }
        }

        Text {
          width: 136
          height: parent.height
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignRight
          text: root.label
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.weight: Font.Medium
          font.letterSpacing: 1.2
          elide: Text.ElideRight
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
