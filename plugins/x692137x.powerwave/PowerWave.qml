import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root

    property color waveColor: "#FFFFFF"

    property int durationMs: 790

    property int coreSize: 9
    property int headSize: 18

    property int trailCount: 52
    property real trailSpacing: 7.2

    property int glowInner: 18
    property int glowMid: 30
    property int glowOuter: 46

    property int cornerBloomSize: 84

    // Softer perimeter aura than v0.12.
    property int perimeterDepth: 36
    property int perimeterBlurMax: 12

    property bool initialized: false
    property bool previousOnBattery: UPower.onBattery
    property int triggerSerial: 0

    Component.onCompleted: {
        previousOnBattery = UPower.onBattery
        initialized = true
        console.log("[PowerWave] v0.13 loaded, onBattery =", UPower.onBattery)
    }

    Connections {
        target: UPower

        function onOnBatteryChanged() {
            if (!root.initialized)
                return

            if (root.previousOnBattery === true && UPower.onBattery === false) {
                root.triggerSerial++
                console.log("[PowerWave] AC connected, trigger =", root.triggerSerial)
            }

            root.previousOnBattery = UPower.onBattery
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: overlay

                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                mask: Region {}

                visible: active
                updatesEnabled: active

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
                    // Gentle fade in, stable low-level aura, gentle fade out.
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

                // ============================================================
                // SUBTLE BLURRED GRADIENT PERIMETER
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
                        GradientStop { position: 0.00; color: "#88FFFFFF" }
                        GradientStop { position: 0.16; color: "#48FFFFFF" }
                        GradientStop { position: 0.42; color: "#1CFFFFFF" }
                        GradientStop { position: 0.72; color: "#08FFFFFF" }
                        GradientStop { position: 1.00; color: "#00FFFFFF" }
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
                        GradientStop { position: 0.00; color: "#00FFFFFF" }
                        GradientStop { position: 0.28; color: "#08FFFFFF" }
                        GradientStop { position: 0.58; color: "#1CFFFFFF" }
                        GradientStop { position: 0.84; color: "#48FFFFFF" }
                        GradientStop { position: 1.00; color: "#88FFFFFF" }
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
                        GradientStop { position: 0.00; color: "#88FFFFFF" }
                        GradientStop { position: 0.16; color: "#48FFFFFF" }
                        GradientStop { position: 0.42; color: "#1CFFFFFF" }
                        GradientStop { position: 0.72; color: "#08FFFFFF" }
                        GradientStop { position: 1.00; color: "#00FFFFFF" }
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
                        GradientStop { position: 0.00; color: "#00FFFFFF" }
                        GradientStop { position: 0.28; color: "#08FFFFFF" }
                        GradientStop { position: 0.58; color: "#1CFFFFFF" }
                        GradientStop { position: 0.84; color: "#48FFFFFF" }
                        GradientStop { position: 1.00; color: "#88FFFFFF" }
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

                // Bottom-center injection remains punchy.
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

                // Corner blooms slightly softened too.
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
                        waveAnimation.start()
                    }
                }
            }
        }
    }
}
