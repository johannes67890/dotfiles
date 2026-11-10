import QtQuick
import qs

// Shared line / bar graph for the System and Claude pages.
// values: primary series; values2: optional second (dim) series; count > 0 keeps a fixed number of slots
// so live history scrolls in from the right.
Canvas {
    id: g
    property var values: []
    property var values2: []
    property bool bars: false
    property int count: 0
    property real max: 0                  // 0 = scale to the data
    property var labels: []               // bar labels, drawn every labelEvery bars
    property int labelEvery: 1
    property var format: v => String(Math.round(v))
    property color color: Style.fg
    property color color2: Style.dim

    implicitHeight: 120
    onValuesChanged: requestPaint()
    onValues2Changed: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const n = Math.max(count, values.length, values2.length, 1)
        const top = Math.max(max, ...values, ...values2, 1e-9)
        const bottom = labels.length ? 14 : 0
        const h = height - bottom - 12, y0 = 12

        ctx.strokeStyle = Style.line
        ctx.lineWidth = 1
        for (let i = 0; i <= 2; i++) {
            const y = Math.round(y0 + h * i / 2) + 0.5
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
        }
        ctx.fillStyle = Style.dim
        ctx.font = "9px '" + Style.font + "'"
        ctx.fillText(format(top), 2, 9)

        const yOf = v => y0 + h - h * Math.min(1, v / top)
        if (bars) {
            const slot = width / n, bw = Math.max(1, slot * 0.7)
            values.forEach((v, i) => {
                ctx.fillStyle = g.color
                const y = yOf(v)
                ctx.fillRect(i * slot + (slot - bw) / 2, y, bw, y0 + h - y)
                if (labels.length && i % labelEvery === 0) {
                    ctx.fillStyle = Style.dim
                    ctx.fillText(labels[i] ?? "", i * slot + (slot - bw) / 2, height - 2)
                }
            })
            return
        }
        const line = (vals, c, fill) => {
            if (vals.length < 2) return
            const step = width / (n - 1), off = n - vals.length
            ctx.beginPath()
            vals.forEach((v, i) => { const x = (off + i) * step; i ? ctx.lineTo(x, yOf(v)) : ctx.moveTo(x, yOf(v)) })
            ctx.strokeStyle = c
            ctx.lineWidth = 1.5
            ctx.stroke()
            if (!fill) return
            ctx.lineTo((n - 1) * step, y0 + h)
            ctx.lineTo(off * step, y0 + h)
            ctx.closePath()
            ctx.globalAlpha = 0.12
            ctx.fillStyle = c
            ctx.fill()
            ctx.globalAlpha = 1
        }
        line(values2, color2, false)
        line(values, color, true)
    }
}
