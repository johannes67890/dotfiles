import QtQuick

Clickable {
    id: btn
    property int code
    property int size: 40
    width: size; height: size; radius: 10
    Icon { anchors.centerIn: parent; code: btn.code; font.pixelSize: btn.size * 0.4 }
}
