import QtQuick
import qs.Ui

// Bar button. Toggles through the stock `omarchy.menu` id on purpose: the
// shell routes that id to whichever menu plugin is enabled (this one while
// Switchboard is on, the built-in menu otherwise), so keybinds and scripts
// never need to know which launcher is active.
BarWidget {
  id: root
  moduleName: "krall.switchboard"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    fontFamily: "omarchy"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}
