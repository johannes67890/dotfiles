pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Proton VPN shows up in NetworkManager as a WireGuard connection while connected.
Singleton {
    id: root
    property string name: ""           // "" = not connected
    property bool killSwitch: false
    property bool known: false         // nmcli answered at least once
    property string publicIp: ""
    property string ipFor: "-"         // VPN state (name) the current publicIp was looked up under
    property real ipChecked: 0

    // ipify sees the address it is asked from; saved as the real IP only if the VPN was off before and after.
    function lookupIp() {
        const before = name
        ipFor = before
        ipChecked = Date.now()
        const xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api.ipify.org")
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (root.name !== before) return // VPN changed while asking; the next poll asks again
            if (xhr.status !== 200) { root.publicIp = "UNAVAILABLE"; return } // offline, or the kill switch blocks it
            const ip = xhr.responseText.trim()
            root.publicIp = ip
            if (!before) { Settings.realIp = ip; Settings.realIpSeen = Date.now() }
        }
        xhr.send()
    }

    Process {
        id: proc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                let vpn = "", ks = false
                for (const line of text.trim().split("\n")) {
                    const i = line.lastIndexOf(":")
                    const n = line.slice(0, i).replace(/\\:/g, ":"), type = line.slice(i + 1)
                    if (n.startsWith("pvpn-killswitch")) ks = true
                    else if (type === "wireguard" || type === "vpn") vpn = n
                }
                root.name = vpn
                root.killSwitch = ks
                root.known = true
                if (vpn !== root.ipFor) root.publicIp = ""
                if (vpn !== root.ipFor || Date.now() - root.ipChecked > 10 * 60 * 1000) root.lookupIp()
            }
        }
    }
    function refresh() { proc.running = true }
    function disconnect() {
        Quickshell.execDetached(["nmcli", "connection", "down", name])
        name = ""
    }

    Timer { interval: 5000; running: Menu.showing; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
