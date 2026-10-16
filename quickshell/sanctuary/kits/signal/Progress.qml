import QtQuick
import ".."

// KIT · Progress — how far along (a track); click to jump when `seekable`.
// Signal: a 2px hairline, filled in the hot colour.
Item {
    id: bar
    property real value: 0          // 0..1
    property bool seekable: false
    signal seek(real fraction)

    width: parent ? parent.width : 100
    height: 10
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 2
        color: Theme.surface0
        Rectangle {
            width: parent.width * bar.value
            height: 2
            color: Theme.sigHot
        }
    }
    MouseArea {
        anchors.fill: parent
        enabled: bar.seekable
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => bar.seek(mouse.x / width)
    }
}
