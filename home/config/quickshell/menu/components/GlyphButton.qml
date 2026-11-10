import QtQuick
import qs

// A control in the style of the Spotify "text" theme: a bare glyph, dimmed until hovered or focused.
Clickable {
    id: btn
    property string glyph
    property int size: 22
    implicitWidth: Math.max(36, glyphText.implicitWidth + 14)
    implicitHeight: 36
    radius: 8
    color: "transparent"
    border.color: activeFocus ? Style.fg : "transparent"
    Text {
        id: glyphText
        anchors.centerIn: parent
        text: btn.glyph
        color: Style.fg
        opacity: btn.hovered || btn.activeFocus || btn.active ? 1 : 0.6
        font.family: Style.font
        font.pixelSize: btn.size
    }
}
