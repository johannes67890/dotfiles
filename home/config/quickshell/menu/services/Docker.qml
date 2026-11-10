pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var containers: [] // docker ps JSON objects
    property string error: ""

    Process {
        id: proc
        command: ["docker", "ps", "-a", "--format", "{{json .}}"]
        stdout: StdioCollector {
            onStreamFinished: root.containers = text.trim() ? text.trim().split("\n").map(l => JSON.parse(l)) : []
        }
        stderr: StdioCollector {
            onStreamFinished: root.error = text.includes("permission denied")
                ? "NO ACCESS TO DOCKER: LOG OUT AND BACK IN AFTER THE REBUILD (docker group)"
                : text.trim().toUpperCase()
        }
    }
    function refresh() { proc.running = true }
    function act(verb, id) {
        Quickshell.execDetached(["docker", verb, id])
        later.restart()
    }
    Timer { id: later; interval: 1500; onTriggered: root.refresh() }
}
