import QtQuick
import qs

Clickable {
    property string label
    property int textSize: 11
    property int padding: 32
    implicitHeight: 30
    implicitWidth: text.implicitWidth + padding
    radius: 8
    idleBorder: Style.line

    Text {
        id: text
        anchors.centerIn: parent
        text: parent.label
        color: Style.fg
        font.family: Style.font
        font.pixelSize: parent.textSize
        font.letterSpacing: 2
    }
}
