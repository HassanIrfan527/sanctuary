import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · WsNumber — one workspace on the bar, as a slot in a toolbar.
// focused = you're on it (pink frame, the selected-tool marks); occupied =
// windows on it (its number); empty = a dim dot; urgent = an alarm frame.
MouseArea {
    id: ws
    property string text: ""
    property bool focused: false
    property bool occupied: false
    property bool urgent: false

    width: 28
    height: 28
    cursorShape: Qt.PointingHandCursor

    Slot {
        anchors.fill: parent
        on: ws.focused
        tone: ws.urgent ? "alarm" : ""
        LText {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            visible: ws.occupied || ws.focused
            text: G.plain(String(Number(ws.text) || ws.text))
            color: ws.urgent ? Theme.lanAlarm : ws.focused ? Theme.lanPink : Theme.lanText
        }
        Rectangle {
            anchors.centerIn: parent
            visible: !ws.occupied && !ws.focused
            width: 2
            height: 2
            color: Theme.lanDim
        }
    }
}
