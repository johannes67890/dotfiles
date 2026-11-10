pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs

Singleton {
    id: root
    // The playing player, else the first one (Spotify, browsers, ...).
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function time(s) {
        s = Math.max(0, Math.floor(s))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    // Mpris position is not pushed; poke it so bindings update.
    Timer {
        interval: 1000
        running: Menu.showing && (root.player?.isPlaying ?? false)
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
