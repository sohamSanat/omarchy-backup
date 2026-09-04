import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "kenny.nightlight"

  readonly property var nightlightService: bar && bar.shell ? bar.shell.serviceFor("kenny.nightlight") : null
  readonly property bool nightActive: nightlightService ? nightlightService.enabled : false
  readonly property int currentTemp: nightlightService ? nightlightService.displayTemperature : 0
  readonly property string statusLine: nightlightService ? nightlightService.statusText : ""

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function toggleNightlight() {
    if (nightlightService) nightlightService.toggle()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰔎"
    dimmed: !root.nightActive
    tooltipText: root.opened ? "" : (
      (root.currentTemp ? root.currentTemp + "K · " : "") + (root.statusLine || "Night Light")
    )

    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleNightlight()
      else root.togglePanel()
    }
  }
}
