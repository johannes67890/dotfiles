import QtQuick
import Quickshell.Networking
import qs
import qs.components
import qs.services

Column {
    id: page
    spacing: 14
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: (wifi?.networks.values ?? [])
        .filter(n => n.name)
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    property var asking: null // network waiting for a password
    property string failed: ""

    Binding { target: page.wifi; property: "scannerEnabled"; value: true; when: !!page.wifi }

    function pick(n) {
        failed = ""
        if (n.connected) return
        if (n.known || n.security === WifiSecurityType.Open) { n.connect(); asking = null }
        else asking = n
    }

    Title { text: "NETWORK" }
    Section {
        Row {
            width: parent.width
            Label { width: parent.width - onoff.width; text: "WI-FI"; anchors.verticalCenter: parent.verticalCenter }
            OnOff { id: onoff; on: Networking.wifiEnabled; onToggled: value => Networking.wifiEnabled = value }
        }
        ListView {
            visible: Networking.wifiEnabled
            width: parent.width
            height: Math.min(contentHeight, 220)
            clip: true
            spacing: 2
            model: page.networks
            delegate: Clickable {
                id: row
                required property var modelData
                required property int index
                width: ListView.view.width; height: 34; radius: 8
                active: modelData.connected
                onClicked: page.pick(modelData)
                onActiveFocusChanged: if (activeFocus) ListView.view.positionViewAtIndex(index, ListView.Contain)
                Label {
                    x: 10; width: 40; anchors.verticalCenter: parent.verticalCenter
                    readonly property real s: parent.modelData.signalStrength
                    text: Math.round(s > 1 ? s : s * 100) + "%"
                }
                Value { x: 56; width: parent.width - 170; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.name }
                Label {
                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    text: parent.modelData.connected ? "CONNECTED" : parent.modelData.stateChanging ? "CONNECTING…"
                        : parent.modelData.known ? "SAVED" : parent.modelData.security === WifiSecurityType.Open ? "OPEN" : Style.icon(0xF033E)
                }
                Connections { target: row.modelData; function onConnectionFailed(reason) { page.failed = "COULD NOT CONNECT TO " + row.modelData.name.toUpperCase() } }
            }
        }
        Row {
            visible: !!page.asking
            width: parent.width
            spacing: 10
            Rectangle {
                width: parent.width - join.width - 10; height: 30; radius: 8
                color: "transparent"; border.color: pw.activeFocus ? Style.lineActive : Style.line
                Field {
                    id: pw
                    x: 10; width: parent.width - 20; anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    focus: !!page.asking
                    placeholder: "PASSWORD FOR " + (page.asking?.name ?? "").toUpperCase()
                    onAccepted: join.clicked()
                }
            }
            Pill { id: join; label: "JOIN"; onClicked: { page.asking.connectWithPsk(pw.text); pw.text = ""; page.asking = null } }
        }
        Label { visible: !!page.failed; text: page.failed }
    }

    Section {
        Label { text: "VPN · PROTON" }
        IpStatus {}
        Label { text: "KILL SWITCH · " + (Vpn.killSwitch ? "ON" : "OFF") }
        Row {
            spacing: 10
            Pill { visible: !!Vpn.name; label: "DISCONNECT"; onClicked: Vpn.disconnect() }
            Pill { label: "OPEN PROTON VPN"; onClicked: Menu.run(["protonvpn-app"]) }
        }
    }
}
