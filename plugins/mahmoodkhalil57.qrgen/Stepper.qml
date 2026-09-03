import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Label, then minus / reading / plus.
//
// A slider is the wrong control for a small integer that has a right answer:
// it is hard to land on exactly 4, and — because a slider takes wheel events
// to change its value — scrolling a panel that contains one drags the setting
// instead of the view. A stepper has neither problem, and the arrow keys work
// on it once it has focus.
RowLayout {
  id: root

  property string label: ""
  property int value: 0
  property int minimum: 0
  property int maximum: 16
  property int step: 1
  property string suffix: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  readonly property bool canDecrease: value > minimum
  readonly property bool canIncrease: value < maximum

  signal changed(int value)

  function nudge(delta) {
    var next = Math.max(root.minimum, Math.min(root.maximum, root.value + delta * root.step))
    if (next !== root.value) root.changed(next)
  }

  spacing: Style.space(8)

  Text {
    text: root.label
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
    Layout.fillWidth: true
  }

  RowLayout {
    spacing: Style.space(4)
    Layout.alignment: Qt.AlignVCenter

    PanelActionButton {
      iconText: "\uf068"
      enabled: root.canDecrease
      opacity: root.canDecrease ? 1 : 0.35
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Math.round(Style.font.caption * 0.85)
      bordered: true
      onClicked: root.nudge(-1)
    }

    // Fixed width so the row does not shuffle as the number changes width.
    Text {
      text: root.value + (root.suffix !== "" ? " " + root.suffix : "")
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignHCenter
      Layout.preferredWidth: Style.space(76)
      Layout.alignment: Qt.AlignVCenter
    }

    PanelActionButton {
      iconText: "\uf067"
      enabled: root.canIncrease
      opacity: root.canIncrease ? 1 : 0.35
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Math.round(Style.font.caption * 0.85)
      bordered: true
      onClicked: root.nudge(1)
    }
  }
}
