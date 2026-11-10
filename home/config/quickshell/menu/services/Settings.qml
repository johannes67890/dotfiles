pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Choices that survive restarts, kept outside the repo in ~/.local/state/quickshell-menu/settings.json.
Singleton {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/.local/state/quickshell-menu"
    property alias claudeModel: data.claudeModel     // "" = Claude Code's default
    property alias realIp: data.realIp               // last public IP seen without the VPN
    property alias realIpSeen: data.realIpSeen       // ms since epoch

    Process { running: true; command: ["mkdir", "-p", root.dir]; onExited: file.reload() }
    FileView {
        id: file
        path: root.dir + "/settings.json"
        blockLoading: true // values are ready as soon as this exists
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }
        JsonAdapter {
            id: data
            property string claudeModel: ""
            property string realIp: ""
            property real realIpSeen: 0
        }
    }
}
