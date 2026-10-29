import QtQuick
import ".."

// KIT (private) · Scanlines — faint CRT lines over a card, for a palette with
// fx "full". Static: painted once per size or palette, nothing runs while idle.
Canvas {
    property int pitch: 3
    readonly property color ink: Theme.sigValue

    visible: Theme.fxFull
    opacity: 0.045
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onInkChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = ink;
        for (let y = 0; y < height; y += pitch)
            ctx.fillRect(0, y, width, 1);
    }
}
