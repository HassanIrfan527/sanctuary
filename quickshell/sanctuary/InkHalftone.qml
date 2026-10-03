import QtQuick

// Screentone: a staggered dot grid whose dots grow from nothing to touching
// across the width. The single most "manga" texture there is, and cheap — it
// only repaints when the item is resized.
Canvas {
    id: tone
    property color dot: Theme.inkLine
    property real strength: 0.2   // dot opacity
    property real from: 0.5       // where the tone starts, as a fraction of width
    property int step: 5          // grid pitch in px
    property bool reverse: false  // grow right→left instead

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onDotChanged: requestPaint()
    onStrengthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = dot;
        ctx.globalAlpha = strength;
        let row = 0;
        for (let y = step / 2; y < height; y += step, row++) {
            for (let x = (row % 2 ? step : step / 2); x < width; x += step) {
                const fx = reverse ? 1 - x / width : x / width;
                const t = (fx - from) / (1 - from);
                if (t <= 0)
                    continue;
                const r = Math.min(step * 0.5, t * step * 0.55);
                ctx.beginPath();
                ctx.arc(x, y, r, 0, 2 * Math.PI);
                ctx.fill();
            }
        }
    }
}
