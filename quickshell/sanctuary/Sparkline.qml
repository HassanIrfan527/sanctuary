import QtQuick

// A trace: the last N samples as a line with a faint fill under it. Newest on
// the right, like every scope and every stock ticker.
Canvas {
    id: spark
    property var values: []
    property real max: 1          // 0 = scale to the largest sample in view
    property color line: Theme.sigHot

    implicitWidth: 36
    implicitHeight: 16

    onValuesChanged: requestPaint()
    onLineChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const v = values || [];
        if (v.length < 2)
            return;
        const top = max > 0 ? max : Math.max(1, ...v);
        const n = Math.max(v.length, 2);
        const dx = width / (n - 1);
        const off = (n - v.length) * dx; // short history hugs the right edge
        const yOf = s => height - 1 - Math.max(0, Math.min(1, s / top)) * (height - 2);

        ctx.beginPath();
        ctx.moveTo(off, height);
        for (let i = 0; i < v.length; i++)
            ctx.lineTo(off + i * dx, yOf(v[i]));
        ctx.lineTo(off + (v.length - 1) * dx, height);
        ctx.closePath();
        ctx.fillStyle = line;
        ctx.globalAlpha = 0.16;
        ctx.fill();

        ctx.globalAlpha = 1;
        ctx.beginPath();
        for (let i = 0; i < v.length; i++) {
            const x = off + i * dx, y = yOf(v[i]);
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.strokeStyle = line;
        ctx.lineWidth = 1;
        ctx.stroke();
    }
}
