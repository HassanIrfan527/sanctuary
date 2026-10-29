import QtQuick
import ".."

// KIT · Tab — a small switch word on a title line.
//   kind "switch"  horiz │ vert: pink when on (your choice), dim when off
//   kind "shelf"   still 445 · live 21: the shelf on show is bright, underlined pink
LText {
    id: tab

    property bool on: false
    property string kind: "switch"
    signal clicked()

    readonly property bool shelf: kind === "shelf"

    color: shelf ? (on ? Theme.lanBright : Theme.lanDim) : (on ? Theme.lanPink : Theme.lanDim)

    Rectangle {
        visible: tab.shelf && tab.on
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: Theme.lanPink
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: tab.clicked()
    }
}
