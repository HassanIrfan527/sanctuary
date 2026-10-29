import QtQuick
import ".."

// KIT (Lantern only) · Corners — the selected tool's marks: a 6px L outside
// each corner, 2px thick (Stardew's cursor on a slot). Fill its target with
// anchors.margins: -4.
Item {
    id: c
    property color color: Theme.lanPink

    Repeater {
        model: 4
        delegate: Item {
            required property int index
            readonly property bool r: index % 2 === 1
            readonly property bool b: index >= 2
            x: r ? c.width - 6 : 0
            y: b ? c.height - 6 : 0
            width: 6
            height: 6
            Rectangle { y: parent.b ? 4 : 0; width: 6; height: 2; color: c.color }
            Rectangle { x: parent.r ? 4 : 0; width: 2; height: 6; color: c.color }
        }
    }
}
