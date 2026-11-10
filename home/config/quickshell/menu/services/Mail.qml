pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Inbox mail from Thunderbird's local cache (quickshell-mail, from quickshell.nix). Thunderbird only syncs while
// it runs, so sync() starts it headless until the inboxes stop changing (a few seconds) when it isn't open.
Singleton {
    id: root
    property var accounts: []   // [{ name, synced, unread }]
    property var messages: []   // newest first: [{ account, from, subject, date, unread, id }]
    property real updated: 0
    readonly property bool syncing: syncer.running
    property var detail: null    // the message being read: { from, to, cc, date, subject, body, attachments } or { error }
    readonly property int unread: accounts.reduce((n, a) => n + a.unread, 0)

    Process {
        id: reader
        command: ["quickshell-mail"]
        stdout: StdioCollector {
            onStreamFinished: { try { const d = JSON.parse(text); root.accounts = d.accounts; root.messages = d.messages; root.updated = Date.now() } catch (e) {} }
        }
    }
    function refresh(force) { if (!reader.running && (force || Date.now() - updated > 30000)) reader.running = true }

    // Headless Thunderbird (it checks every account at startup); quickshell-mail stops it once the inboxes are
    // quiet, and also when this process is stopped.
    Process {
        id: syncer
        command: ["quickshell-mail", "--sync"]
        onExited: root.refresh(true)
    }

    // One message as plain text (HTML converted, so nothing in it is ever loaded).
    Process {
        id: bodyReader
        stdout: StdioCollector {
            onStreamFinished: { try { root.detail = Object.assign({ id: root.readingId }, JSON.parse(text)) } catch (e) { root.detail = { id: root.readingId, error: "Could not read this mail." } } }
        }
    }
    property string readingId: ""
    function read(m) {
        readingId = m.id
        detail = { loading: true, id: m.id, subject: m.subject, from: m.from }
        bodyReader.command = ["quickshell-mail", "--body", m.account, m.id]
        bodyReader.running = true
    }
    function sync() { if (!syncer.running) syncer.running = true }

    // Opens a mail (or just Thunderbird). A headless sync is stopped first: Thunderbird would otherwise hand
    // the request to that windowless instance.
    function open(id) {
        if (syncer.running) syncer.signal(15)
        Quickshell.execDetached(["sh", "-c", "while pgrep -x 'thunderbird|\\.thunderbird-wr.*' >/dev/null && [ \"$1\" = wait ]; do sleep 0.5; done; shift; exec thunderbird \"$@\"",
            "_", syncer.running ? "wait" : "go"].concat(id ? ["mid:" + id] : []))
    }
}
