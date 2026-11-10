import QtQuick
import qs
import qs.components
import qs.services

Column {
    spacing: 14
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: Docker.refresh() }

    Title { text: "DOCKER" }
    Label { visible: !!Docker.error; width: parent.width; text: Docker.error; wrapMode: Text.Wrap }
    Label { visible: !Docker.error && Docker.containers.length === 0; text: "NO CONTAINERS" }
    ListView {
        width: parent.width
        height: Math.min(contentHeight, 440)
        clip: true
        spacing: 6
        model: Docker.containers
        delegate: Rectangle {
            required property var modelData
            readonly property bool up: modelData.State === "running"
            width: ListView.view.width; height: 54; radius: 10
            color: "transparent"; border.color: Style.line
            Rectangle { x: 14; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: parent.up ? Style.fg : Style.line }
            Value { x: 34; y: 10; width: parent.width - 160; text: parent.modelData.Names }
            Label { x: 34; y: 30; width: parent.width - 160; text: (parent.modelData.Image + " · " + parent.modelData.Status).toUpperCase(); font.pixelSize: 9 }
            Pill {
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                width: 90
                label: parent.up ? "STOP" : "START"
                onClicked: Docker.act(parent.up ? "stop" : "start", parent.modelData.ID)
            }
        }
    }
}
