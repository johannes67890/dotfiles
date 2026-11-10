import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services

Column {
    id: page
    spacing: 14
    readonly property var bat: UPower.displayDevice
    property real brightness: 0 // 0..1
    property real maxBrightness: 10000 // replaced by what KDE reports

    // KDE's own brightness API, so its OSD and settings stay in sync.
    Process {
        running: true
        command: ["sh", "-c", "busctl --user get-property org.kde.ScreenBrightness /org/kde/ScreenBrightness/display0 org.kde.ScreenBrightness.Display Brightness MaxBrightness"]
        stdout: StdioCollector {
            onStreamFinished: { const f = text.trim().split(/\s+/); page.maxBrightness = Number(f[3]); page.brightness = Number(f[1]) / page.maxBrightness }
        }
    }
    Component.onCompleted: BatteryHistory.refresh()
    function setBrightness(v) {
        brightness = Math.max(0.01, v)
        Quickshell.execDetached(["busctl", "--user", "call", "org.kde.ScreenBrightness", "/org/kde/ScreenBrightness/display0",
            "org.kde.ScreenBrightness.Display", "SetBrightness", "iu", String(Math.round(brightness * maxBrightness)), "0"])
    }
    function duration(s) {
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        return (h ? h + " h " : "") + m + " min"
    }

    Title { text: "BATTERY & DISPLAY" }
    Section {
        Label { text: "BRIGHTNESS" }
        Row {
            width: parent.width
            spacing: 12
            Slider { width: parent.width - 52; value: page.brightness; onMoved: v => page.setBrightness(v) }
            Value { width: 40; horizontalAlignment: Text.AlignRight; text: Math.round(page.brightness * 100) + "%"; font.pixelSize: 11 }
        }
    }
    Section {
        Label { text: "BATTERY" }
        Row {
            spacing: 14
            Value { text: Math.round(bat.percentage * 100) + "%"; font.pixelSize: 22 }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    text: bat.state === UPowerDeviceState.Charging ? "CHARGING · FULL IN " + page.duration(bat.timeToFull)
                        : bat.state === UPowerDeviceState.Discharging ? "ON BATTERY · " + page.duration(bat.timeToEmpty) + " LEFT"
                        : bat.state === UPowerDeviceState.FullyCharged ? "FULLY CHARGED" : "PLUGGED IN"
                }
                Label { text: Math.abs(bat.changeRate).toFixed(1) + " W" }
            }
        }
        Bar { width: parent.width; value: bat.percentage }
        Grid {
            id: details
            columns: 4
            width: parent.width
            rowSpacing: 10
            readonly property var i: SysMon.info
            Repeater {
                model: [
                    { name: "HEALTH", value: Math.min(100, Math.round(Number(details.i.bat_charge_full) / Number(details.i.bat_charge_full_design) * 100)) + "%" },
                    { name: "CYCLES", value: details.i.bat_cycle_count ?? "—" },
                    { name: "CHARGE LIMIT", value: details.i.bat_charge_control_end_threshold ? details.i.bat_charge_control_end_threshold + "%" : "—" },
                    { name: "CAPACITY", value: (Number(details.i.bat_charge_full) / 1000).toFixed(0) + " / " + (Number(details.i.bat_charge_full_design) / 1000).toFixed(0) + " mAh" },
                    { name: "VOLTAGE", value: SysMon.bat.volts.toFixed(2) + " V" },
                    { name: "CURRENT", value: SysMon.bat.amps.toFixed(2) + " A" },
                    { name: "CELL", value: (details.i.bat_manufacturer ?? "") + " " + (details.i.bat_model_name ?? "") },
                    { name: "TECHNOLOGY", value: details.i.bat_technology ?? "—" }
                ]
                Column {
                    required property var modelData
                    width: parent.width / 4
                    spacing: 2
                    Label { text: parent.modelData.name; font.pixelSize: 9 }
                    Value { width: parent.width; text: parent.modelData.value; font.pixelSize: 13 }
                }
            }
        }
    }
    Row {
        width: parent.width
        spacing: 12
        Section {
            width: (parent.width - 12) / 2
            pad: 12
            Row {
                width: parent.width
                Label { width: parent.width - range.width; text: "BATTERY % · 24 H" }
                Label { id: range; text: BatteryHistory.values.length ? Math.round(Math.min(...BatteryHistory.values)) + "–" + Math.round(Math.max(...BatteryHistory.values)) + "%" : "NO HISTORY YET" }
            }
            Graph { width: parent.width; height: 64; count: BatteryHistory.slots; values: BatteryHistory.values; max: 100; format: v => Math.round(v) + "%" }
        }
        Section {
            width: (parent.width - 12) / 2
            pad: 12
            Row {
                width: parent.width
                Label { width: parent.width - watts.width; text: "POWER DRAW" }
                Label { id: watts; text: SysMon.bat.watts.toFixed(1) + " W" }
            }
            Graph { width: parent.width; height: 64; count: SysMon.range; values: SysMon.recent(SysMon.powerHist); format: v => v.toFixed(1) + " W" }
        }
    }
    Section {
        Label { text: "POWER PROFILE" }
        Row {
            spacing: 10
            Pill { label: "SAVER"; active: PowerProfiles.profile === PowerProfile.PowerSaver; onClicked: PowerProfiles.profile = PowerProfile.PowerSaver }
            Pill { label: "BALANCED"; active: PowerProfiles.profile === PowerProfile.Balanced; onClicked: PowerProfiles.profile = PowerProfile.Balanced }
            Pill {
                visible: PowerProfiles.hasPerformanceProfile
                label: "PERFORMANCE"; active: PowerProfiles.profile === PowerProfile.Performance
                onClicked: PowerProfiles.profile = PowerProfile.Performance
            }
        }
    }
}
