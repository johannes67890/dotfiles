pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Calculator and currency for the search, like rofi-calc: the same qalc call (exchange rates refresh at most daily).
Singleton {
    id: root
    property string input: ""   // the query the result belongs to
    property string result: ""  // "" = nothing worth showing

    // shortcut: only queries with a digit (or a bare "usd to dkk" pair) go to qalc, because it "solves"
    // plain words too ("d" = 86400 s); widen the pattern if other wordy queries should count.
    function query(q) {
        q = q.trim()
        result = ""
        input = /\d/.test(q) || /^[a-z]{3}\s+(to|in)\s+[a-z]{3}$/i.test(q) ? q : ""
        if (input) delay.restart()
    }
    function expr(q) {
        return q.replace(/^=\s*/, "")                // "=2/2" is a comparison to qalc: "false"
                .replace(/\s+in\s+(?=[a-z]+$)/i, " to ") // "10 usd in dkk": qalc reads "in" as inches
    }
    // still busy: try again later instead of dropping the query
    Timer { id: delay; interval: 120; onTriggered: if (proc.running) restart(); else { proc.q = root.input; proc.running = true } }
    Process {
        id: proc
        property string q
        // "ignore dot off": the Danish locale otherwise reads "2.5" as 25 (dot = thousands separator)
        command: ["qalc", "-s", "update_exchange_rates 1days", "-s", "ignore dot off", "-terse", root.expr(q)]
        stdout: StdioCollector {
            onStreamFinished: {
                if (proc.q !== root.input) { if (root.input) delay.restart(); return } // typed on meanwhile: ask again
                const r = text.trim().split("\n").pop()
                root.result = r && r !== root.input ? r : ""
            }
        }
    }
    function copy() { Quickshell.execDetached(["wl-copy", "--", result]) }
}
