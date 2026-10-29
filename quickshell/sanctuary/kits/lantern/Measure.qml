import QtQuick
import "Glyphs.js" as G

// KIT · Measure — how wide a menu should be for its entries, in this style's
// type: the card fits its longest label (within limits). Invisible.
//   texts        the labels
//   checks/icons whether any entry has a check box / an icon (gutters)
//   textX        where labels start · cardWidth  the card's width
Column {
    id: m
    property var texts: []
    property bool checks: false
    property bool icons: false
    readonly property int textX: 12 + (checks ? 24 : 0) + (icons ? 28 : 0)
    readonly property real cardWidth: Math.max(220, Math.min(460, width + textX + 64))

    visible: false
    Repeater {
        model: m.texts
        LText {
            required property var modelData
            text: G.plain(modelData)
        }
    }
}
