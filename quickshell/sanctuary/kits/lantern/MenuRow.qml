import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · MenuRow — one line of a list (picker, power, RIG, COMMS…). Lantern: a
// shop row; the selected one is raised, with a pink pointer at the left.
//
//   ▸ 1  name       what it does                          ● live
//
//   number    shown dim at the left (index + 1); -1 hides it
//   key       a letter that acts (RIG): pink while selected
//   current   the name lights pink: this is the one you're using
//   status    "warn" / "alarm": the row IS in that state now (rec, paused)
//   danger    acting on it ends something: the pointer and name turn the
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
    property bool litWhenSelected: false
    property int nameWidth: 70
    property bool centred: false
    property alias lead: leadBox.data

    signal hovered()
    signal clicked()

    readonly property color hot: status === "alarm" || danger ? Theme.lanAlarm
                               : status === "warn" ? Theme.lanWarn
                               : Theme.lanPink

    width: parent ? parent.width : 0
    height: 36
    color: selected ? Theme.lanRaised : "transparent"

    Icon {
        x: 2
        anchors.verticalCenter: parent.verticalCenter
        visible: row.selected
        name: "chevron-right"
        color: row.hot
    }
    Row {
        x: 26
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        spacing: 12

        LText {
            anchors.verticalCenter: row.centred ? parent.verticalCenter : undefined
            visible: row.number >= 0
            text: String(row.number)
            color: Theme.lanDim
        }
        LText {
            anchors.verticalCenter: row.centred ? parent.verticalCenter : undefined
            visible: row.key !== ""
            text: G.plain(row.key.toLowerCase())
            color: row.selected ? row.hot : Theme.lanDim
        }
        Item {
            id: leadBox
            anchors.verticalCenter: parent.verticalCenter
            visible: children.length > 0
            width: childrenRect.width
            height: childrenRect.height
        }
        LText {
            anchors.verticalCenter: row.centred ? parent.verticalCenter : undefined
            width: row.nameWidth
            elide: Text.ElideRight
            text: G.plain(row.name)
            color: row.current || row.status !== "" || (row.litWhenSelected && row.selected) ? row.hot
                 : row.selected ? Theme.lanBright : Theme.lanText
        }
        LText {
            anchors.verticalCenter: row.centred ? parent.verticalCenter : undefined
            // what's left of the row, less the detail: Jersey runs wider than mono
            width: Math.max(0, Math.min(implicitWidth, row.width - 26 - x - detailText.implicitWidth - 24))
            elide: Text.ElideRight
            text: G.plain(row.desc)
            color: Theme.lanDim
        }
    }
    LText {
        id: detailText
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: G.plain(row.detail.toLowerCase())
        color: row.status === "alarm" ? Theme.lanAlarm : row.status === "warn" ? Theme.lanWarn : Theme.lanOk
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.hovered()
        onClicked: row.clicked()
    }
}
