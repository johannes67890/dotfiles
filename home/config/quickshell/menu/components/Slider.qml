import QtQuick
import qs

// 0..1 slider; emits moved() while dragging or on h/l / arrow keys, the owner writes the value back.
Item {
    id: slider
    property real value: 0
    signal moved(real value)
    implicitHeight: 20
    activeFocusOnTab: true

    function step(d) { moved(Math.max(0, Math.min(1, value + d))) }
    Keys.onLeftPressed: step(-0.05)
    Keys.onRightPressed: step(0.05)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_H) { step(-0.05); event.accepted = true }
        else if (event.key === Qt.Key_L) { step(0.05); event.accepted = true }
    }

    Bar { anchors.verticalCenter: parent.verticalCenter; width: parent.width; value: slider.value }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: (parent.width - width) * Math.max(0, Math.min(1, slider.value))
        width: 14; height: 14; radius: 7; color: Style.fg
        border.width: slider.activeFocus ? 3 : 0
        border.color: Style.dim
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(mx) { slider.forceActiveFocus(); slider.moved(Math.max(0, Math.min(1, mx / width))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => set(mouse.x)
    }
}
