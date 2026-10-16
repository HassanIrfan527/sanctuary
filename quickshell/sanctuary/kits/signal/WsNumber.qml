import QtQuick
import ".."

// KIT · WsNumber — one workspace on the bar. focused = you're on it (a 2px
// underline); occupied = windows on it; urgent = something there wants you.
MouseArea {
    id: ws
    property string text: ""
    property bool focused: false
    property bool occupied: false
    property bool urgent: false

    width: num.implicitWidth + 4
    height: 18
    cursorShape: Qt.PointingHandCursor

    Text {
        id: num
        anchors.centerIn: parent
        text: ws.text
        font.family: Theme.mono
        font.pixelSize: 11
        font.weight: ws.focused ? Font.Bold : Font.Normal
        color: ws.urgent ? Theme.sigAlarm : ws.focused ? Theme.sigHot : ws.occupied ? Theme.sigValue : Theme.surface2
    }
    Rectangle {   // the focused cursor: a 2px underline
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: num.implicitWidth
        height: 2
        color: Theme.sigHot
        visible: ws.focused
    }
}
