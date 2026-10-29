import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Cell — one readout on the bar: what it is, then its value(s).
// Lantern: things, not labels — a label the kit knows is drawn as its icon
// (CPU ⚡, MEM backpack, TMR hourglass, MSG mailbox …); WS and WIN need none;
// anything else stays a dim word. Spacing separates cells, not lines (rule 5);
// the mailbox gets a wooden post before it, the bar's last zone.
//   labelTone  "" | "hot" | "warn" | "alarm" | "second"
//   rule       (Lantern: none drawn) · interactive  hover wash + clicks
Item {
    id: cell

    property string label: ""
    property string labelTone: ""
    property bool rule: true
    property bool interactive: false

    signal clicked(var mouse)
    signal scrolled(var wheel)

    default property alias content: row.data
    readonly property string cellLabel: label        // Value reads this (MSG badge, TMR amber)

    readonly property bool bare: label === "WS" || label === "WIN" || label === ""
    readonly property bool post: label === "MSG"
    // what colour the thing is: yours = pink, time = amber, the machine = state
    readonly property color iconColor:
          labelTone === "warn" ? Theme.lanWarn : labelTone === "alarm" ? Theme.lanAlarm
        : label === "MSG" ? Theme.lanPink
        : labelTone === "second" ? Theme.lanSound
        : labelTone === "hot" ? (label === "TMR" ? Theme.lanAmber : label === "MIC" ? Theme.lanOk : Theme.lanPink)
        : label === "PLAY" ? Theme.lanSound
        : Theme.lanDim

    implicitWidth: row.x + row.implicitWidth + 8
    implicitHeight: 32

    Rectangle {   // hover wash, only on cells that do something
        x: cell.post ? 12 : 0
        width: parent.width - x
        height: parent.height
        color: Theme.lanRaised
        visible: cell.interactive && area.containsMouse
    }
    Rectangle {   // the post: wood, with a nail
        visible: cell.post
        x: 0
        width: 10
        height: parent.height
        color: Theme.lanOutline
        Rectangle {
            x: 2
            width: 6
            height: parent.height
            color: Theme.lanWood
            Rectangle { width: 2; height: parent.height; color: Theme.lanWoodLit }
            Rectangle { x: 2; y: 15; width: 2; height: 2; color: Theme.lanNail }
        }
    }

    Icon {
        id: icon
        x: cell.post ? 20 : 6
        anchors.verticalCenter: parent.verticalCenter
        name: cell.bare ? "" : cell.label
        color: cell.iconColor
    }
    LText {
        id: word
        x: cell.post ? 20 : 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        visible: !cell.bare && !icon.known
        text: G.plain(cell.label.toLowerCase())
        color: cell.iconColor
    }

    Row {
        id: row
        x: icon.known ? icon.x + icon.width + 4 : word.visible ? word.x + word.implicitWidth + 6 : (cell.post ? 20 : 6)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: cell.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => cell.clicked(mouse)
        onWheel: wheel => cell.scrolled(wheel)
    }
}
