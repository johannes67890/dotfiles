import QtQuick
import qs
import qs.services

// Public IP with VPN state; the real IP (last seen off the VPN) only on request.
Column {
    id: ip
    property bool reveal: false
    width: parent ? parent.width : 0
    spacing: 8
    Row {
        spacing: 10
        Icon { code: Vpn.name ? 0xF05E0 : 0xF0159; anchors.verticalCenter: parent.verticalCenter } // md-check-circle / md-close-circle
        Value { text: Vpn.name ? "IP HIDDEN BY VPN · " + Vpn.name : "NOT PROTECTED · NO VPN"; font.pixelSize: 13 }
    }
    KeyValue { key: Vpn.name ? "VISIBLE IP (VPN)" : "PUBLIC IP"; value: Vpn.publicIp || "CHECKING…" }
    KeyValue {
        visible: !!Vpn.name
        key: "ORIGINAL IP"
        value: !ip.reveal ? "HIDDEN" : Settings.realIp
            ? Settings.realIp + " · SEEN " + Style.ago((Date.now() - Settings.realIpSeen) / 1000).toUpperCase() + " AGO"
            : "NOT SEEN YET (CHECKED WHILE OFF THE VPN)"
    }
    Pill { visible: !!Vpn.name; label: ip.reveal ? "HIDE ORIGINAL IP" : "SHOW ORIGINAL IP"; onClicked: ip.reveal = !ip.reveal }
}
