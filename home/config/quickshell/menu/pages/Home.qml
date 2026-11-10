import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services

Item {
    id: home
    focus: true
    // The search fills the page while focused (or while it holds text); otherwise the dashboard shows.
    readonly property bool searching: input.activeFocus || input.text !== ""
    property string query: ""
    property int selected: 0
    Component.onCompleted: { Dnd.refresh(); ClaudeUsage.refresh(); BatteryHistory.refresh(); Mail.refresh(); useSearch() }
    function useSearch() { if (Menu.search) { input.text = Menu.search; input.forceActiveFocus(); Menu.search = "" } }
    // Start searching from anywhere on Home: shell.qml sends printable keys here ("/" only focuses).
    function typeToSearch(ch) { input.forceActiveFocus(); if (ch !== "/") input.insert(input.cursorPosition, ch) }
    Connections { target: Menu; function onSearchChanged() { home.useSearch() } }

    // Pages the search can jump to, besides apps.
    readonly property var pageHits: [
        { id: "claude", label: "Claude", words: "claude ai ask question chat usage tokens model" },
        { id: "system", label: "System", words: "system cpu memory ram temperature sensors fan disk network processes top battery gpu" },
        { id: "media", label: "Media", words: "music spotify player song" },
        { id: "audio", label: "Audio", words: "sound volume mute speaker" },
        { id: "network", label: "Network", words: "wifi wi-fi internet vpn proton ip" },
        { id: "bluetooth", label: "Bluetooth", words: "bluetooth headphones devices pair" },
        { id: "power", label: "Battery & display", words: "battery brightness power profile screen" },
        { id: "activity", label: "Activity", words: "mail email inbox thunderbird unread activity notifications" },
        { id: "docker", label: "Docker", words: "docker containers" },
        { id: "nix", label: "NixOS", words: "nix nixos garbage generation flake" },
        { id: "session", label: "Session", words: "lock sleep suspend logout reboot restart shutdown power off" }
    ]
    readonly property var results: {
        const q = query.trim().toLowerCase()
        if (!q) return []
        const has = s => (s ?? "").toLowerCase().includes(q)
        const apps = DesktopEntries.applications.values
            .filter(e => !e.noDisplay && (has(e.name) || has(e.genericName) || (e.keywords ?? []).some(has)))
            .sort((a, b) => (b.name.toLowerCase().startsWith(q) ? 1 : 0) - (a.name.toLowerCase().startsWith(q) ? 1 : 0))
            .slice(0, 6)
            .map(e => ({ kind: "app", label: e.name, detail: e.genericName || e.comment, entry: e }))
        const pages = pageHits.filter(p => has(p.label) || p.words.includes(q))
            .map(p => ({ kind: "page", label: p.label, detail: "MENU PAGE", id: p.id }))
        const calc = Calc.result && Calc.input === query.trim()
            ? [{ kind: "calc", label: "= " + Calc.result, detail: "CALCULATOR · ENTER COPIES" }] : []
        return calc.concat(apps, pages, [
            { kind: "claude", label: "Ask Claude: " + query.trim(), detail: "CLAUDE" },
            { kind: "web", label: "Search Brave for \"" + query.trim() + "\"", detail: "WEB" }
        ])
    }
    onResultsChanged: selected = 0
    onQueryChanged: Calc.query(query)

    function activate(r) {
        if (!r) return
        if (r.kind === "app") { Menu.showing = false; r.entry.execute() }
        else if (r.kind === "calc") { Calc.copy(); Menu.showing = false }
        else if (r.kind === "page") { Menu.page = r.id }
        else if (r.kind === "claude") { Claude.ask(query.trim()); Menu.page = "claude" }
        else Menu.run(["xdg-open", "https://search.brave.com/search?q=" + encodeURIComponent(query.trim())])
    }
    function duration(s) { const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60); return (h ? h + "h " : "") + m + "m" }

    // top row: search (grows to the full width while searching) and the clock
    Rectangle {
        id: box
        width: home.searching ? parent.width : 300
        height: 40
        y: home.searching ? 0 : 8
        radius: 10
        color: "transparent"
        border.color: input.activeFocus ? Style.lineActive : Style.line
        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: input.forceActiveFocus() }
        Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; code: 0xF0349; color: Style.dim; font.pixelSize: 14 }
        Field {
            id: input
            x: 40; width: parent.width - 54
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 13
            placeholder: home.searching ? "APPS, PAGES, CLAUDE OR THE WEB" : "SEARCH  ·  /"
            onTextChanged: home.query = text
            Keys.onDownPressed: home.selected = Math.min(home.selected + 1, home.results.length - 1)
            Keys.onUpPressed: home.selected = Math.max(home.selected - 1, 0)
            Keys.onReturnPressed: home.activate(home.results[home.selected])
            Keys.onEnterPressed: home.activate(home.results[home.selected])
            // Esc: clear the text, then go back to the dashboard
            Keys.onEscapePressed: text ? text = "" : home.forceActiveFocus()
        }
    }
    Column {
        anchors.right: parent.right
        visible: !home.searching
        SystemClock { id: clock; precision: SystemClock.Seconds }
        Text { anchors.right: parent.right; text: Qt.formatTime(clock.date, "HH:mm"); color: Style.fg; font.family: Style.font; font.pixelSize: 34; font.weight: Font.Light }
        Label { anchors.right: parent.right; text: Qt.formatDate(clock.date, "dddd d MMMM").toUpperCase(); font.pixelSize: 10 }
    }

    // search results
    Label {
        visible: home.searching && !home.query.trim()
        anchors.centerIn: parent
        text: "TYPE TO SEARCH · ↑ ↓ TO PICK · ENTER TO OPEN · ESC TO GO BACK"
    }
    ListView {
        visible: home.searching
        y: box.height + 12
        width: parent.width
        height: parent.height - y
        clip: true
        spacing: 4
        model: home.results
        currentIndex: home.selected
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
        delegate: Clickable {
            required property var modelData
            required property int index
            width: ListView.view.width; height: 44; radius: 8
            focusable: false
            active: index === home.selected
            // Hover only highlights; Enter opens the keyboard selection (↑/↓), never the row under the mouse.
            onClicked: home.activate(modelData)
            Image {
                id: appIcon
                x: 12; anchors.verticalCenter: parent.verticalCenter
                width: 24; height: 24
                sourceSize: Qt.size(48, 48)
                visible: parent.modelData.kind === "app" && status === Image.Ready
                source: parent.modelData.kind === "app" ? Quickshell.iconPath(parent.modelData.entry.icon, true) : ""
            }
            Icon {
                x: 16; anchors.verticalCenter: parent.verticalCenter
                visible: !appIcon.visible
                code: ({ web: 0xF059F, page: 0xF035C, claude: 0xF0B79, calc: 0xF00EC })[parent.modelData.kind] ?? 0xF003B
                color: Style.dim
            }
            Value { x: 48; y: 6; width: parent.width - 60; text: parent.modelData.label; font.pixelSize: 13 }
            Label { x: 48; y: 25; width: parent.width - 60; text: (parent.modelData.detail ?? "").toUpperCase(); font.pixelSize: 9 }
        }
    }

    // dashboard
    Item {
        visible: !home.searching
        y: 62
        width: parent.width
        height: parent.height - y

        // quick toggles as icons; the hovered (or focused) one is named next to them
        Row {
            id: toggles
            spacing: 6
            property string hint: "" // id of the button being pointed at
            readonly property var bt: Bluetooth.defaultAdapter
            readonly property var switches: [
                { id: "wifi", tip: Networking.wifiEnabled ? "WI-FI ON" : "WI-FI OFF", code: Networking.wifiEnabled ? 0xF05A9 : 0xF05AA,
                  on: Networking.wifiEnabled, act: () => Networking.wifiEnabled = !Networking.wifiEnabled },
                { id: "bt", tip: toggles.bt?.enabled ? "BLUETOOTH ON" : "BLUETOOTH OFF", code: toggles.bt?.enabled ? 0xF00AF : 0xF00B2,
                  on: toggles.bt?.enabled ?? false, act: () => { if (toggles.bt) toggles.bt.enabled = !toggles.bt.enabled } },
                { id: "dnd", tip: Dnd.on ? "DO NOT DISTURB ON" : "DO NOT DISTURB OFF", code: Dnd.on ? 0xF009B : 0xF009A,
                  on: Dnd.on, act: () => Dnd.set(!Dnd.on) },
                { id: "vpn", tip: Vpn.name ? "VPN · " + Vpn.name : "VPN OFF · OPEN NETWORK", code: Vpn.name ? 0xF0582 : 0xF099E,
                  on: !!Vpn.name, act: () => Menu.page = "network" }
            ]
            readonly property var profiles: [
                { id: "saver", tip: "POWER SAVER", code: 0xF032A, on: PowerProfiles.profile === PowerProfile.PowerSaver,
                  act: () => PowerProfiles.profile = PowerProfile.PowerSaver },
                { id: "balanced", tip: "BALANCED", code: 0xF05D1, on: PowerProfiles.profile === PowerProfile.Balanced,
                  act: () => PowerProfiles.profile = PowerProfile.Balanced }
            ].concat(PowerProfiles.hasPerformanceProfile ? [
                { id: "performance", tip: "PERFORMANCE", code: 0xF04C5, on: PowerProfiles.profile === PowerProfile.Performance,
                  act: () => PowerProfiles.profile = PowerProfile.Performance }
            ] : [])

            Component {
                id: toggle
                IconButton {
                    required property var modelData
                    size: 36
                    code: modelData.code
                    active: modelData.on
                    idleBorder: Style.line
                    onClicked: modelData.act()
                    onHoveredChanged: toggles.hint = hovered ? modelData.id : ""
                    onActiveFocusChanged: toggles.hint = activeFocus ? modelData.id : ""
                }
            }
            Repeater { model: toggles.switches; delegate: toggle }
            Rectangle { width: 1; height: 26; color: Style.line; anchors.verticalCenter: parent.verticalCenter }
            Repeater { model: toggles.profiles; delegate: toggle }
            Label {
                leftPadding: 8
                anchors.verticalCenter: parent.verticalCenter
                // looked up by id, so it shows the new state right after a click
                text: toggles.switches.concat(toggles.profiles).find(t => t.id === toggles.hint)?.tip ?? ""
            }
        }

        // three equal columns
        Row {
            id: columns
            y: toggles.height + 12
            width: parent.width
            spacing: 12
            readonly property real side: (width - 24) / 3

            // calendar + Claude
            Column {
                width: columns.side
                spacing: 12
                Section {
                    id: cal
                    property int offset: 0 // months from now
                    readonly property date month: new Date(clock.date.getFullYear(), clock.date.getMonth() + offset, 1)
                    pad: 10
                    Item {
                        width: parent.width; height: 22
                        Label { anchors.centerIn: parent; color: Style.fg; text: Qt.formatDate(cal.month, "MMMM yyyy").toUpperCase() }
                        IconButton { size: 22; code: 0xF0141; onClicked: cal.offset-- }
                        IconButton { size: 22; anchors.right: parent.right; code: 0xF0142; onClicked: cal.offset++ }
                    }
                    Grid {
                        columns: 7
                        width: parent.width
                        readonly property real cell: width / 7
                        Repeater {
                            model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                            Label { required property string modelData; width: parent.cell; horizontalAlignment: Text.AlignHCenter; text: modelData; font.pixelSize: 9 }
                        }
                        Repeater {
                            model: 42
                            Rectangle {
                                required property int index
                                readonly property int lead: (cal.month.getDay() + 6) % 7 // Monday first
                                readonly property date day: new Date(cal.month.getFullYear(), cal.month.getMonth(), 1 - lead + index)
                                readonly property bool today: day.toDateString() === clock.date.toDateString()
                                width: parent.cell; height: 24; radius: 6
                                color: today ? Style.fg : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.day.getDate()
                                    color: parent.today ? Style.bg : parent.day.getMonth() === cal.month.getMonth() ? Style.fg : Style.line
                                    font.family: Style.font
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
                Section {
                    pad: 12
                    Row {
                        width: parent.width
                        Label { width: parent.width - ask.width; text: "CLAUDE · TODAY"; anchors.verticalCenter: parent.verticalCenter }
                        Pill { id: ask; label: "ASK"; textSize: 9; padding: 16; implicitHeight: 24; onClicked: Menu.page = "claude" }
                    }
                    KeyValue { key: "OUTPUT TOKENS"; value: ClaudeUsage.tokens(ClaudeUsage.data.today.out) }
                    KeyValue { key: "MESSAGES"; value: ClaudeUsage.data.today.msgs }
                }
            }

            // system + VPN
            Column {
                width: columns.side
                spacing: 12
                Section {
                    pad: 12
                    Label { text: "SYSTEM" }
                    Repeater {
                        model: [
                            { name: "CPU", value: SysMon.cpu, text: Math.round(SysMon.cpu * 100) + "%" },
                            { name: "RAM", value: SysMon.memUsed / SysMon.memTotal, text: Style.bytes(SysMon.memUsed) },
                            { name: "TEMP", value: SysMon.temp / 100, text: Math.round(SysMon.temp) + "°C" },
                            { name: "DISK", value: SysMon.diskUsed / SysMon.diskTotal, text: Style.bytes(SysMon.diskUsed) }
                        ]
                        Column {
                            required property var modelData
                            width: parent.width
                            spacing: 3
                            KeyValue { key: parent.modelData.name; value: parent.modelData.text }
                            Bar { width: parent.width; value: parent.modelData.value }
                        }
                    }
                    KeyValue { key: "NET ↓ / ↑"; value: Style.bytes(SysMon.rxRate) + " · " + Style.bytes(SysMon.txRate) }
                }
                Clickable {
                    width: parent.width
                    height: vpnCol.implicitHeight + 24
                    radius: 10
                    idleBorder: Style.line
                    onClicked: Menu.page = "network"
                    Column {
                        id: vpnCol
                        x: 12; y: 12; width: parent.width - 24
                        spacing: 6
                        Label { text: "VPN & IP" }
                        Value { width: parent.width; text: Vpn.name ? "HIDDEN · " + Vpn.name : "NOT PROTECTED"; font.pixelSize: 12 }
                        KeyValue { key: Vpn.name ? "VISIBLE (VPN)" : "PUBLIC IP"; value: Vpn.publicIp || "…" }
                    }
                }
                Clickable {
                    width: parent.width
                    height: mailCol.implicitHeight + 20
                    radius: 10
                    idleBorder: Style.line
                    onClicked: Menu.page = "activity"
                    Column {
                        id: mailCol
                        x: 12; y: 10; width: parent.width - 24
                        spacing: 4
                        KeyValue { key: "MAIL"; value: Mail.unread ? Mail.unread + " UNREAD" : "NO UNREAD" }
                        Repeater {
                            model: Mail.messages.slice(0, 2)
                            Value {
                                required property var modelData
                                width: parent.width
                                font.pixelSize: 11
                                color: modelData.unread ? Style.fg : Style.dim
                                text: (modelData.unread ? "● " : "") + modelData.subject
                            }
                        }
                    }
                }
            }

            // weather + battery
            Column {
                width: columns.side
                spacing: 12
                Section {
                    pad: 12
                    Label { text: "WEATHER · COPENHAGEN" }
                    Label { visible: !Weather.ready; text: Weather.error || "LOADING…" }
                    Row {
                        visible: Weather.ready
                        spacing: 12
                        Icon { code: Weather.glyph(Weather.code); font.pixelSize: 30 }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Value { text: Math.round(Weather.temp) + "°C"; font.pixelSize: 18 }
                            Label { text: Weather.describe(Weather.code); font.pixelSize: 9 }
                        }
                    }
                    Row {
                        visible: Weather.ready
                        width: parent.width
                        Repeater {
                            model: Weather.hours.slice(0, 4)
                            Column {
                                required property var modelData
                                width: parent.width / 4
                                spacing: 3
                                Label { anchors.horizontalCenter: parent.horizontalCenter; text: parent.modelData.time; font.pixelSize: 9 }
                                Icon { anchors.horizontalCenter: parent.horizontalCenter; code: Weather.glyph(parent.modelData.code); font.pixelSize: 13 }
                                Value { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(parent.modelData.temp) + "°"; font.pixelSize: 11 }
                            }
                        }
                    }
                }
                Section {
                    id: batCard
                    pad: 12
                    readonly property var dev: UPower.displayDevice
                    Label { text: "BATTERY" }
                    Row {
                        spacing: 10
                        Value { text: SysMon.bat.capacity + "%"; font.pixelSize: 20 }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 9
                            readonly property var d: batCard.dev
                            text: d.state === UPowerDeviceState.Discharging ? home.duration(d.timeToEmpty) + " LEFT"
                                : d.state === UPowerDeviceState.Charging ? "CHARGING · " + home.duration(d.timeToFull)
                                : d.state === UPowerDeviceState.FullyCharged ? "FULL" : "PLUGGED IN"
                        }
                    }
                    Graph { width: parent.width; height: 44; count: BatteryHistory.slots; values: BatteryHistory.values; max: 100; format: v => Math.round(v) + "%" }
                    Label { text: "LAST 24 H"; font.pixelSize: 9 }
                }
            }
        }

        // mini player
        Section {
            id: player
            visible: !!Media.player
            y: parent.height - height
            pad: 10
            Row {
                width: parent.width
                spacing: 12
                Rectangle {
                    width: 36; height: 36; radius: 6; color: Style.raised; clip: true
                    Image { anchors.fill: parent; source: Media.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop }
                }
                Column {
                    width: parent.width - 36 - controls.width - 24
                    anchors.verticalCenter: parent.verticalCenter
                    Value { width: parent.width; text: Media.player?.trackTitle || "Nothing playing" }
                    Label { width: parent.width; text: (Media.player?.trackArtist ?? "").toUpperCase(); font.pixelSize: 9 }
                }
                Row {
                    id: controls
                    anchors.verticalCenter: parent.verticalCenter
                    GlyphButton { glyph: "\u25C1"; size: 18; onClicked: Media.player.previous() }
                    GlyphButton { glyph: Media.player?.isPlaying ? "\u275A\u275A" : "\u25B6"; size: 18; onClicked: Media.player.togglePlaying() }
                    GlyphButton { glyph: "\u25B7"; size: 18; onClicked: Media.player.next() }
                }
            }
        }
    }
}
