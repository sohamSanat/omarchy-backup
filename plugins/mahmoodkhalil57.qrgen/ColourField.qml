import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Label, swatch, hex. Typed input is only handed upwards once it parses, so a
// half-typed "#1f" never repaints the code mid-keystroke; the swatch is the
// confirmation that what was typed was understood.
//
// An empty value is meaningful for the eye colours — it means "inherit the
// foreground" — so blank is accepted rather than treated as a mistake.
RowLayout {
  id: root

  property string label: ""
  property string value: ""
  property string placeholder: ""
  property bool allowEmpty: false
  property color swatchFallback: Color.foreground
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal changed(string value)

  readonly property bool valid: isColour(field.text)
  // The panel's key catcher has to stand down while this is being typed in.
  readonly property bool editing: field.activeFocus

  function isColour(text) {
    var candidate = String(text || "").trim().toLowerCase()
    if (candidate === "" || candidate === "theme" || candidate === "inherit") return root.allowEmpty
    return /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(candidate)
  }

  function commit() {
    var candidate = String(field.text || "").trim()
    if (candidate.toLowerCase() === "theme" || candidate.toLowerCase() === "inherit") candidate = ""
    if (!isColour(candidate)) {
      // Put the last good value back rather than leaving something that does
      // not parse sitting in the field.
      field.text = root.value
      return
    }
    if (candidate === root.value) {
      field.text = root.value
      return
    }
    root.changed(candidate)
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

  Rectangle {
    implicitWidth: Style.space(18)
    implicitHeight: Style.space(18)
    radius: Math.min(Style.cornerRadius, Style.space(5))
    color: root.valid && field.text.trim() !== "" && /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(field.text.trim()) ? field.text.trim() : root.swatchFallback
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.25)
    Layout.alignment: Qt.AlignVCenter
  }

  TextField {
    id: field
    text: root.value
    placeholderText: root.placeholder
    foreground: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    verticalPadding: Style.space(4)
    implicitWidth: Style.space(88)
    Layout.alignment: Qt.AlignVCenter

    onEditingFinished: root.commit()
    onAccepted: root.commit()
  }

  // A value changed from elsewhere (a reset, a stored setting) has to reach the
  // field, but not while it is being typed into.
  Connections {
    target: root
    function onValueChanged() {
      if (!field.activeFocus) field.text = root.value
    }
  }
}
