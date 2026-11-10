// Quick settings menu in the style of 43PR's Quickshell settings window, for KDE.
// Toggle: qs -c menu ipc call menu toggle (bound to Alt+F in kde/plasma.nix).
// Keys while open: Alt+1..9/0 pages, Ctrl+(Shift+)Tab cycle pages, Tab / j k move focus,
// h l previous / next page, Enter / Space activate, Esc close.
// Data sources live in services/; most poll only while the menu is open, SysMon samples slowly in the background.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components
import qs.services // also makes the module visible to the pages, which are loaded by path

ShellRoot {
    // Create SysMon at startup so the graphs collect history while the menu is closed.
    readonly property int sysmon: SysMon.capacity
    // Load saved settings before anything (e.g. a Claude question over IPC) reads them.
    readonly property string settings: Settings.dir

    IpcHandler {
        target: "menu"
        function toggle(): void { Menu.toggle() }
        // page or page/tab, e.g. open system/processes
        function open(page: string): void { Menu.page = page.split("/")[0]; Menu.tab = page.split("/")[1] ?? ""; Menu.showing = true }
        function search(text: string): void { Menu.page = "home"; Menu.search = text; Menu.showing = true }
        function stop(): void { Claude.stop() }
        function ask(question: string): void { Menu.page = "claude"; Menu.showing = true; Claude.ask(question) }
    }

    PanelWindow {
        id: win
        visible: Menu.showing
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-menu"

        MouseArea { anchors.fill: parent; onClicked: Menu.showing = false }

        Rectangle {
            width: 820
            height: 580
            anchors.horizontalCenter: parent.horizontalCenter
            y: 50
            radius: 12
            color: Style.bg
            border.color: Style.line

            MouseArea { anchors.fill: parent } // swallow clicks so they don't close the menu

            FocusScope {
                id: scope
                anchors.fill: parent
                focus: true
                // On the Claude page Esc stops a running answer first.
                Keys.onEscapePressed: {
                    if (Menu.page === "claude" && Claude.busy) Claude.stop()
                    else if (!page.item?.back?.()) Menu.showing = false // a page's back() returns true when it handled Esc
                }
                // Only keys nothing else took arrive here, so typing in a text field is unaffected.
                Keys.onPressed: event => {
                    if (Menu.navKey(event)) { event.accepted = true; return }
                    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
                    // On Home, typing anywhere starts a search (so j/k/h/l type there instead of moving).
                    if (Menu.page === "home" && event.text.length === 1 && event.text > " " && page.item?.typeToSearch) {
                        page.item.typeToSearch(event.text)
                        event.accepted = true
                        return
                    }
                    const move = { [Qt.Key_J]: true, [Qt.Key_Down]: true, [Qt.Key_K]: false, [Qt.Key_Up]: false }[event.key]
                    if (move !== undefined) {
                        const from = scope.Window.activeFocusItem ?? page.item
                        from?.nextItemInFocusChain(move)?.forceActiveFocus(Qt.TabFocusReason)
                        event.accepted = true
                    } else if (event.key === Qt.Key_H || event.key === Qt.Key_L) {
                        Menu.step(event.key === Qt.Key_L ? 1 : -1)
                        event.accepted = true
                    }
                }

                Column {
                    x: 14; y: 14
                    spacing: 6
                    Repeater {
                        model: Menu.pages
                        IconButton {
                            required property var modelData
                            code: modelData.code
                            focusable: false
                            active: Menu.page === modelData.id
                            onClicked: Menu.page = modelData.id
                        }
                    }
                }
                Rectangle { x: 18; y: session.y - 10; width: 32; height: 1; color: Style.line } // pages | session
                IconButton {
                    id: session
                    x: 14; y: parent.height - height - 14
                    code: 0xF0425
                    focusable: false
                    active: Menu.page === "session"
                    onClicked: Menu.page = "session"
                }
                Rectangle { x: 68; y: 14; width: 1; height: parent.height - 28; color: Style.line }

                Loader {
                    id: page
                    x: 86; y: 18
                    width: parent.width - 104
                    height: parent.height - 36
                    focus: true
                    active: Menu.showing
                    source: "pages/" + Menu.page.charAt(0).toUpperCase() + Menu.page.slice(1) + ".qml"
                }
            }
        }
    }
}
