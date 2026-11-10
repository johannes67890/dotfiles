import QtQuick
import qs

// Plain text only: these show mail subjects and Wi-Fi/Bluetooth names, and rich text would load images.
Text {
    textFormat: Text.PlainText
    color: Style.fg
    font.family: Style.font
    font.pixelSize: 12
    elide: Text.ElideRight
}
