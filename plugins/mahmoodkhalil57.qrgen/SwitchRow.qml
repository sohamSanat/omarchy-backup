import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Label on the left, switch on the right. The panel has enough of these that
// spelling the row out at every call site would bury the options among the
// scaffolding.
RowLayout {
  id: root

  property string label: ""
  property bool checked: false
  property bool enabled: true
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal toggled(bool checked)

  spacing: Style.space(8)

  Text {
    text: root.label
    color: root.foreground
    opacity: root.enabled ? 1 : 0.45
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
    Layout.fillWidth: true
  }

  ToggleSwitch {
    checked: root.checked
    interactive: root.enabled
    opacity: root.enabled ? 1 : 0.45
    foreground: root.foreground
    Layout.alignment: Qt.AlignVCenter
    onToggled: root.toggled(!root.checked)
  }
}
