import QtQuick
import ".."

// KIT · BarStrip — the bar's surface and where its zones sit:
//   leftItems │ … │ alertItems · CLOCK · … │ rightItems
//   leftItems   what you're in (recorders, workspaces, the window)
//   alertItems  built outward from the clock: only what is wrong right now
//   centreItem  the clock, dead centre
//   rightItems  the readouts
// (not left/right: those are taken, FINAL, on every Item)
// compact: the strip shrinks to a centred block, as wide as its wider half
// needs, mirrored — the clock stays dead centre. caution: Master Caution,
// part 1 (Signal: the registration marks turn red).
Rectangle {
    id: strip

    property bool compact: false
    property bool caution: false
    property alias leftItems: leftRow.data
    property alias alertItems: alertRow.data
    property alias centreItem: clockSlot.data
    property alias rightItems: rightRow.data
    readonly property alias leftRow: leftRow
    readonly property alias alertRow: alertRow

    readonly property int gap: 14   // clock ↔ its neighbours
    readonly property real half: Math.max(
        leftRow.width + alertRow.width + gap * 2 + clockSlot.width / 2,
        clockSlot.width / 2 + gap + rightRow.width)

    x: compact ? Math.round((parent.width - width) / 2) : 8
    y: 6
    width: compact ? Math.min(parent.width - 16, Math.ceil(half * 2)) : parent.width - 16
    height: Theme.sigStripH
    color: Theme.sigFill
    border.width: 1
    border.color: Theme.sigRule

    Ticks {
        anchors.fill: parent
        anchors.margins: -3
        color: strip.caution ? Theme.sigAlarm : Theme.sigHot
        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    Row {
        id: leftRow
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
        spacing: 6
    }
    Row {
        id: rightRow
        anchors.right: parent.right
        height: parent.height
    }
}
