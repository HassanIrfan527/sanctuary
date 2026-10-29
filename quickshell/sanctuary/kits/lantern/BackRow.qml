import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · BackRow — "‹ name": the way out of a submenu, at the top of it.
Rectangle {
    id: back
    property string text: ""
    signal clicked()

    width: parent ? parent.width : 0
    height: 32
    color: area.containsMouse ? Theme.lanRaised : "transparent"
    LText {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        text: G.plain("‹ " + back.text.toLowerCase())
        color: Theme.lanPink
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: back.clicked()
    }
}
