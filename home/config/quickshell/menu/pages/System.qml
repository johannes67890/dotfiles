import QtQuick
import qs
import qs.components
import qs.services

Item {
    id: page
    readonly property var rate: v => Style.bytes(v) + "/s"
    readonly property var pct: v => Math.round(v) + "%"
    function uptime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d ? d + "d " : "") + (h ? h + "h " : "") + m + "m"
    }
    function peak(a) { return a.length ? Math.max(...a) : 0 }

    component Stat: Column {
        property string name
        property string value
        spacing: 2
        Label { text: parent.name; font.pixelSize: 9 }
        Value { text: parent.value; font.pixelSize: 13; width: parent.width }
    }
    component GraphCard: Section {
        property string name
        property string value
        property var values: []
        property var values2: []
        property real max: 0
        property var format: v => String(Math.round(v))
        property int graphHeight: 80
        pad: 12
        Row {
            width: parent.width
            Label { width: parent.width - val.width; text: parent.parent.parent.name }
            Value { id: val; text: parent.parent.parent.value; font.pixelSize: 11 }
        }
        Graph {
            width: parent.width; height: parent.parent.graphHeight
            count: SysMon.range
            values: parent.parent.values
            values2: parent.parent.values2
            max: parent.parent.max
            format: parent.parent.format
        }
    }
    component Meter: Row {
        property string name
        property real value
        property string text
        spacing: 10
        Label { width: 90; text: parent.name; anchors.verticalCenter: parent.verticalCenter }
        Bar { width: parent.width - 90 - 180 - 20; anchors.verticalCenter: parent.verticalCenter; value: parent.value }
        Value { width: 180; horizontalAlignment: Text.AlignRight; text: parent.text; font.pixelSize: 11 }
    }

    Row {
        id: header
        width: parent.width
        Title { width: parent.width - range.width; text: "SYSTEM"; anchors.verticalCenter: parent.verticalCenter }
        Tabs {
            id: range
            model: [{ id: "30", label: "1 MIN" }, { id: "150", label: "5 MIN" }, { id: "450", label: "15 MIN" }]
            current: String(SysMon.range)
            onCurrentChanged: SysMon.range = Number(current)
        }
    }
    Component.onCompleted: useTab()
    // A tab asked for over IPC (open page/tab); cleared so it doesn't stick to later visits.
    function useTab() { if (tabs.model.some(t => t.id === Menu.tab)) tabs.current = Menu.tab; if (Menu.tab) Menu.tab = "" }
    Connections { target: Menu; function onTabChanged() { page.useTab() } }
    Binding { target: SysMon; property: "detailTab"; value: tabs.current }
    Tabs {
        id: tabs
        y: header.height + 10
        model: [
            { id: "overview", label: "OVERVIEW" }, { id: "cpu", label: "CPU" }, { id: "memory", label: "MEMORY" },
            { id: "sensors", label: "SENSORS" }, { id: "disk", label: "DISK" },
            { id: "network", label: "NETWORK" }, { id: "processes", label: "PROCESSES" }
        ]
    }

    Item {
        id: body
        y: tabs.y + tabs.height + 12
        width: parent.width
        height: parent.height - y

        // OVERVIEW
        Column {
            visible: tabs.current === "overview"
            width: parent.width
            spacing: 12
            Section {
                pad: 12
                Grid {
                    columns: 3
                    width: parent.width
                    rowSpacing: 10
                    Stat { width: parent.width / 3; name: "HOST"; value: SysMon.info.host ?? "" }
                    Stat { width: parent.width / 3; name: "NIXOS"; value: SysMon.info.nixos ?? "" }
                    Stat { width: parent.width / 3; name: "KERNEL"; value: SysMon.info.kernel ?? "" }
                    Stat { width: parent.width / 3; name: "UPTIME"; value: page.uptime(SysMon.uptime) }
                    Stat { width: parent.width / 3; name: "LOAD 1 / 5 / 15"; value: SysMon.load.map(l => l.toFixed(2)).join("  ") }
                    Stat { width: parent.width / 3; name: "PROCESSES"; value: SysMon.procCount }
                }
            }
            Grid {
                columns: 2
                spacing: 12
                width: parent.width
                GraphCard { width: (parent.width - 12) / 2; name: "CPU"; value: page.pct(SysMon.cpu * 100); values: SysMon.recent(SysMon.cpuHist).map(v => v * 100); max: 100; format: page.pct }
                GraphCard { width: (parent.width - 12) / 2; name: "MEMORY"; value: Style.bytes(SysMon.memUsed) + " / " + Style.bytes(SysMon.memTotal); values: SysMon.recent(SysMon.memHist).map(v => v * 100); max: 100; format: page.pct }
                GraphCard { width: (parent.width - 12) / 2; name: "NETWORK ↓ / ↑"; value: page.rate(SysMon.rxRate) + "  " + page.rate(SysMon.txRate); values: SysMon.recent(SysMon.rxHist); values2: SysMon.recent(SysMon.txHist); format: page.rate }
                GraphCard { width: (parent.width - 12) / 2; name: "CPU TEMP"; value: Math.round(SysMon.temp) + "°C"; values: SysMon.recent(SysMon.tempHist); format: v => Math.round(v) + "°" }
            }
        }

        // CPU
        Column {
            id: cpuTab
            visible: tabs.current === "cpu"
            width: parent.width
            spacing: 12
            readonly property var mhz: SysMon.cores.map(c => c.mhz)
            Section {
                pad: 12
                Grid {
                    columns: 4
                    width: parent.width
                    Stat { width: parent.width / 2; name: "MODEL"; value: SysMon.info.cpuModel ?? "" }
                    Stat { width: parent.width / 6; name: "GOVERNOR"; value: (SysMon.info.governor ?? "").toUpperCase() }
                    Stat { width: parent.width / 6; name: "PROFILE (EPP)"; value: (SysMon.info.epp ?? "").replace(/_/g, " ").toUpperCase() }
                    Stat {
                        width: parent.width / 6; name: "AVG / MAX GHZ"
                        value: (cpuTab.mhz.reduce((a, b) => a + b, 0) / Math.max(1, SysMon.cores.length) / 1000).toFixed(1)
                            + " / " + ((SysMon.info.cpuMaxMhz ?? 0) / 1000).toFixed(1)
                    }
                }
            }
            GraphCard { name: "TOTAL LOAD · " + SysMon.cores.length + " CORES"; value: page.pct(SysMon.cpu * 100); values: SysMon.recent(SysMon.cpuHist).map(v => v * 100); max: 100; format: page.pct; graphHeight: 100 }
            Grid {
                columns: 4
                columnSpacing: 12
                rowSpacing: 8
                width: parent.width
                Repeater {
                    model: SysMon.cores
                    Column {
                        required property var modelData
                        required property int index
                        width: (parent.width - 36) / 4
                        spacing: 4
                        Row {
                            width: parent.width
                            Label { width: 36; text: "C" + parent.parent.index; font.pixelSize: 9 }
                            Value { width: parent.width - 36; horizontalAlignment: Text.AlignRight; font.pixelSize: 10
                                text: page.pct(parent.parent.modelData.load * 100) + " · " + (parent.parent.modelData.mhz / 1000).toFixed(1) + " GHz" }
                        }
                        Bar { width: parent.width; value: parent.modelData.load }
                    }
                }
            }
        }

        // MEMORY
        Column {
            id: memTab
            visible: tabs.current === "memory"
            width: parent.width
            spacing: 12
            readonly property var m: SysMon.mem
            readonly property real total: m.MemTotal ?? 1
            Section {
                pad: 14
                Meter { width: parent.width; name: "USED"; value: SysMon.memUsed / memTab.total; text: Style.bytes(SysMon.memUsed) + " / " + Style.bytes(memTab.total) }
                Meter { width: parent.width; name: "CACHE"; value: ((memTab.m.Cached ?? 0) + (memTab.m.SReclaimable ?? 0)) / memTab.total; text: Style.bytes((memTab.m.Cached ?? 0) + (memTab.m.SReclaimable ?? 0)) }
                Meter { width: parent.width; name: "BUFFERS"; value: (memTab.m.Buffers ?? 0) / memTab.total; text: Style.bytes(memTab.m.Buffers ?? 0) }
                Meter { width: parent.width; name: "SHARED"; value: (memTab.m.Shmem ?? 0) / memTab.total; text: Style.bytes(memTab.m.Shmem ?? 0) }
                Meter { width: parent.width; name: "FREE"; value: (memTab.m.MemFree ?? 0) / memTab.total; text: Style.bytes(memTab.m.MemFree ?? 0) }
                Meter {
                    width: parent.width; name: "SWAP"
                    readonly property real used: (memTab.m.SwapTotal ?? 0) - (memTab.m.SwapFree ?? 0)
                    value: used / Math.max(1, memTab.m.SwapTotal ?? 0)
                    text: (memTab.m.SwapTotal ?? 0) ? Style.bytes(used) + " / " + Style.bytes(memTab.m.SwapTotal) : "NONE"
                }
            }
            GraphCard { name: "MEMORY USED"; value: page.pct(SysMon.memUsed / SysMon.memTotal * 100); values: SysMon.recent(SysMon.memHist).map(v => v * 100); max: 100; format: page.pct; graphHeight: 110 }
        }

        // SENSORS
        Column {
            id: sensTab
            visible: tabs.current === "sensors"
            width: parent.width
            spacing: 12
            readonly property var cores: SysMon.temps.filter(t => t.chip === "coretemp" && t.label.startsWith("Core"))
                .sort((a, b) => Number(a.label.slice(5)) - Number(b.label.slice(5)))
            function find(chip, label) { return SysMon.temps.find(t => t.chip === chip && (!label || t.label.startsWith(label))) }
            function c(t) { return t ? Math.round(t.c) + "°C" : "—" }
            GraphCard { name: "CPU PACKAGE"; value: Math.round(SysMon.temp) + "°C"; values: SysMon.recent(SysMon.tempHist); format: v => Math.round(v) + "°"; graphHeight: 60 }
            GraphCard { name: "GPU"; value: SysMon.gpuMhz + " / " + (SysMon.info.gpuMaxMhz ?? 0) + " MHz"; values: SysMon.recent(SysMon.gpuHist); max: SysMon.info.gpuMaxMhz ?? 0; format: v => Math.round(v) + " MHz"; graphHeight: 60 }
            Section {
                pad: 12
                Grid {
                    columns: 5
                    width: parent.width
                    rowSpacing: 10
                    Stat { width: parent.width / 5; name: "CORES MAX"; value: Math.round(Math.max(0, ...sensTab.cores.map(t => t.c))) + "°C" }
                    Stat { width: parent.width / 5; name: "CORES AVG"; value: Math.round(sensTab.cores.reduce((a, t) => a + t.c, 0) / Math.max(1, sensTab.cores.length)) + "°C" }
                    Stat { width: parent.width / 5; name: "SSD"; value: sensTab.c(sensTab.find("nvme", "Composite")) }
                    Stat { width: parent.width / 5; name: "RAM"; value: sensTab.c(sensTab.find("spd5118")) }
                    Stat { width: parent.width / 5; name: "WI-FI"; value: sensTab.c(sensTab.find("iwlwifi_1")) }
                    Stat { width: parent.width / 5; name: "BATTERY"; value: sensTab.c(sensTab.find("cros_ec", "battery")) }
                    Stat { width: parent.width / 5; name: "EC CPU"; value: sensTab.c(sensTab.find("cros_ec", "cpu")) }
                    Stat { width: parent.width / 5; name: "EC DDR"; value: sensTab.c(sensTab.find("cros_ec", "ddr")) }
                    Stat { width: parent.width / 5; name: "EC BOARD"; value: sensTab.c(sensTab.find("cros_ec", "local")) }
                    Stat { width: parent.width / 5; name: "FAN"; value: Math.round(SysMon.fan) + " RPM" }
                }
            }
            Section {
                pad: 12
                Label { text: "PER CORE" }
                Grid {
                    columns: 8
                    width: parent.width
                    rowSpacing: 6
                    Repeater {
                        model: sensTab.cores
                        Value { required property var modelData; width: parent.width / 8; font.pixelSize: 10; text: modelData.label.replace("Core ", "C") + " " + Math.round(modelData.c) + "°" }
                    }
                }
            }
        }

        // DISK
        Column {
            visible: tabs.current === "disk"
            width: parent.width
            spacing: 12
            Section {
                pad: 12
                Grid {
                    columns: 4
                    width: parent.width
                    Stat { width: parent.width / 4; name: "DRIVE"; value: SysMon.info.diskModel ?? "—" }
                    Stat { width: parent.width / 4; name: "READ / WRITE"; value: page.rate(SysMon.readRate) + "  " + page.rate(SysMon.writeRate) }
                    Stat { width: parent.width / 4; name: "READ SINCE BOOT"; value: Style.bytes(SysMon.readTotal) }
                    Stat { width: parent.width / 4; name: "WRITTEN SINCE BOOT"; value: Style.bytes(SysMon.writeTotal) }
                }
            }
            GraphCard { name: "READ ─ / WRITE ─"; value: "PEAK " + page.rate(page.peak(SysMon.recent(SysMon.readHist).concat(SysMon.recent(SysMon.writeHist)))); values: SysMon.recent(SysMon.readHist); values2: SysMon.recent(SysMon.writeHist); format: page.rate; graphHeight: 100 }
            Section {
                pad: 14
                Label { text: "MOUNTS" }
                Repeater {
                    model: SysMon.mounts
                    Meter {
                        required property var modelData
                        width: parent.width
                        name: modelData.target
                        value: modelData.used / modelData.size
                        text: Style.bytes(modelData.used) + " / " + Style.bytes(modelData.size) + " · " + modelData.fstype
                    }
                }
            }
        }

        // NETWORK
        Item {
            visible: tabs.current === "network"
            anchors.fill: parent
            Section {
                id: pub
                pad: 12
                IpStatus {}
            }
            ListView {
                y: pub.height + 12
                width: parent.width
                height: parent.height - y
                clip: true
                spacing: 12
                model: SysMon.links
                delegate: Section {
                    id: link
                    required property var modelData
                    readonly property var r: SysMon.ifaces[modelData.name] ?? { rx: 0, tx: 0, rxTotal: 0, txTotal: 0 }
                    readonly property var h: SysMon.ifaceHist[modelData.name] ?? { rx: [], tx: [] }
                    width: ListView.view.width
                    pad: 12
                    Row {
                        width: parent.width
                        Value { width: parent.width - state.width; text: link.modelData.name + (link.modelData.wifi ? "  ·  " + link.modelData.wifi.ssid : ""); font.pixelSize: 13 }
                        Label { id: state; text: link.modelData.state }
                    }
                    Row {
                        width: parent.width
                        Stat { width: parent.width / 2; name: "ADDRESSES"; value: link.modelData.ips.join("   ") || "—" }
                        Stat { width: parent.width / 4; name: "MAC"; value: link.modelData.mac ?? "—" }
                        Stat { width: parent.width / 4; name: link.modelData.wifi ? "LINK · SIGNAL" : "LINK"; value: link.modelData.wifi ? link.modelData.wifi.rate + " · " + link.modelData.wifi.signal + "%" : "—" }
                    }
                    Row {
                        width: parent.width
                        Stat { width: parent.width / 4; name: "↓ NOW / PEAK"; value: page.rate(link.r.rx) + " / " + page.rate(page.peak(SysMon.recent(link.h.rx))) }
                        Stat { width: parent.width / 4; name: "↑ NOW / PEAK"; value: page.rate(link.r.tx) + " / " + page.rate(page.peak(SysMon.recent(link.h.tx))) }
                        Stat { width: parent.width / 4; name: "↓ SINCE BOOT"; value: Style.bytes(link.r.rxTotal) }
                        Stat { width: parent.width / 4; name: "↑ SINCE BOOT"; value: Style.bytes(link.r.txTotal) }
                    }
                    Graph { width: parent.width; height: 70; count: SysMon.range; values: SysMon.recent(link.h.rx); values2: SysMon.recent(link.h.tx); format: page.rate }
                }
            }
        }

        // PROCESSES
        Row {
            visible: tabs.current === "processes"
            width: parent.width
            spacing: 12
            Repeater {
                model: [
                    { name: "TOP CPU", list: SysMon.procs.filter(p => p.name !== "top").sort((a, b) => b.cpu - a.cpu).slice(0, 14), value: p => p.cpu.toFixed(1) + "%" },
                    { name: "TOP MEMORY", list: SysMon.procs.slice().sort((a, b) => b.rss - a.rss).slice(0, 14), value: p => Style.bytes(p.rss) }
                ]
                Section {
                    id: plist
                    required property var modelData
                    width: (body.width - 12) / 2
                    pad: 12
                    Label { text: plist.modelData.name + (SysMon.procs.length ? "" : " · LOADING…") }
                    Repeater {
                        model: plist.modelData.list
                        Row {
                            required property var modelData
                            width: parent.width
                            Label { width: 56; text: parent.modelData.pid; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                            Value { width: parent.width - 56 - 80; text: parent.modelData.name.replace(/^\./, "").replace(/-w(r(a(p(p(ed?)?)?)?)?)?$/, ""); font.pixelSize: 11 }
                            Value { width: 80; horizontalAlignment: Text.AlignRight; text: plist.modelData.value(parent.modelData); font.pixelSize: 11 }
                        }
                    }
                }
            }
        }
    }
}
