import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · CautionLamp — Master Caution: the one light that means "something
// needs you", naming what. clicked() = acknowledge.
// Lantern: a red notched tag with the bell and the reasons.
Item {
    id: root
    property string text: ""
    signal clicked()

    width: lamp.width
    height: parent ? parent.height : 32
    Rectangle {
        id: lamp
        anchors.verticalCenter: parent.verticalCenter
        width: lampRow.width + 16
        height: 26
        color: lampArea.containsMouse ? Theme.lanAlarmHi : Theme.lanAlarm
        Repeater {   // notched corners
            model: 4
            Rectangle {
                required property int index
                x: index % 2 ? lamp.width - 2 : 0
                y: index >= 2 ? lamp.height - 2 : 0
                width: 2
                height: 2
                color: Theme.lanPaper
            }
        }
        Row {
            id: lampRow
            anchors.centerIn: parent
            spacing: 6
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "bell-ring"
                color: Theme.lanOnAlarm
            }
            LText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: G.plain(root.text.toLowerCase())
                color: Theme.lanOnAlarm
            }
        }
        MouseArea {
            id: lampArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
