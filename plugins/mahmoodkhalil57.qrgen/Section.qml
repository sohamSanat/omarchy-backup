import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// A disclosure: a title row that toggles, and content laid out only while it
// is open. A collapsed section costs its header and nothing else, which is
// what keeps a panel with this many options usable inside a bar dropdown.
ColumnLayout {
  id: root

  property string title: ""
  // The owner keeps the state and binds it in. A section that flipped its own
  // `expanded` would overwrite that binding on the first click, and stored
  // state would stop reaching it from then on.
  property bool expanded: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal toggleRequested()

  default property alias content: body.data

  spacing: Style.space(10)

  Item {
    Layout.fillWidth: true
    implicitHeight: header.implicitHeight + Style.space(10)

    RowLayout {
      id: header
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(8)

      // Chevron right when shut, down when open — the direction says which way
      // the content will move, which is the convention everything else uses.
      Text {
        text: root.expanded ? "\uf078" : "\uf054"
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Math.round(Style.font.caption * 0.8)
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        text: root.title
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        Layout.fillWidth: true
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggleRequested()
    }
  }

  ColumnLayout {
    id: body
    visible: root.expanded
    spacing: Style.space(12)
    Layout.fillWidth: true
    Layout.bottomMargin: root.expanded ? Style.space(4) : 0
  }
}
