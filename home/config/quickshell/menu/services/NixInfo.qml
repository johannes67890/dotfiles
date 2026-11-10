pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int generation: 0
    property int generations: 0
    property real built: 0            // ms since epoch
    property var inputs: []           // [{ name, modified (ms) }]
    property real garbageBytes: -1    // -1 = not calculated
    property int garbagePaths: 0
    property real garbageAt: 0
    property bool calculating: false

    Process {
        id: gens
        command: ["sh", "-c", `
            cur=$(readlink /nix/var/nix/profiles/system); cur=\${cur#system-}; echo "\${cur%-link}"
            stat -c %Y /nix/var/nix/profiles/$(readlink /nix/var/nix/profiles/system)
            ls -d /nix/var/nix/profiles/system-*-link | wc -l
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")
                root.generation = Number(f[0])
                root.built = Number(f[1]) * 1000
                root.generations = Number(f[2])
            }
        }
    }
    FileView {
        id: lock
        path: Quickshell.env("HOME") + "/dotfiles/flake.lock"
        onLoaded: {
            const j = JSON.parse(text())
            root.inputs = Object.entries(j.nodes[j.root].inputs)
                .map(([name, key]) => ({ name: name, modified: (j.nodes[key]?.locked?.lastModified ?? 0) * 1000 }))
                .sort((a, b) => a.modified - b.modified)
        }
    }
    // Store paths nothing references anymore, i.e. what plain `nix-collect-garbage` frees.
    Process {
        id: garbage
        command: ["sh", "-c", `
            dead=$(nix-store --gc --print-dead 2>/dev/null)
            printf '%s\\n' "$dead" | grep -c .
            printf '%s\\n' "$dead" | grep . | tr '\\n' '\\0' | du -scb --files0-from=- 2>/dev/null | tail -1 | cut -f1
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")
                root.garbagePaths = Number(f[0])
                root.garbageBytes = Number(f[1] || 0)
                root.garbageAt = Date.now()
                root.calculating = false
            }
        }
    }

    function refresh() { gens.running = true; lock.reload() }
    function calculate() { calculating = true; garbage.running = true }
}
