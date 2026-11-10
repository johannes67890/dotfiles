pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// System stats (awk skips files a host doesn't have: gawk otherwise stops at the first missing one). One awk call every 2 s (also while the menu is closed, so the graphs have history),
// df when open, and process / network details only while the System page is visible.
Singleton {
    id: root
    readonly property int capacity: 450        // 15 min of 2 s samples
    property int range: 150                    // samples shown by the graphs (1 / 5 / 15 min)
    function recent(a) { return a.slice(-range) }

    // live values (Home uses cpu, memUsed, memTotal, temp, diskUsed, diskTotal, rxRate, txRate)
    property real cpu: 0
    property var cores: []                     // [{ load, mhz }]
    property var mem: ({})                     // MemTotal, MemAvailable, Cached, ... in bytes
    property real memUsed: 0
    property real memTotal: 1
    property real temp: 0                      // CPU package °C
    property var temps: []                     // [{ chip, label, c }]
    property real fan: 0
    property real gpuMhz: 0
    property var bat: ({ capacity: 0, status: "", amps: 0, volts: 0, watts: 0 }) // filled by the first sample
    property var load: [0, 0, 0]
    property string procCount: ""
    property real uptime: 0
    property real rxRate: 0
    property real txRate: 0
    property var ifaces: ({})                  // name -> { rx, tx, rxTotal, txTotal }
    property real readRate: 0
    property real writeRate: 0
    property real readTotal: 0
    property real writeTotal: 0

    // history
    property var cpuHist: []
    property var memHist: []
    property var tempHist: []
    property var powerHist: []
    property var gpuHist: []
    property var rxHist: []
    property var txHist: []
    property var readHist: []
    property var writeHist: []
    property var ifaceHist: ({})               // name -> { rx: [], tx: [] }

    // static + detail
    property var info: ({})                    // cpuModel, host, nixos, kernel, governor, epp, cpuMaxMhz, gpuMaxMhz, battery..., diskModel
    property var mounts: []                    // [{ target, size, used, fstype }]
    property real diskUsed: 0
    property real diskTotal: 1
    property var procs: []                     // [{ pid, cpu, mem, rss, name }]
    property var links: []                     // ip -j addr, plus wifi info merged in

    property var last: null

    function push(a, v) { const b = a.concat([v]); return b.length > capacity ? b.slice(b.length - capacity) : b }

    Process {
        id: sampler
        command: ["sh", "-c", `LC_ALL=C awk 'BEGINFILE { if (ERRNO) nextfile } { print FILENAME "\\t" $0 }' /proc/stat /proc/meminfo /proc/net/dev /proc/diskstats /proc/loadavg /proc/uptime \
            /sys/class/hwmon/hwmon*/name /sys/class/hwmon/hwmon*/temp*_input /sys/class/hwmon/hwmon*/temp*_label /sys/class/hwmon/hwmon*/fan*_input \
            /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq \
            /sys/class/power_supply/BAT*/capacity /sys/class/power_supply/BAT*/current_now /sys/class/power_supply/BAT*/voltage_now /sys/class/power_supply/BAT*/status \
            /sys/class/drm/card*/device/tile0/gt0/freq0/act_freq 2>/dev/null`]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    function parse(text) {
        const now = Date.now()
        const cpuLines = {}, memv = {}, net = {}, hw = {}, freq = {}, b = {}
        let disk = null
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t")
            if (tab < 0) continue
            const file = line.slice(0, tab), v = line.slice(tab + 1)
            if (file === "/proc/stat") {
                const f = v.trim().split(/\s+/)
                if (f[0].startsWith("cpu")) cpuLines[f[0]] = f.slice(1).map(Number)
            } else if (file === "/proc/meminfo") {
                const f = v.split(/\s+/)
                memv[f[0].replace(":", "")] = Number(f[1]) * 1024
            } else if (file === "/proc/net/dev") {
                const f = v.trim().split(/[:\s]+/)
                if (f.length > 10 && f[0] !== "lo" && f[0] !== "Inter-" && f[0] !== "face") net[f[0]] = [Number(f[1]), Number(f[9])]
            } else if (file === "/proc/diskstats") {
                const f = v.trim().split(/\s+/)
                if (!disk && /^(nvme\d+n\d+|sd[a-z]|vd[a-z])$/.test(f[2])) disk = [Number(f[5]) * 512, Number(f[9]) * 512]
            } else if (file === "/proc/loadavg") {
                const f = v.split(" ")
                load = f.slice(0, 3).map(Number)
                procCount = f[3].split("/")[1]
            } else if (file === "/proc/uptime") {
                uptime = Number(v.split(" ")[0])
            } else if (file.startsWith("/sys/class/hwmon/")) {
                const m = file.match(/hwmon(\d+)\/(.+)$/)
                if (!hw[m[1]]) hw[m[1]] = { temps: {}, labels: {}, fans: [] }
                const h = hw[m[1]]
                if (m[2] === "name") h.name = v
                else if (m[2].endsWith("_input") && m[2].startsWith("temp")) h.temps[m[2].slice(0, -6)] = Number(v) / 1000
                else if (m[2].endsWith("_label")) h.labels[m[2].slice(0, -6)] = v
                else if (m[2].startsWith("fan")) h.fans.push(Number(v))
            } else if (file.includes("/cpufreq/")) {
                freq[Number(file.match(/cpu(\d+)\//)[1])] = Number(v) / 1000
            } else if (file.includes("/power_supply/")) {
                b[file.split("/").pop()] = v
            } else if (file.endsWith("act_freq")) {
                gpuMhz = Number(v)
            }
        }

        // CPU (deltas against the previous sample)
        const prev = last
        const busy = c => { const idle = c[3] + c[4], total = c.reduce((x, y) => x + y, 0); return [total - idle, total] }
        const ratio = (k) => {
            if (!prev || !prev.cpu[k]) return 0
            const [b1, t1] = busy(cpuLines[k]), [b0, t0] = busy(prev.cpu[k])
            return Math.max(0, Math.min(1, (b1 - b0) / Math.max(1, t1 - t0)))
        }
        cpu = ratio("cpu")
        const n = Object.keys(cpuLines).length - 1
        cores = Array.from({ length: n }, (_, i) => ({ load: ratio("cpu" + i), mhz: freq[i] ?? 0 }))

        // memory
        mem = memv
        memTotal = memv.MemTotal ?? 1
        memUsed = memTotal - (memv.MemAvailable ?? 0)

        // sensors
        const list = []
        fan = 0
        for (const id in hw) {
            const h = hw[id]
            for (const t in h.temps) list.push({ chip: h.name, label: h.labels[t] || t, c: h.temps[t] })
            for (const f of h.fans) fan = Math.max(fan, f)
        }
        temps = list
        temp = (list.find(t => t.chip === "coretemp" && t.label.startsWith("Package")) ?? list[0] ?? { c: 0 }).c

        // battery (sysfs reports µA / µV)
        const amps = Number(b.current_now ?? 0) / 1e6, volts = Number(b.voltage_now ?? 0) / 1e6
        bat = { capacity: Number(b.capacity ?? 0), status: b.status ?? "", amps: amps, volts: volts, watts: amps * volts }

        // network + disk rates
        const dt = prev ? (now - prev.time) / 1000 : 0
        const rates = {}
        let rx = 0, tx = 0
        for (const i in net) {
            const p = prev?.net[i]
            const r = { rx: p && dt ? Math.max(0, (net[i][0] - p[0]) / dt) : 0, tx: p && dt ? Math.max(0, (net[i][1] - p[1]) / dt) : 0, rxTotal: net[i][0], txTotal: net[i][1] }
            rates[i] = r
            // VPN and container traffic also passes the physical link, so leave virtual links out of the total.
            if (!/^(proton|pvpn|wg|tun|docker|veth|br-)/.test(i)) { rx += r.rx; tx += r.tx }
        }
        ifaces = rates
        rxRate = rx; txRate = tx
        if (disk) {
            readRate = prev?.disk && dt ? Math.max(0, (disk[0] - prev.disk[0]) / dt) : 0
            writeRate = prev?.disk && dt ? Math.max(0, (disk[1] - prev.disk[1]) / dt) : 0
            readTotal = disk[0]; writeTotal = disk[1]
        }
        last = { time: now, cpu: cpuLines, net: net, disk: disk }
        if (!prev) return // first sample only primes the deltas

        cpuHist = push(cpuHist, cpu)
        memHist = push(memHist, memUsed / memTotal)
        tempHist = push(tempHist, temp)
        powerHist = push(powerHist, bat.watts)
        gpuHist = push(gpuHist, gpuMhz)
        rxHist = push(rxHist, rxRate)
        txHist = push(txHist, txRate)
        readHist = push(readHist, readRate)
        writeHist = push(writeHist, writeRate)
        const ih = {}
        for (const i in rates) ih[i] = { rx: push(ifaceHist[i]?.rx ?? [], rates[i].rx), tx: push(ifaceHist[i]?.tx ?? [], rates[i].tx) }
        ifaceHist = ih
    }

    // Every 2 s while open, every 10 s in the background: background history is coarser but costs ~5x less.
    Timer { interval: Menu.showing ? 2000 : 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: sampler.running = true }

    // read once: hardware names, limits, versions
    Process {
        id: statics
        running: true
        command: ["sh", "-c", `
            printf 'host\\t%s\\nnixos\\t%s\\nkernel\\t%s\\n' "$(hostname)" "$(nixos-version)" "$(uname -r)"
            printf 'cpuModel\\t%s\\n' "$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1)"
            LC_ALL=C awk 'BEGINFILE { if (ERRNO) nextfile } { print FILENAME "\\t" $0 }' /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor \
                /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq \
                /sys/class/power_supply/BAT*/charge_full /sys/class/power_supply/BAT*/charge_full_design /sys/class/power_supply/BAT*/cycle_count \
                /sys/class/power_supply/BAT*/charge_control_end_threshold /sys/class/power_supply/BAT*/manufacturer \
                /sys/class/power_supply/BAT*/model_name /sys/class/power_supply/BAT*/technology \
                /sys/block/nvme*/device/model /sys/block/sd*/device/model /sys/class/drm/card*/device/tile0/gt0/freq0/max_freq 2>/dev/null
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const i = {}
                let maxMhz = 0
                for (const line of text.split("\n")) {
                    const [k, ...rest] = line.split("\t")
                    const v = rest.join("\t").trim()
                    if (!k) continue
                    const name = k.split("/").pop()
                    if (name === "cpuinfo_max_freq") maxMhz = Math.max(maxMhz, Number(v) / 1000)
                    else if (name === "scaling_governor") i.governor = v
                    else if (name === "energy_performance_preference") i.epp = v
                    else if (name === "max_freq") i.gpuMaxMhz = Number(v)
                    else if (name === "model" && k.startsWith("/sys/block/")) i.diskModel = v
                    else if (k.includes("/power_supply/")) i["bat_" + name] = v
                    else i[k] = v
                }
                i.cpuMaxMhz = maxMhz
                root.info = i
            }
        }
    }

    // df: Home's disk bar and the Disk tab
    Process {
        id: dfProc
        command: ["sh", "-c", "LC_ALL=C df -B1 --output=size,used,fstype,target -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs -x ramfs | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mounts = text.trim().split("\n").filter(l => l).map(l => {
                    const f = l.trim().split(/\s+/)
                    return { size: Number(f[0]), used: Number(f[1]), fstype: f[2], target: f.slice(3).join(" ") }
                }).filter(m => m.size > 0)
                const rootFs = root.mounts.find(m => m.target === "/")
                if (rootFs) { root.diskTotal = rootFs.size; root.diskUsed = rootFs.used }
            }
        }
    }
    Timer { interval: 30000; running: Menu.showing; repeat: true; triggeredOnStart: true; onTriggered: dfProc.running = true }

    // detail, only while the System page is open
    readonly property bool detailed: Menu.showing && Menu.page === "system"
    property string detailTab: "" // System page tab, set by the page
    onDetailTabChanged: if (detailed) detailTimer.restart()
    Process {
        id: procProc
        command: ["sh", "-c", "LC_ALL=C top -b -n2 -d0.5 -e k -w 512 | awk '/^ *PID/ { n++; next } n == 2 && NF >= 12 { print $1 \"\\t\" $9 \"\\t\" $10 \"\\t\" $6 \"\\t\" $12 }'"]
        stdout: StdioCollector {
            onStreamFinished: root.procs = text.trim().split("\n").filter(l => l).map(l => {
                const f = l.split("\t")
                return { pid: f[0], cpu: Number(f[1]), mem: Number(f[2]), rss: Number(f[3]) * 1024, name: f[4] }
            })
        }
    }
    Process {
        id: linkProc
        command: ["sh", "-c", "ip -j addr; echo; nmcli -t -f IN-USE,SSID,RATE,SIGNAL,CHAN dev wifi list --rescan no | grep '^\\*'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [json, wifi] = text.split("\n\n")
                let l = []
                try { l = JSON.parse(json).filter(x => x.ifname !== "lo") } catch (e) {}
                const w = (wifi ?? "").trim().replace(/\\:/g, "\u0000").split(":").map(s => s.replace(/\u0000/g, ":"))
                root.links = l.map(x => ({
                    name: x.ifname, state: x.operstate, mac: x.address,
                    ips: (x.addr_info ?? []).map(a => a.local + "/" + a.prefixlen),
                    wifi: x.ifname.startsWith("wl") && w.length > 3 ? { ssid: w[1], rate: w[2], signal: w[3], channel: w[4] } : null
                }))
            }
        }
    }
    Timer {
        id: detailTimer
        interval: 3000; running: root.detailed; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (root.detailTab === "processes") procProc.running = true
            if (root.detailTab === "network") linkProc.running = true
        }
    }
}
