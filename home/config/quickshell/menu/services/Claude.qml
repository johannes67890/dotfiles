pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Quick questions through Claude Code in print mode. --restricted + --tools WebSearch: no shell, file or code
// tools. Runs in its own state dir so these chats stay out of other projects; follow-ups resume the session.
Singleton {
    id: root
    property var messages: [] // [{ role: "user" | "claude" | "note", text, html }]
    property bool busy: false
    property string error: ""
    property string sessionId: ""
    property bool stopping: false // the running request was stopped; drop its result

    function ask(q) {
        q = q.trim()
        if (!q || busy) return
        messages = messages.concat([{ role: "user", text: q }])
        error = ""
        busy = true
        proc.command = ["sh", "-c",
            'd="$HOME/.local/state/quickshell-claude"; mkdir -p "$d" && cd "$d" && exec claude -p "$@" < /dev/null', "_",
            "--output-format", "json", "--restricted", "--tools", "WebSearch",
            "--append-system-prompt", "You answer in a small desktop popup: be brief and use short Markdown."]
            .concat(Settings.claudeModel ? ["--model", Settings.claudeModel] : [], sessionId ? ["--resume", sessionId] : [], ["--", q])
        proc.running = true
    }
    function stop() {
        if (!busy) return
        stopping = true
        proc.signal(15)
    }
    function newChat() {
        stop()
        messages = []
        sessionId = ""
        error = ""
    }

    // Markdown -> rich text with highlighted code (quickshell-md, from quickshell.nix); until it's done, or if it
    // fails, the page shows the answer as plain text.
    property int rendering: -1
    function render(i) {
        rendering = i
        renderer.command = ["quickshell-md", messages[i].text]
        renderer.running = true
    }
    Process {
        id: renderer
        stdout: StdioCollector {
            onStreamFinished: {
                const i = root.rendering
                if (i < 0 || i >= root.messages.length || !text.trim()) return
                root.messages = root.messages.map((m, j) => j === i ? Object.assign({}, m, { html: text }) : m)
            }
        }
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false
                if (root.stopping) {
                    root.stopping = false
                    if (root.messages.length) root.messages = root.messages.concat([{ role: "note", text: "Stopped." }])
                    return
                }
                let r
                try { r = JSON.parse(text) } catch (e) { if (!root.error) root.error = "NO ANSWER FROM CLAUDE"; return }
                if (r.session_id) root.sessionId = r.session_id
                if (r.is_error) root.error = (r.result || "CLAUDE RETURNED AN ERROR").toUpperCase()
                else { root.messages = root.messages.concat([{ role: "claude", text: r.result, html: "" }]); root.render(root.messages.length - 1) }
                ClaudeUsage.refresh(true)
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim() && !root.stopping) root.error = text.trim().split("\n").pop() }
    }
}
