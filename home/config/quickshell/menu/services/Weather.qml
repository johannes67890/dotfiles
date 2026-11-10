pragma Singleton
import QtQuick
import Quickshell
import qs

// Open-Meteo (no API key) for Copenhagen; refreshed on open when older than 15 min.
Singleton {
    id: root
    readonly property real lat: 55.68
    readonly property real lon: 12.57

    property bool ready: false
    property string error: ""
    property real temp: 0
    property real wind: 0
    property int code: 0
    property var hours: [] // [{ time, temp, code }]
    property real updated: 0

    function describe(c) {
        if (c === 0) return "CLEAR"
        if (c <= 2) return "PARTLY CLOUDY"
        if (c === 3) return "CLOUDY"
        if (c <= 48) return "FOG"
        if (c <= 57) return "DRIZZLE"
        if (c <= 67) return "RAIN"
        if (c <= 77) return "SNOW"
        if (c <= 82) return "SHOWERS"
        if (c <= 86) return "SNOW SHOWERS"
        return "THUNDER"
    }
    // Nerd Font md-weather-* glyphs
    function glyph(c) {
        if (c === 0) return 0xF0599
        if (c <= 2) return 0xF0595
        if (c === 3) return 0xF0590
        if (c <= 48) return 0xF0591
        if (c <= 67 || (c >= 80 && c <= 82)) return 0xF0597
        if (c <= 86) return 0xF0598
        return 0xF0593
    }

    function refresh() {
        const xhr = new XMLHttpRequest()
        xhr.open("GET", `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}`
            + "&current=temperature_2m,weather_code,wind_speed_10m"
            + "&hourly=temperature_2m,weather_code&forecast_hours=7&timezone=auto")
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) { error = "WEATHER UNAVAILABLE"; return }
            const d = JSON.parse(xhr.responseText)
            temp = d.current.temperature_2m
            wind = d.current.wind_speed_10m
            code = d.current.weather_code
            hours = d.hourly.time.slice(1).map((t, i) => ({
                time: t.slice(11, 16),
                temp: d.hourly.temperature_2m[i + 1],
                code: d.hourly.weather_code[i + 1]
            }))
            updated = Date.now()
            error = ""
            ready = true
        }
        xhr.send()
    }

    function refreshIfStale() { if (Menu.showing && Date.now() - updated > 15 * 60 * 1000) refresh() }
    Component.onCompleted: refreshIfStale() // created lazily, i.e. after the menu already opened
    Connections { target: Menu; function onShowingChanged() { root.refreshIfStale() } }
}
