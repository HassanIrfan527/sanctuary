import QtQuick
import ".."

// KIT · BarStrip — the bar's surface and where its zones sit:
//   leftItems │ … │ alertItems · CLOCK · … │ rightItems
//   leftItems   what you're in (recorders, workspaces, the window)
//   alertItems  built outward from the clock: only what is wrong right now
//   centreItem  the clock, dead centre
//   rightItems  the readouts
// compact: the rail shrinks to a centred block, as wide as its wider half
// needs, mirrored — the clock stays dead centre. caution: Master Caution,
// part 1 (Lantern: the rail's frame turns red).
// Lantern: one wooden rail around one sunk strip of paper, 44px, with a hard
// shadow; the clock plaque stands the rail's full height.
Item {
    id: strip

    property bool compact: false
    property bool caution: false
    property alias leftItems: leftRow.data
    property alias alertItems: alertRow.data
    property alias centreItem: clockSlot.data
    property alias rightItems: rightRow.data
    readonly property alias leftRow: leftRow
    readonly property alias alertRow: alertRow

    readonly property int gap: 16   // clock ↔ its neighbours
    readonly property real half: Math.max(
        leftRow.width + alertRow.width + gap * 2 + clockSlot.width / 2,
        clockSlot.width / 2 + gap + rightRow.width) + 6

    x: compact ? Math.round((parent.width - width) / 2) : 4
    y: 2
    width: compact ? Math.min(parent.width - 8, Math.ceil(half) * 2) : parent.width - 8
    height: 44

    Wood {
        id: rail
        anchors.fill: parent
        thick: 4
        shadow: true
        outline: strip.caution ? Theme.lanAlarm : Theme.lanOutline
    }

    Item {   // the paper: zones live here
        id: paper
        x: rail.edge
        y: rail.edge
        width: parent.width - 2 * rail.edge
        height: parent.height - 2 * rail.edge

        Row {
            id: leftRow
            x: 4
            height: parent.height
        }
        Item {
            id: clockSlot
            anchors.centerIn: parent
            width: childrenRect.width
            height: childrenRect.height
        }
        Row {
            id: alertRow
            anchors.right: clockSlot.left
            anchors.rightMargin: strip.gap
            height: parent.height
            layoutDirection: Qt.RightToLeft
            spacing: 8
        }
        Row {
            id: rightRow
            anchors.right: parent.right
            height: parent.height
        }
    }
}
