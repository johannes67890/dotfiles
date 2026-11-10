import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

Column {
    spacing: 14
    Component.onCompleted: NixInfo.refresh()

    Title { text: "NIXOS" }
    Section {
        Row {
            spacing: 28
            Column { Label { text: "GENERATION" } Value { text: NixInfo.generation; font.pixelSize: 20 } }
            Column { Label { text: "BUILT" } Value { text: Style.ago((Date.now() - NixInfo.built) / 1000) + " ago"; font.pixelSize: 20 } }
            Column { Label { text: "GENERATIONS KEPT" } Value { text: NixInfo.generations; font.pixelSize: 20 } }
        }
    }
    Section {
        Label { text: "FLAKE INPUTS · LAST UPDATED" }
        Grid {
            columns: 2
            columnSpacing: 30
            rowSpacing: 6
            Repeater {
                model: NixInfo.inputs
                Row {
                    required property var modelData
                    spacing: 10
                    Value { width: 150; text: parent.modelData.name; font.pixelSize: 11 }
                    Label { text: Style.ago((Date.now() - parent.modelData.modified) / 1000).toUpperCase() + " AGO" }
                }
            }
        }
    }
    Section {
        Label { text: "GARBAGE" }
        Value {
            width: parent.width
            wrapMode: Text.Wrap
            text: NixInfo.calculating ? "Calculating…"
                : NixInfo.garbageBytes < 0 ? "Not calculated yet."
                : Style.bytes(NixInfo.garbageBytes) + " in " + NixInfo.garbagePaths + " unused store paths can be freed by nix-collect-garbage"
                  + " (checked " + Qt.formatTime(new Date(NixInfo.garbageAt), "HH:mm") + ")."
        }
        Label {
            width: parent.width; wrapMode: Text.Wrap; font.letterSpacing: 1
            text: "THE OTHER " + Math.max(0, NixInfo.generations - 1) + " GENERATIONS KEEP MORE ALIVE: sudo nix-collect-garbage -d ALSO DELETES THEM AND FREES MORE."
        }
        Row {
            spacing: 10
            Pill { label: NixInfo.calculating ? "CALCULATING…" : "CALCULATE"; onClicked: if (!NixInfo.calculating) NixInfo.calculate() }
            Pill { label: "COPY COMMAND"; onClicked: Quickshell.execDetached(["wl-copy", "sudo nix-collect-garbage -d"]) }
        }
    }
}
