import QtQuick
import qs

Item {
    property real value: 0
    implicitHeight: 4
    Rectangle { anchors.fill: parent; radius: 2; color: Style.line }
    Rectangle { width: parent.width * Math.max(0, Math.min(1, parent.value)); height: parent.height; radius: 2; color: Style.dim }
}
