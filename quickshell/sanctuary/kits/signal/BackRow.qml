import QtQuick
import ".."

// KIT · BackRow — "‹ NAME": the way out of a submenu, at the top of it.
Rectangle {
    id: back
    property string text: ""
    signal clicked()

    width: parent ? parent.width : 0
    height: 28
    color: area.containsMouse ? Theme.sigCell : "transparent"
    Text {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        text: "‹ " + back.text.toUpperCase()
        font.family: Theme.mono
        font.pixelSize: 9
        font.weight: Font.Bold
        font.letterSpacing: 1.6
        color: Theme.sigHot
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: back.clicked()
    }
}
