import QtQuick
import ".."

// KIT · Boxes — a tiny schematic: rectangles in a frame, each [x, y, w, h]
// as fractions of the frame (a window layout). The first box is the main one.
// `lit` = pink (your choice); `turn` = transposed. Lantern: 2px pixel boxes
// on whole even pixels, the main one filled.
Item {
    id: glyph

    property var boxes: []
    property bool lit: false
    property bool turn: false

    readonly property color ink: lit ? Theme.lanPink : Theme.lanDim

    width: 34
    height: 20
    clip: true

    Repeater {
        model: glyph.boxes
        delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property var b: glyph.turn
                ? [modelData[1], modelData[0], modelData[3], modelData[2]]
                : modelData
            x: Math.round(b[0] * glyph.width / 2) * 2
            y: Math.round(b[1] * glyph.height / 2) * 2
            width: Math.max(4, Math.round(b[2] * glyph.width / 2) * 2)
            height: Math.max(4, Math.round(b[3] * glyph.height / 2) * 2)
            color: index === 0 ? Qt.rgba(glyph.ink.r, glyph.ink.g, glyph.ink.b, 0.35) : Theme.lanSunk
            border.width: 2
            border.color: glyph.ink
        }
    }
}
