import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.components

Column {
    id: page
    spacing: 14
    // Hardware devices (not app streams): sinks are outputs, the rest inputs.
    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    PwObjectTracker { objects: page.devices }

    function label(n) { return n ? (n.description || n.nickname || n.name) : "" }

    component Device: Section {
        id: dev
        property string title
        property var current            // the default device
        property var list
        signal pick(var node)
        readonly property var audio: current?.audio ?? null
        Row {
            width: parent.width
            Label { width: parent.width - mute.width; text: dev.title + (dev.current ? " · " + page.label(dev.current).toUpperCase() : " · NONE"); anchors.verticalCenter: parent.verticalCenter }
            Pill { id: mute; visible: !!dev.audio; label: dev.audio?.muted ? "MUTED" : "MUTE"; active: dev.audio?.muted ?? false; onClicked: dev.audio.muted = !dev.audio.muted }
        }
        Row {
            visible: !!dev.audio
            width: parent.width
            spacing: 12
            Slider { width: parent.width - 52; value: Math.min(1, dev.audio?.volume ?? 0); onMoved: v => dev.audio.volume = v }
            Value { width: 40; horizontalAlignment: Text.AlignRight; text: Math.round(Math.min(1, dev.audio?.volume ?? 0) * 100) + "%"; font.pixelSize: 11 }
        }
        Label { text: "DEVICES"; font.pixelSize: 9 }
        ListView {
            width: parent.width
            height: Math.min(contentHeight, 136)
            clip: true
            spacing: 2
            model: dev.list
            delegate: Clickable {
                required property var modelData
                required property int index
                width: ListView.view.width; height: 32; radius: 8
                active: modelData === dev.current
                onClicked: dev.pick(modelData)
                onActiveFocusChanged: if (activeFocus) ListView.view.positionViewAtIndex(index, ListView.Contain)
                Value { x: 12; width: parent.width - 100; anchors.verticalCenter: parent.verticalCenter; text: page.label(parent.modelData); font.pixelSize: 11 }
                Label {
                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 9
                    text: (parent.modelData.audio?.muted ? "MUTED · " : "") + (parent.active ? "IN USE" : "USE")
                }
            }
        }
    }

    Title { text: "AUDIO" }
    Device {
        title: "OUTPUT"
        current: Pipewire.defaultAudioSink
        list: page.devices.filter(n => n.isSink)
        onPick: node => Pipewire.preferredDefaultAudioSink = node
    }
    Device {
        title: "INPUT"
        current: Pipewire.defaultAudioSource
        list: page.devices.filter(n => !n.isSink)
        onPick: node => Pipewire.preferredDefaultAudioSource = node
    }
}
