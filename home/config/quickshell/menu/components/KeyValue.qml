import QtQuick
import qs

// One "LABEL ........ value" row; the value is right-aligned and the label gives way first.
Row {
    property string key
    property string value
    width: parent ? parent.width : 0
    Label { width: parent.width - val.width; text: parent.key; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
    Value { id: val; text: parent.value; font.pixelSize: 11 }
}
