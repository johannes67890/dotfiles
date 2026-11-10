import QtQuick

Row {
    property bool on
    signal toggled(bool value)
    spacing: 10
    Pill { width: 80; label: "ON"; active: parent.on; onClicked: parent.toggled(true) }
    Pill { width: 80; label: "OFF"; active: !parent.on; onClicked: parent.toggled(false) }
}
