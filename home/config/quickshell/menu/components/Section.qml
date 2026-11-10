import QtQuick
import qs

Rectangle {
    default property alias content: col.data
    property int pad: 16
    width: parent ? parent.width : 0
    implicitHeight: col.implicitHeight + pad * 2
    radius: 10
    color: "transparent"
    border.color: Style.line
    Column { id: col; x: pad; y: pad; width: parent.width - pad * 2; spacing: 12 }
}
