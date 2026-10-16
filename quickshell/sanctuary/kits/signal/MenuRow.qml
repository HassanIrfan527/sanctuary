import QtQuick
import ".."

// KIT · MenuRow — one line of a list (launcher, picker, power, …). Signal: a
// log line; the selected one gets a wash and a 2px marker in the hot colour.
//
//   ▌1   NAME      what it does                         ● LIVE
//
//   number    shown dim at the left (index + 1); -1 hides it
//   key       a letter that acts (RIG): bold, lit while selected
//   current   the name lights: this is the live one
//   status    "warn" / "alarm": the row IS in that state now (REC, PAUSED) —
//             the name and marker take that colour
//   danger    acting on it ends something: the marker and name turn the
//             alarm colour while selected
//   lead      items between the number and the name (a glyph, an icon)
Rectangle {
    id: row

    property int number: -1
    property string key: ""
    property string name: ""
    property string desc: ""
    property string detail: ""
    property bool selected: false
    property bool current: false
    property string status: ""
    property bool danger: false
    property bool litWhenSelected: false   // name lights while selected, not only when current
    property int nameWidth: 70
    property bool centred: false           // centre each item vertically (rows with a lead)
    property alias lead: leadBox.data

    signal hovered()
    signal clicked()

    readonly property color hot: status === "alarm" || danger ? Theme.sigAlarm
                               : status === "warn" ? Theme.sigWarn
                               : Theme.sigHot

    width: parent ? parent.width : 0
    height: 30
    color: selected ? Theme.sigCell : "transparent"

    Rectangle {
        width: 2
        height: parent.height
        color: row.hot
        visible: row.selected
    }
    Row {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            anchors.verticalCenter: row.centred ? parent.verticalCenter : undefined
            visible: row.number >= 0
            text: String(row.number)
            font.family: Theme.mono
            font.pixelSize: 10
            color: Theme.surface2
        }
        Text {
            anchors.verticalCenter: row.centred ? parent.verticalCenter : undefined
            visible: row.key !== ""
            text: row.key
            font.family: Theme.mono
            font.pixelSize: 10
            font.weight: Font.Bold
            color: row.selected ? row.hot : Theme.surface2
        }
        Item {
            id: leadBox
            anchors.verticalCenter: parent.verticalCenter
            visible: children.length > 0
            width: childrenRect.width
            height: childrenRect.height
        }
        Text {
            anchors.verticalCenter: row.centred ? parent.verticalCenter : undefined
            width: row.nameWidth
            text: row.name
            font.family: Theme.mono
            font.pixelSize: 12
            font.weight: Font.Bold
            color: row.current || row.status !== "" || (row.litWhenSelected && row.selected) ? row.hot : Theme.sigValue
        }
        Text {
            anchors.verticalCenter: row.centred ? parent.verticalCenter : undefined
            text: row.desc
            font.family: Theme.mono
            font.pixelSize: 10
            color: Theme.sigLabel
        }
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: row.detail
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: 1.2
        color: Theme.sigHot
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.hovered()
        onClicked: row.clicked()
    }
}
