pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// KDE do-not-disturb lives in plasmanotifyrc; --notify makes plasmashell pick the change up.
Singleton {
    id: root
    property bool on: false

    Process {
        id: read
        command: ["kreadconfig6", "--file", "plasmanotifyrc", "--group", "DoNotDisturb", "--key", "Until"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",").map(Number) // y,m,d,h,min,s
                root.on = f.length >= 3 && new Date(f[0], f[1] - 1, f[2], f[3] || 0, f[4] || 0) > new Date()
            }
        }
    }
    function refresh() { read.running = true }
    function set(value) {
        on = value
        Quickshell.execDetached(value
            ? ["kwriteconfig6", "--notify", "--file", "plasmanotifyrc", "--group", "DoNotDisturb", "--key", "Until", "2099,1,1,0,0,0"]
            : ["kwriteconfig6", "--notify", "--file", "plasmanotifyrc", "--group", "DoNotDisturb", "--key", "Until", "--delete"])
    }
}
