import QtQuick
import qs

// Base for anything clickable: mouse, Tab focus (white ring) and Enter/Space.
Rectangle {
    id: root
    property bool active: false
    property bool focusable: true
    property color idleBorder: "transparent"
    readonly property bool hovered: mouse.containsMouse
    signal clicked

    activeFocusOnTab: focusable
    color: active || hovered || activeFocus ? Style.raised : "transparent"
    border.color: activeFocus ? Style.fg : active ? Style.lineActive : idleBorder
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onSpacePressed: clicked()

    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
