import QtQuick
import qs

Text {
    property int code
    text: Style.icon(code)
    color: Style.fg
    font.family: Style.font
    font.pixelSize: 16
}
