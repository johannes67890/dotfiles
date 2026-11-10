pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Usage counted from local Claude Code transcripts (~/.claude/projects, last 30 days), like ccusage does.
// Plan limits (the % shown by /usage) aren't available outside Claude Code itself.
Singleton {
    id: root
    readonly property var empty: ({ msgs: 0, sessions: 0, out: 0, input: 0 })
    property var data: ({ h5: empty, today: empty, week: empty, month: empty, cacheHit: 0, webSearches: 0, model: "",
                          hourly: [], daily: [], projects: [], models: [], tools: [], sessions: [] })
    property real updated: 0

    Process {
        id: proc
        command: ["sh", "-c", `
            find "$HOME/.claude/projects" -name '*.jsonl' -mtime -31 -print0 | xargs -0 -r cat 2>/dev/null \\
              | jq -c -R 'fromjson? | select(.type == "assistant" and .message.id and .message.model != "<synthetic>")
                  | { id: .message.id, s: .sessionId, cwd: .cwd, m: .message.model,
                      t: (.timestamp | sub("\\\\.[0-9]+Z$"; "Z") | fromdateiso8601), u: .message.usage,
                      tools: [ .message.content[]? | select(.type == "tool_use") | { id, name } ] }' \\
              | jq -s -c --argjson now "$(date +%s)" --argjson midnight "$(date -d 'today 00:00' +%s)" '
                  def tin: (.u.input_tokens // 0) + (.u.cache_creation_input_tokens // 0) + (.u.cache_read_input_tokens // 0);
                  def agg(since): [ .[] | select(.t >= since) ]
                    | { msgs: length, sessions: (map(.s) | unique | length),
                        out: (map(.u.output_tokens // 0) | add // 0), input: (map(tin) | add // 0) };
                  ([ .[] | .tools[] ] | unique_by(.id)) as $tools
                  | (map(select(.u)) | unique_by(.id)) as $m
                  | ($m | map(select(.t >= $now - 604800))) as $week
                  | {
                      h5: ($m | agg($now - 18000)), today: ($m | agg($midnight)), week: ($m | agg($now - 604800)), month: ($m | agg($now - 2592000)),
                      cacheHit: (($week | map(.u.cache_read_input_tokens // 0) | add // 0) / ([1, ($week | map(tin) | add // 0)] | max)),
                      webSearches: ($week | map(.u.server_tool_use.web_search_requests // 0) | add // 0),
                      model: ($m | max_by(.t) | .m // ""),
                      hourly: [ range(23; -1; -1) as $i | ($now - ($now % 3600) - $i * 3600) as $h
                                | { label: ($h | strflocaltime("%H")), out: ([ $m[] | select(.t >= $h and .t < $h + 3600) | .u.output_tokens // 0 ] | add // 0) } ],
                      daily: [ range(29; -1; -1) as $i | ($midnight - $i * 86400) as $d
                               | { label: ($d | strflocaltime("%d")), out: ([ $m[] | select(.t >= $d and .t < $d + 86400) | .u.output_tokens // 0 ] | add // 0),
                                   msgs: ([ $m[] | select(.t >= $d and .t < $d + 86400) ] | length) } ],
                      projects: ($m | group_by(.cwd) | map({ name: (.[0].cwd // "?" | sub("^/home/[^/]+/?"; "~/")), out: (map(.u.output_tokens // 0) | add), msgs: length }) | sort_by(-.out) | .[:8]),
                      models: ($m | group_by(.m) | map({ name: .[0].m, out: (map(.u.output_tokens // 0) | add), msgs: length }) | sort_by(-.out)),
                      tools: ($tools | group_by(.name) | map({ name: .[0].name, count: length }) | sort_by(-.count) | .[:10]),
                      sessions: ($m | group_by(.s) | map({ id: .[0].s, cwd: .[0].cwd, last: (map(.t) | max), msgs: length, out: (map(.u.output_tokens // 0) | add) }) | sort_by(-.last) | .[:8])
                    }'
        `]
        stdout: StdioCollector {
            onStreamFinished: { try { root.data = JSON.parse(text); root.updated = Date.now() } catch (e) {} }
        }
    }
    // 5 min unless forced: the full scan costs ~0.7 s CPU; the Claude page and each answer force a fresh one.
    function refresh(force) { if (!proc.running && (force || Date.now() - updated > 300000)) proc.running = true }

    function tokens(n) {
        if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
        if (n >= 1e3) return (n / 1e3).toFixed(1) + "k"
        return String(Math.round(n))
    }
}
