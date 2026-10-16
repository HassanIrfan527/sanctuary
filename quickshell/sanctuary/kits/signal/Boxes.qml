import QtQuick
import ".."

// KIT · Boxes — a tiny schematic: rectangles in a frame, each [x, y, w, h]
// as fractions of the frame (a window layout, a column strip). The first box
// is the main one. `lit` = drawn in the hot colour; `turn` = transposed.
// Signal: hairline boxes, the main one with a faint fill.
Item {
    id: glyph

    property var boxes: []
    property bool lit: false
    property bool turn: false

    readonly property color ink: lit ? Theme.sigHot : Theme.sigLabel

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
            x: Math.round(b[0] * glyph.width)
            y: Math.round(b[1] * glyph.height)
            width: Math.max(2, Math.round(b[2] * glyph.width))
            height: Math.max(2, Math.round(b[3] * glyph.height))
            color: index === 0 ? Qt.rgba(glyph.ink.r, glyph.ink.g, glyph.ink.b, 0.25) : Theme.sigFill
            border.width: 1
            border.color: glyph.ink
        }
    }
}
