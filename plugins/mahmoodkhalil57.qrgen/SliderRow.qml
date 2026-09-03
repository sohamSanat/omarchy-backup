import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Label and current reading above, track below. PanelSlider fills whatever it
// is given rather than carrying its own height, so it needs the wrapper.
ColumnLayout {
  id: root

  property QtObject bar: null
  // The Flickable this row lives in, so a wheel over the track scrolls the
  // panel instead of dragging the value.
  property Flickable scrollTarget: null
  property string label: ""
  property string readout: ""
  property real value: 0
  property real minimum: 0
  property real maximum: 1
  property real step: 0.05
  property bool integer: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal moved(real value)
  signal released(real value)

  spacing: Style.space(4)

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.space(8)

    Text {
      text: root.label
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      Layout.fillWidth: true
    }

    Text {
      text: root.readout
      color: Qt.darker(root.foreground, 1.4)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  Item {
    Layout.fillWidth: true
    implicitHeight: Style.spacing.controlHeight

    PanelSlider {
      anchors.fill: parent
      bar: root.bar
      minimum: root.minimum
      maximum: root.maximum
      step: root.step
      integer: root.integer
      value: root.value
      onMoved: function(v) { root.moved(v) }
      onReleased: function(v) { root.released(v) }
    }

    // PanelSlider changes its value on the wheel, which turns any scroll that
    // happens to pass over the track into an edit. This sits above it and takes
    // the wheel first — accepting no buttons, so pressing and dragging the
    // slider still works — and scrolls the panel with it instead.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      onWheel: function(wheel) {
        wheel.accepted = true
        var target = root.scrollTarget
        if (!target) return
        var limit = Math.max(0, target.contentHeight - target.height)
        target.contentY = Math.max(0, Math.min(limit, target.contentY - wheel.angleDelta.y))
      }
    }
  }
}
