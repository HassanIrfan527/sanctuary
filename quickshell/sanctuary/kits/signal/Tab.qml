import QtQuick
import ".."

// KIT · Tab — a small switch word on a title line.
//   kind "switch"  HORIZ │ VERT: bold small caps, hot when on, dim when off
//   kind "shelf"   STILL 445 · LIVE 21: the shelf on show is bold, underlined
Text {
    id: tab

    property bool on: false
    property string kind: "switch"
    signal clicked()

    readonly property bool shelf: kind === "shelf"

    font.family: Theme.mono
    font.pixelSize: 9
    font.weight: !shelf || on ? Font.Bold : Font.Normal
    font.letterSpacing: 1.4
    font.underline: shelf && on
    color: shelf ? (on ? Theme.sigValue : Theme.sigLabel) : (on ? Theme.sigHot : Theme.surface2)

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: tab.clicked()
    }
}
