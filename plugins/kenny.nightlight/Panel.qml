import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "NightlightModel.js" as NightlightModel

Panel {
  id: root
  moduleName: "kenny.nightlight"
  ipcTarget: "kenny.nightlight"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property var nightlightService: bar && bar.shell ? bar.shell.serviceFor("kenny.nightlight") : null

  readonly property int currentTemp: nightlightService ? nightlightService.displayTemperature : NightlightModel.DEFAULT_DAY_TEMPERATURE
  readonly property string warmthLabel: nightlightService ? nightlightService.warmthLabel : NightlightModel.warmthName(currentTemp)
  readonly property string statusLine: nightlightService ? nightlightService.statusText : ""
  readonly property bool autoOn: nightlightService ? nightlightService.mode === "auto" && !nightlightService.paused : false
  readonly property bool paused: nightlightService ? nightlightService.paused : false
  readonly property var presetOptions: NightlightModel.PRESETS

  property string focusSection: "slider"
  property int selectedIndex: -1
  property bool cursorActive: false
  property bool sliderDragging: false

  readonly property var visibleSections: ["slider", "auto", "presets", "pause"]

  function open() {
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  IpcHandler {
    target: "kenny.nightlight"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  onOpenedChanged: if (!opened) {
    cursorActive = false
    setCenterHoverRevealSuppressed(false)
  }

  function sectionFirstIndex(section) {
    if (section === "slider" || section === "auto") return -1
    return 0
  }

  function sectionCount(section) {
    if (section === "presets") return presetOptions.length
    if (section === "pause") return 2
    return 0
  }

  function moveCursor(dx, dy) {
    if (dy !== 0) {
      var sections = visibleSections
      var sIdx = sections.indexOf(focusSection)
      if (sIdx < 0) { focusSection = sections[0]; selectedIndex = sectionFirstIndex(focusSection); return }
      if (dy > 0 && sIdx < sections.length - 1) {
        focusSection = sections[sIdx + 1]
        selectedIndex = sectionFirstIndex(focusSection)
      } else if (dy < 0 && sIdx > 0) {
        focusSection = sections[sIdx - 1]
        selectedIndex = sectionFirstIndex(focusSection)
      }
      return
    }
    if (dx === 0) return
    if (focusSection === "slider") {
      nudgeSlider(dx)
      return
    }
    if (focusSection === "auto") return
    var max = sectionCount(focusSection) - 1
    if (max < 0) return
    selectedIndex = Math.max(0, Math.min(max, selectedIndex + dx))
  }

  function nudgeSlider(dx) {
    if (!nightlightService) return
    nightlightService.setManualTemperature(currentTemp + dx * 100)
  }

  function activateCursor() {
    if (focusSection === "auto") {
      toggleAuto()
      return
    }
    if (focusSection === "presets") {
      var preset = presetOptions[selectedIndex]
      if (preset && nightlightService) nightlightService.applyPreset(preset.value)
      return
    }
    if (focusSection === "pause") {
      if (selectedIndex === 0) pauseHour()
      else pauseSunrise()
    }
  }

  function toggleAuto() {
    if (!nightlightService) return
    nightlightService.setMode(autoOn ? "manual" : "auto")
  }

  function pauseHour() {
    if (nightlightService) nightlightService.pauseFor(3600)
  }

  function pauseSunrise() {
    if (nightlightService) nightlightService.pauseUntilSunrise()
  }

  function sliderMoved(v) {
    sliderDragging = true
    if (nightlightService) {
      nightlightService.applyingLive = true
      nightlightService.setManualTemperature(v)
    }
  }

  function sliderReleased(v) {
    sliderDragging = false
    if (nightlightService) {
      nightlightService.setManualTemperature(v)
      nightlightService.applyingLive = false
    }
  }

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dx, dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "a" || t === "A") root.toggleAuto()
        else if (t === "p" || t === "P") root.pauseHour()
        else if (t === "s" || t === "S") root.pauseSunrise()
      }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        PanelHero {
          width: parent.width
          title: root.warmthLabel
          meta: root.statusLine
          detail: root.currentTemp + "K"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          iconComponent: Component {
            Text {
              text: "󰔎"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.display
              opacity: root.nightlightService && root.nightlightService.enabled ? 1.0 : 0.55
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          Item {
            width: parent.width
            height: Style.space(18)

            Text {
              text: "Temperature"
              color: Qt.darker(root.contentForeground, 1.4)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: root.currentTemp + "K"
              color: Qt.darker(root.contentForeground, 1.4)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          CursorSurface {
            id: sliderRow
            width: parent.width
            height: tempSlider.implicitHeight + Style.spacing.controlGap
            hasCursor: root.cursorActive && root.focusSection === "slider"
            foreground: root.contentForeground
            outline: true

            PanelSlider {
              id: tempSlider
              bar: root.bar
              anchors.fill: parent
              anchors.leftMargin: Style.space(6)
              anchors.rightMargin: Style.space(6)
              minimum: NightlightModel.MIN_TEMPERATURE
              maximum: NightlightModel.MAX_TEMPERATURE
              step: 50
              integer: true
              value: root.currentTemp
              onMoved: function(v) { root.sliderMoved(v) }
              onReleased: function(v) { root.sliderReleased(v) }
            }

            HoverHandler {
              onHoveredChanged: if (hovered) {
                root.cursorActive = true
                root.focusSection = "slider"
                root.selectedIndex = -1
              }
            }
          }
        }

        Toggle {
          id: autoToggle
          width: parent.width
          label: "Auto schedule"
          description: root.paused ? "Paused — screen stays at daylight until then" : "Follow sunrise and sunset at this location"
          checked: root.autoOn
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          hasCursor: root.cursorActive && root.focusSection === "auto"
          onHovered: function(on) {
            if (on) {
              root.cursorActive = true
              root.focusSection = "auto"
              root.selectedIndex = -1
            }
          }
          onClicked: root.toggleAuto()
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "PRESETS"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
          }

          ButtonGroup {
            id: presetGroup
            width: parent.width
            options: root.presetOptions
            value: NightlightModel.presetForTemperature(root.currentTemp)
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            focusable: false
            cursorIndex: root.cursorActive && root.focusSection === "presets" ? Math.max(0, root.selectedIndex) : -1
            onHovered: function(index, on) {
              if (on) {
                root.cursorActive = true
                root.focusSection = "presets"
                root.selectedIndex = index
              }
            }
            onChanged: function(value) {
              if (root.nightlightService) root.nightlightService.applyPreset(value)
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "PAUSE AUTO"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            Button {
              id: pauseHourButton
              width: (parent.width - parent.spacing) / 2
              text: "1 hour"
              bordered: true
              selected: root.paused
              hasCursor: root.cursorActive && root.focusSection === "pause" && root.selectedIndex === 0
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onHovered: function(on) {
                if (on) {
                  root.cursorActive = true
                  root.focusSection = "pause"
                  root.selectedIndex = 0
                }
              }
              onClicked: root.pauseHour()
            }

            Button {
              id: pauseSunriseButton
              width: (parent.width - parent.spacing) / 2
              text: "Until sunrise"
              bordered: true
              hasCursor: root.cursorActive && root.focusSection === "pause" && root.selectedIndex === 1
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              onHovered: function(on) {
                if (on) {
                  root.cursorActive = true
                  root.focusSection = "pause"
                  root.selectedIndex = 1
                }
              }
              onClicked: root.pauseSunrise()
            }
          }
        }
      }
    }
  }
}
