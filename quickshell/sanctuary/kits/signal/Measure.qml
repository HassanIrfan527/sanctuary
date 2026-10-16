import QtQuick
import ".."

// KIT · Measure — how wide a menu should be for its entries, in this style's
// type: the card fits its longest label (within limits) instead of a fixed
// width that clips or swims. Invisible.
//   texts        the labels
//   checks/icons whether any entry has a check lamp / an icon (gutters)
//   textX        where labels start · cardWidth  the card's width
Column {
    id: m
    property var texts: []
    property bool checks: false
    property bool icons: false
    readonly property int textX: 14 + (checks ? 16 : 0) + (icons ? 24 : 0)
    readonly property real cardWidth: Math.max(200, Math.min(420, width + textX + 48))

    visible: false
    Repeater {
        model: m.texts
        Text {
            required property var modelData
            text: modelData
            font.family: Theme.mono
            font.pixelSize: 12
            font.weight: Font.Normal
        }
    }
}
