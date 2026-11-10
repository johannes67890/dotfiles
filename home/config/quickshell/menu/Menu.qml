pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool showing: false
    property string page: "home"
    property string tab: "" // requested tab on pages that have tabs (System, Claude)
    property string search: "" // text for Home's search box, set over IPC

    // Sidebar order; Alt+1..9, Alt+0 cover the first ten. Session sits apart at the bottom.
    readonly property var pages: [
        { id: "home", code: 0xF02DC },
        { id: "claude", code: 0xF0B79 },
        { id: "media", code: 0xF075A },
        { id: "activity", code: 0xF01EE },
        { id: "network", code: 0xF05A9 },
        { id: "bluetooth", code: 0xF00AF },
        { id: "audio", code: 0xF057E },
        { id: "system", code: 0xF035B },
        { id: "power", code: 0xF0079 },
        { id: "docker", code: 0xF0868 },
        { id: "nix", code: 0xF1105 }
    ]

    function toggle() {
        if (!showing) page = "home" // reopen on the search bar
        showing = !showing
    }
    function step(d) {
        const ids = pages.map(p => p.id).concat("session")
        page = ids[(ids.indexOf(page) + d + ids.length) % ids.length]
    }
    // Page keys while the menu is open: Alt+1..9, Alt+0 and Ctrl+(Shift+)Tab. Returns true when handled.
    // Handled as key events because QML Shortcuts never fire in the layer-shell overlay.
    function navKey(event) {
        if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            const i = (event.key - Qt.Key_0 + 9) % 10 // 1 -> first page, 0 -> tenth
            if (pages[i]) page = pages[i].id
            return true
        }
        if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            step(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1)
            return true
        }
        return false
    }
    function run(cmd) {
        showing = false
        Quickshell.execDetached(cmd)
    }
}
