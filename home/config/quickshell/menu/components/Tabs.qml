import QtQuick

// Row of pills; `current` is the selected tab id.
Row {
    id: tabs
    property var model: [] // [{ id, label }]
    property string current: model.length ? model[0].id : ""
    spacing: 6
    Repeater {
        model: tabs.model
        Pill {
            required property var modelData
            label: modelData.label
            textSize: 10
            padding: 20
            implicitHeight: 26
            active: tabs.current === modelData.id
            onClicked: tabs.current = modelData.id
        }
    }
}
