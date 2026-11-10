import QtQuick
import qs

// Plain text only: these show mail subjects and Wi-Fi/Bluetooth names, and rich text would load images.
Text {
    textFormat: Text.PlainText
    color: Style.dim
    font.family: Style.font
    font.pixelSize: 11
    font.letterSpacing: 2
    elide: Text.ElideRight
}
