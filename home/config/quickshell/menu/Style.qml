pragma Singleton
import QtQuick
import Quickshell

// Colours match the Spotify/Vesktop themes (Ghostty's #171717 panels, dim borders).
Singleton {
    readonly property color bg: "#171717"
    readonly property color raised: "#2a2a2a"
    readonly property color line: "#333333"
    readonly property color lineActive: "#777777"
    readonly property color dim: "#999999"
    readonly property color fg: "#ffffff"
    readonly property string font: "FiraCode Nerd Font"

    function icon(code) { return String.fromCodePoint(code) }
    function bytes(n) {
        const u = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (n >= 1024 && i < u.length - 1) { n /= 1024; i++ }
        return n.toFixed(i > 1 ? 1 : 0) + " " + u[i]
    }
    function ago(seconds) {
        const d = Math.floor(seconds / 86400)
        if (d > 0) return d + (d === 1 ? " day" : " days")
        const h = Math.floor(seconds / 3600)
        return h > 0 ? h + " h" : Math.max(1, Math.floor(seconds / 60)) + " min"
    }
}
