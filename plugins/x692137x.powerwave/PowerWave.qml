import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

Item {
    id: root

    // Theme-adaptive wave color matching Omarchy theme accent
    property color waveColor: {
        if (typeof Color !== "undefined" && Color.accent) {
            return Color.accent
        }
        return "#00E5FF"
    }

    function auraColor(alpha) {
        return Qt.rgba(root.waveColor.r, root.waveColor.g, root.waveColor.b, alpha)
    }

    property int durationMs: 790

    property int coreSize: 9
    property int headSize: 18

    property int trailCount: 52
    property real trailSpacing: 7.2

    property int glowInner: 18
    property int glowMid: 30
    property int glowOuter: 46

    property int cornerBloomSize: 84

    // Softer perimeter aura
    property int perimeterDepth: 36
    property int perimeterBlurMax: 12

    property bool initialized: false
    property bool isCharging: false
    property real lastTriggerTime: 0
    property int triggerSerial: 0

    function triggerAnimation(source) {
        var now = Date.now()
        // Prevent rapid duplicate triggers within 1500ms
        if (now - root.lastTriggerTime < 1500) {
            console.log("[PowerWave] Debouncing trigger from", source)
            return
        }
        root.lastTriggerTime = now
        root.triggerSerial++
        console.log("[PowerWave] Charging animation triggered! Source:", source, "Serial:", root.triggerSerial)
    }

    function onChargingStarted(source) {
        if (!root.isCharging) {
            root.isCharging = true
            root.triggerAnimation(source)
        }
    }

    function onChargingStopped(source) {
        if (root.isCharging) {
            root.isCharging = false
            console.log("[PowerWave] Charging stopped (Source:", source, ")")
        }
    }

    function forceTriggerAnimation() {
        root.lastTriggerTime = Date.now()
        root.triggerSerial++
        console.log("[PowerWave] Force triggered via IPC! Serial:", root.triggerSerial)
    }

    // Real-time kernel uevent & sysfs monitor
    Process {
        id: powerMonitor
        command: [
            "python3", "-u",
            Qt.resolvedUrl("scripts/power-monitor.py").toString().replace(/^file:\/\//, "")
        ]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                var text = line.trim()
                if (text === "STATE:CHARGING") {
                    root.isCharging = true
                    root.initialized = true
                    console.log("[PowerWave] Initial state: charging")
                } else if (text === "STATE:DISCHARGING") {
                    root.isCharging = false
                    root.initialized = true
                    console.log("[PowerWave] Initial state: discharging")
                } else if (text === "CHARGING") {
                    root.onChargingStarted("power-monitor")
                } else if (text === "DISCHARGING") {
                    root.onChargingStopped("power-monitor")
                }
            }
        }
        onExited: function(exitCode, exitStatus) {
            console.log("[PowerWave] power-monitor exited, restarting...")
            monitorRestartTimer.restart()
        }
    }

    Timer {
        id: monitorRestartTimer
        interval: 1000
        repeat: false
        onTriggered: {
            powerMonitor.running = true
        }
    }

    // Redundant UPower connections
    Connections {
        target: UPower.displayDevice
        function onStateChanged() {
            if (!root.initialized) return
            if (UPower.displayDevice.state === UPowerDeviceState.Charging) {
                root.onChargingStarted("upower.displayDevice")
            } else if (UPower.displayDevice.state === UPowerDeviceState.Discharging) {
                root.onChargingStopped("upower.displayDevice")
            }
        }
    }

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            if (!root.initialized) return
            if (UPower.onBattery === false) {
                root.onChargingStarted("upower.onBattery")
            } else if (UPower.onBattery === true) {
                root.onChargingStopped("upower.onBattery")
            }
        }
    }

    // Safety fallback timer: verifies state periodically
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging) {
                if (!root.isCharging) {
                    root.onChargingStarted("timer-sync")
                }
            }
        }
    }

    // IPC interface for testing and manual triggering
    IpcHandler {
        target: "x692137x.powerwave"
        function trigger(): string {
            root.forceTriggerAnimation()
            return "triggered"
        }
        function status(): string {
            return root.isCharging ? "charging" : "discharging"
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: overlay

                required property var modelData
                screen: modelData

                WlrLayershell.namespace: "powerwave"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                mask: Region {}

                // Only visible when active so the layer surface unmaps when animation completes
                visible: active

                property bool active: false
                property real progress: 0.0

                readonly property real halfW: width / 2
                readonly property real halfPathLength: width + height

                function clamp(v, lo, hi) {
                    return Math.max(lo, Math.min(hi, v))
                }

                function motion(t) {
                    if (t < 0.07) {
                        const u = t / 0.07
                        return 0.07 * (1 - Math.pow(1 - u, 2.5))
                    }

                    if (t < 0.96)
                        return t

                    const u = (t - 0.96) / 0.04
                    return 0.96 + 0.04 * (1 - Math.pow(1 - u, 1.7))
                }

                function headDistance() {
                    return motion(progress) * halfPathLength
                }

                function rightPoint(distance, inset) {
                    if (distance <= halfW)
                        return Qt.point(halfW + distance, height - inset)

                    distance -= halfW

                    if (distance <= height)
                        return Qt.point(width - inset, height - distance)

                    distance -= height
                    return Qt.point(width - distance, inset)
                }

                function leftPoint(distance, inset) {
                    if (distance <= halfW)
                        return Qt.point(halfW - distance, height - inset)

                    distance -= halfW

                    if (distance <= height)
                        return Qt.point(inset, height - distance)

                    distance -= height
                    return Qt.point(distance, inset)
                }

                function distanceForTrail(index) {
                    return headDistance() - index * root.trailSpacing
                }

                function trailStrength(index) {
                    const t = index / Math.max(1, root.trailCount - 1)

                    if (t < 0.12)
                        return 1.0 - 0.10 * (t / 0.12)

                    if (t < 0.60) {
                        const u = (t - 0.12) / 0.48
                        return 0.90 - 0.64 * u
                    }

                    const u = (t - 0.60) / 0.40
                    return 0.26 * Math.pow(1 - u, 1.45)
                }

                function frameEnvelope() {
                    if (progress < 0.12)
                        return progress / 0.12

                    if (progress < 0.82)
                        return 1.0

                    return Math.max(0, 1.0 - (progress - 0.82) / 0.18)
                }

                readonly property real cornerProgress:
                    halfW / Math.max(1, halfPathLength)

                function cornerEnvelope() {
                    const p = motion(progress)
                    const c = cornerProgress
                    const range = 0.06
                    const d = Math.abs(p - c)

                    if (d >= range)
                        return 0

                    return Math.pow(1 - d / range, 1.65)
                }

                // Visual content container: only visible when active
                Item {
                    id: visualRoot
                    anchors.fill: parent
                    visible: overlay.active
                    opacity: overlay.active ? 1.0 : 0.0

                    // ============================================================
                    // SUBTLE BLURRED GRADIENT PERIMETER (THEME-ADAPTIVE)
                    // ============================================================

                    Rectangle {
                        id: topAuraSource
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: root.perimeterDepth
                        opacity: 0.26 * overlay.frameEnvelope()

                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.00; color: root.auraColor(0.53) }
                            GradientStop { position: 0.16; color: root.auraColor(0.28) }
                            GradientStop { position: 0.42; color: root.auraColor(0.11) }
                            GradientStop { position: 0.72; color: root.auraColor(0.03) }
                            GradientStop { position: 1.00; color: root.auraColor(0.00) }
                        }
                    }

                    MultiEffect {
                        source: topAuraSource
                        anchors.fill: topAuraSource
                        visible: overlay.active
                        opacity: 0.62 * overlay.frameEnvelope()
                        blurEnabled: true
                        blur: 0.58
                        blurMax: root.perimeterBlurMax
                        blurMultiplier: 1.0
                        autoPaddingEnabled: false
                    }

                    Rectangle {
                        id: bottomAuraSource
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: root.perimeterDepth
                        opacity: 0.26 * overlay.frameEnvelope()

                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.00; color: root.auraColor(0.00) }
                            GradientStop { position: 0.28; color: root.auraColor(0.03) }
                            GradientStop { position: 0.58; color: root.auraColor(0.11) }
                            GradientStop { position: 0.84; color: root.auraColor(0.28) }
                            GradientStop { position: 1.00; color: root.auraColor(0.53) }
                        }
                    }

                    MultiEffect {
                        source: bottomAuraSource
                        anchors.fill: bottomAuraSource
                        visible: overlay.active
                        opacity: 0.62 * overlay.frameEnvelope()
                        blurEnabled: true
                        blur: 0.58
                        blurMax: root.perimeterBlurMax
                        blurMultiplier: 1.0
                        autoPaddingEnabled: false
                    }

                    Rectangle {
                        id: leftAuraSource
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: root.perimeterDepth
                        opacity: 0.26 * overlay.frameEnvelope()

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.00; color: root.auraColor(0.53) }
                            GradientStop { position: 0.16; color: root.auraColor(0.28) }
                            GradientStop { position: 0.42; color: root.auraColor(0.11) }
                            GradientStop { position: 0.72; color: root.auraColor(0.03) }
                            GradientStop { position: 1.00; color: root.auraColor(0.00) }
                        }
                    }

                    MultiEffect {
                        source: leftAuraSource
                        anchors.fill: leftAuraSource
                        visible: overlay.active
                        opacity: 0.62 * overlay.frameEnvelope()
                        blurEnabled: true
                        blur: 0.58
                        blurMax: root.perimeterBlurMax
                        blurMultiplier: 1.0
                        autoPaddingEnabled: false
                    }

                    Rectangle {
                        id: rightAuraSource
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: root.perimeterDepth
                        opacity: 0.26 * overlay.frameEnvelope()

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.00; color: root.auraColor(0.00) }
                            GradientStop { position: 0.28; color: root.auraColor(0.03) }
                            GradientStop { position: 0.58; color: root.auraColor(0.11) }
                            GradientStop { position: 0.84; color: root.auraColor(0.28) }
                            GradientStop { position: 1.00; color: root.auraColor(0.53) }
                        }
                    }

                    MultiEffect {
                        source: rightAuraSource
                        anchors.fill: rightAuraSource
                        visible: overlay.active
                        opacity: 0.62 * overlay.frameEnvelope()
                        blurEnabled: true
                        blur: 0.58
                        blurMax: root.perimeterBlurMax
                        blurMultiplier: 1.0
                        autoPaddingEnabled: false
                    }

                    component EnergyTrail: Item {
                        required property bool rightSide
                        required property int bodySize
                        required property real bodyOpacity
                        required property real headBias

                        anchors.fill: parent

                        Repeater {
                            model: root.trailCount

                            Rectangle {
                                required property int index

                                readonly property real d: overlay.distanceForTrail(index)
                                readonly property real strength: overlay.trailStrength(index)
                                readonly property point pos: rightSide
                                    ? overlay.rightPoint(
                                        overlay.clamp(d, 0, overlay.halfPathLength),
                                        bodySize / 2
                                      )
                                    : overlay.leftPoint(
                                        overlay.clamp(d, 0, overlay.halfPathLength),
                                        bodySize / 2
                                      )

                                readonly property real nearHead:
                                    Math.max(0, 1 - index / 8.0)

                                width: Math.max(
                                    root.coreSize,
                                    bodySize * (0.70 + 0.20 * strength + headBias * nearHead)
                                )
                                height: width

                                x: Math.round(pos.x - width / 2)
                                y: Math.round(pos.y - height / 2)

                                color: root.waveColor
                                opacity: (
                                    d >= 0 &&
                                    d <= overlay.halfPathLength
                                ) ? bodyOpacity * strength : 0

                                antialiasing: false
                            }
                        }
                    }

                    EnergyTrail {
                        rightSide: true
                        bodySize: root.glowOuter
                        bodyOpacity: 0.075
                        headBias: 0.12
                    }

                    EnergyTrail {
                        rightSide: false
                        bodySize: root.glowOuter
                        bodyOpacity: 0.075
                        headBias: 0.12
                    }

                    EnergyTrail {
                        rightSide: true
                        bodySize: root.glowMid
                        bodyOpacity: 0.16
                        headBias: 0.10
                    }

                    EnergyTrail {
                        rightSide: false
                        bodySize: root.glowMid
                        bodyOpacity: 0.16
                        headBias: 0.10
                    }

                    EnergyTrail {
                        rightSide: true
                        bodySize: root.glowInner
                        bodyOpacity: 0.34
                        headBias: 0.08
                    }

                    EnergyTrail {
                        rightSide: false
                        bodySize: root.glowInner
                        bodyOpacity: 0.34
                        headBias: 0.08
                    }

                    EnergyTrail {
                        rightSide: true
                        bodySize: root.coreSize
                        bodyOpacity: 1.0
                        headBias: 0.0
                    }

                    EnergyTrail {
                        rightSide: false
                        bodySize: root.coreSize
                        bodyOpacity: 1.0
                        headBias: 0.0
                    }

                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index

                            readonly property real d:
                                overlay.headDistance() - index * 5.2
                            readonly property point pos:
                                overlay.rightPoint(
                                    overlay.clamp(d, 0, overlay.halfPathLength),
                                    root.headSize / 2
                                )

                            width: root.headSize - index * 3
                            height: width
                            x: Math.round(pos.x - width / 2)
                            y: Math.round(pos.y - height / 2)
                            color: root.waveColor
                            opacity: d >= 0 && d <= overlay.halfPathLength
                                ? 0.95 - index * 0.17
                                : 0
                            antialiasing: false
                        }
                    }

                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index

                            readonly property real d:
                                overlay.headDistance() - index * 5.2
                            readonly property point pos:
                                overlay.leftPoint(
                                    overlay.clamp(d, 0, overlay.halfPathLength),
                                    root.headSize / 2
                                )

                            width: root.headSize - index * 3
                            height: width
                            x: Math.round(pos.x - width / 2)
                            y: Math.round(pos.y - height / 2)
                            color: root.waveColor
                            opacity: d >= 0 && d <= overlay.halfPathLength
                                ? 0.95 - index * 0.17
                                : 0
                            antialiasing: false
                        }
                    }

                    // Bottom-center injection pulse
                    Rectangle {
                        readonly property real local:
                            Math.min(1.0, overlay.progress / 0.085)

                        width: 110 + 150 * local
                        height: 25 - 9 * local
                        x: Math.round((overlay.width - width) / 2)
                        y: overlay.height - height

                        color: root.waveColor
                        opacity: overlay.progress < 0.085
                            ? 0.58 * (1.0 - local)
                            : 0
                    }

                    // Corner blooms
                    Rectangle {
                        readonly property real e: overlay.cornerEnvelope()
                        width: root.cornerBloomSize
                        height: root.cornerBloomSize
                        x: 0
                        y: overlay.height - height
                        color: root.waveColor
                        opacity: 0.11 * e
                    }

                    Rectangle {
                        readonly property real e: overlay.cornerEnvelope()
                        width: root.cornerBloomSize
                        height: root.cornerBloomSize
                        x: overlay.width - width
                        y: overlay.height - height
                        color: root.waveColor
                        opacity: 0.11 * e
                    }

                    // Top convergence bloom
                    Rectangle {
                        readonly property real local:
                            overlay.progress < 0.955
                            ? 0
                            : (overlay.progress - 0.955) / 0.045

                        width: 54 - 28 * local
                        height: 18 - 7 * local
                        x: Math.round((overlay.width - width) / 2)
                        y: 0

                        color: root.waveColor
                        opacity: overlay.progress < 0.955
                            ? 0
                            : (local < 0.32
                                ? 0.95 * (local / 0.32)
                                : 0.95 * (1 - (local - 0.32) / 0.68))
                    }
                }

                NumberAnimation {
                    id: waveAnimation
                    target: overlay
                    property: "progress"
                    from: 0.0
                    to: 1.0
                    duration: root.durationMs
                    easing.type: Easing.Linear

                    onFinished: {
                        overlay.progress = 0.0
                        overlay.active = false
                    }
                }

                Connections {
                    target: root

                    function onTriggerSerialChanged() {
                        waveAnimation.stop()
                        overlay.progress = 0.0
                        overlay.active = true
                        waveAnimation.restart()
                    }
                }
            }
        }
    }
}
