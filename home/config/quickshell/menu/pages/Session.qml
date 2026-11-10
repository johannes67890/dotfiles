import QtQuick
import qs
import qs.components

Column {
    id: page
    spacing: 14
    property string confirm: "" // action waiting for its second click
    Timer { id: expire; interval: 3000; onTriggered: page.confirm = "" }

    readonly property var shutdown: ["busctl", "--user", "call", "org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown"]
    readonly property var actions: [
        { id: "lock", label: "LOCK", code: 0xF033E, cmd: ["loginctl", "lock-session"] },
        { id: "sleep", label: "SLEEP", code: 0xF0904, cmd: ["systemctl", "suspend"] },
        { id: "logout", label: "LOG OUT", code: 0xF0343, cmd: shutdown.concat("logout"), ask: true },
        { id: "reboot", label: "REBOOT", code: 0xF0709, cmd: shutdown.concat("logoutAndReboot"), ask: true },
        { id: "off", label: "SHUT DOWN", code: 0xF0425, cmd: shutdown.concat("logoutAndShutdown"), ask: true }
    ]

    Title { text: "SESSION" }
    Grid {
        columns: 3
        spacing: 12
        Repeater {
            model: page.actions
            Clickable {
                required property var modelData
                readonly property bool asking: page.confirm === modelData.id
                width: (page.width - 24) / 3; height: 110; radius: 12
                active: asking
                idleBorder: Style.line
                onClicked: {
                    if (modelData.ask && page.confirm !== modelData.id) { page.confirm = modelData.id; expire.restart(); return }
                    Menu.run(modelData.cmd)
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; code: parent.parent.modelData.code; font.pixelSize: 26 }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; color: Style.fg; text: parent.parent.asking ? "CLICK AGAIN" : parent.parent.modelData.label }
                }
            }
        }
    }
}
