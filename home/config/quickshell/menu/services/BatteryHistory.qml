pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Battery % over the last 24 h from UPower's own history (it records it anyway), in 15-minute slots.
Singleton {
    id: root
    readonly property int slots: 96
    property var values: []      // one % per slot, oldest first; empty slots before the first record are left out
    property real updated: 0

    Process {
        id: proc
        command: ["sh", "-c", `
            dev=$(busctl --system --json=short call org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower EnumerateDevices \\
                | jq -r '.data[0][] | select(test("/battery_"))' | head -1)
            [ -n "$dev" ] && busctl --system --json=short call org.freedesktop.UPower "$dev" org.freedesktop.UPower.Device GetHistory suu charge 86400 400
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let points = []
                try { points = JSON.parse(text).data[0].filter(p => p[2] !== 0 && p[1] > 0).sort((a, b) => a[0] - b[0]) } catch (e) {}
                const now = Date.now() / 1000, size = 86400 / root.slots
                const out = []
                let i = 0, last = null
                for (let s = 0; s < root.slots; s++) {
                    const end = now - 86400 + (s + 1) * size
                    while (i < points.length && points[i][0] <= end) last = points[i++][1]
                    if (last !== null) out.push(last)
                }
                root.values = out
                root.updated = Date.now()
            }
        }
    }
    function refresh() { if (!proc.running && Date.now() - updated > 60000) proc.running = true }
}
