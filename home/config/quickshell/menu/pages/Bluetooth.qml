import QtQuick
import Quickshell.Bluetooth
import qs
import qs.components

Column {
    id: page
    spacing: 14
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices.values
    readonly property var mine: devices.filter(d => d.paired || d.connected).sort((a, b) => b.connected - a.connected)
    readonly property var nearby: devices.filter(d => !d.paired && !d.connected && d.deviceName)
        .sort((a, b) => a.deviceName.localeCompare(b.deviceName))
    property var pairingWith: null

    // Scan while the page is open.
    Binding { target: page.adapter; property: "discovering"; value: true; when: !!page.adapter && page.adapter.enabled }
    // A freshly paired device is trusted (so it reconnects by itself) and connected.
    Connections {
        target: page.pairingWith
        function onPairedChanged() {
            if (!page.pairingWith?.paired) return
            page.pairingWith.trusted = true
            page.pairingWith.connect()
            page.pairingWith = null
        }
    }

    function glyph(d) {
        const i = d.icon ?? ""
        if (/headset|headphone/.test(i)) return 0xF02CB   // md-headphones
        if (/audio|speaker/.test(i)) return 0xF04C3       // md-speaker
        if (/phone/.test(i)) return 0xF011C               // md-cellphone
        if (/keyboard/.test(i)) return 0xF030C            // md-keyboard
        if (/mouse/.test(i)) return 0xF037D               // md-mouse
        if (/gaming|joystick/.test(i)) return 0xF0297     // md-gamepad-variant
        return 0xF00AF                                    // md-bluetooth
    }

    component DeviceRow: Row {
        id: row
        property var device
        property string status
        default property alias buttons: actions.data
        width: parent ? parent.width : 0
        height: 36
        spacing: 10
        Icon { code: page.glyph(row.device); anchors.verticalCenter: parent.verticalCenter; width: 22 }
        Column {
            width: parent.width - 22 - actions.width - 20
            anchors.verticalCenter: parent.verticalCenter
            Value { width: parent.width; text: row.device.deviceName || row.device.name || row.device.address }
            Label { width: parent.width; text: row.status; font.pixelSize: 9 }
        }
        Row { id: actions; spacing: 6; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
        width: parent.width
        Title { width: parent.width - power.width; text: "BLUETOOTH" + (page.adapter?.discovering ? " · SCANNING…" : ""); anchors.verticalCenter: parent.verticalCenter }
        OnOff { id: power; visible: !!page.adapter; on: page.adapter?.enabled ?? false; onToggled: value => page.adapter.enabled = value }
    }
    Label { visible: !page.adapter; text: "NO BLUETOOTH ADAPTER" }

    Section {
        visible: page.adapter?.enabled ?? false
        Label { text: "MY DEVICES" + (page.mine.length ? "" : " · NONE PAIRED") }
        Repeater {
            model: page.mine
            DeviceRow {
                required property var modelData
                device: modelData
                status: (modelData.connected ? "CONNECTED" : "PAIRED")
                    + (modelData.batteryAvailable ? " · BATTERY " + Math.round(modelData.battery * 100) + "%" : "")
                Pill {
                    label: parent.parent.device.connected ? "DISCONNECT" : "CONNECT"
                    textSize: 9; padding: 16; implicitHeight: 26
                    onClicked: parent.parent.device.connected ? parent.parent.device.disconnect() : parent.parent.device.connect()
                }
                Pill { label: "FORGET"; textSize: 9; padding: 16; implicitHeight: 26; onClicked: parent.parent.device.forget() }
            }
        }
    }

    Section {
        visible: page.adapter?.enabled ?? false
        Label { text: "AVAILABLE" + (page.nearby.length ? " · " + page.nearby.length : " · SEARCHING…") }
        ListView {
            width: parent.width
            height: Math.min(contentHeight, 230)
            clip: true
            spacing: 4
            model: page.nearby
            delegate: DeviceRow {
                required property var modelData
                device: modelData
                status: modelData.pairing ? "PAIRING…" : modelData.address
                Pill {
                    label: parent.parent.device.pairing ? "CANCEL" : "PAIR"
                    textSize: 9; padding: 16; implicitHeight: 26
                    onClicked: {
                        const d = parent.parent.device
                        if (d.pairing) { d.cancelPair(); page.pairingWith = null }
                        else { page.pairingWith = d; d.pair() }
                    }
                }
            }
        }
    }
}
