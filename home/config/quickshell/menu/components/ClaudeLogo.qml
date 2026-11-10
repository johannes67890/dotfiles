import QtQuick

// Claude's spark, drawn: tapered rays of uneven length in Claude orange.
Canvas {
    property color color: "#D97757"
    implicitWidth: 22
    implicitHeight: 22
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2
        const lengths = [1, 0.78, 0.92, 0.7, 0.96, 0.8, 1, 0.74, 0.9, 0.72, 0.95, 0.82]
        ctx.fillStyle = color
        lengths.forEach((l, i) => {
            const a = i / lengths.length * Math.PI * 2 + 0.12 * Math.sin(i * 2.3)
            const tip = r * l, base = r * 0.13, tipW = r * 0.06
            const dx = Math.cos(a), dy = Math.sin(a), px = -dy, py = dx
            ctx.beginPath()
            ctx.moveTo(cx + px * base, cy + py * base)
            ctx.lineTo(cx + dx * tip + px * tipW, cy + dy * tip + py * tipW)
            ctx.arc(cx + dx * tip, cy + dy * tip, tipW, a + Math.PI / 2, a - Math.PI / 2, true)
            ctx.lineTo(cx - px * base, cy - py * base)
            ctx.closePath()
            ctx.fill()
        })
        ctx.beginPath()
        ctx.arc(cx, cy, r * 0.16, 0, Math.PI * 2)
        ctx.fill()
    }
}
