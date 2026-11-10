import QtQuick
import qs

// The one text field: menu styling, Tab focus, and the menu's Alt / Ctrl keys still work while typing
// (a plain TextInput would take Alt+1 and type "1").
TextInput {
    property string placeholder
    activeFocusOnTab: true
    clip: true
    selectByMouse: true
    color: Style.fg
    selectionColor: Style.line
    font.family: Style.font
    font.pixelSize: 12
    Keys.onPressed: event => { if (Menu.navKey(event)) event.accepted = true }
    Label { visible: !parent.text; anchors.verticalCenter: parent.verticalCenter; text: parent.placeholder }
}
