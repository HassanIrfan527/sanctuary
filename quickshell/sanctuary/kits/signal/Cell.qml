import QtQuick
import ".."

// KIT · Cell — one readout on the bar: a small-caps LABEL, then its value(s),
// then a hairline. The label is always dimmer than the value — you read the
// number, the label only tells you which number it is.
//   labelTone  "" | "hot" | "warn" | "alarm" | "second" (Signal's warm voice)
//   rule       hairline on the right edge · interactive  hover wash + clicks
Item {
    id: cell

    property string label: ""
    property string labelTone: ""
    property bool rule: true
    property bool interactive: false

    signal clicked(var mouse)
    signal scrolled(var wheel)

    default property alias content: row.data

    implicitWidth: row.x + row.implicitWidth + 11
    implicitHeight: Theme.sigStripH

    Rectangle {   // hover wash, only on cells that do something
        anchors.fill: parent
        color: Theme.sigCell
        visible: cell.interactive && area.containsMouse
    }

    Text {
        id: lab
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        visible: text !== ""
        text: cell.label
        font.family: Theme.mono
        font.pixelSize: 9
        font.weight: Font.Bold
        font.letterSpacing: 1.4
        color: cell.labelTone === "hot" ? Theme.sigHot : cell.labelTone === "warn" ? Theme.sigWarn
             : cell.labelTone === "alarm" ? Theme.sigAlarm : cell.labelTone === "second" ? Theme.peach
             : Theme.sigLabel
    }

    Row {
        id: row
        x: lab.visible ? lab.x + lab.implicitWidth + 7 : 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }

    Rectangle {
        visible: cell.rule
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 12
        color: Theme.sigRule
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
