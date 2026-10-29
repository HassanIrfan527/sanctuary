import QtQuick
import ".."

// KIT · Progress — how far along a track is; click to jump when `seekable`.
// Lantern: a 4px groove, filled cyan (it's sound) in 2px steps.
Item {
    id: bar
    property real value: 0          // 0..1
    property bool seekable: false
    signal seek(real fraction)

    width: parent ? parent.width : 100
    height: 12
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        color: Theme.lanSunk
        Rectangle {
            width: Math.floor(parent.width * Math.max(0, Math.min(1, bar.value)) / 2) * 2
            height: 4
            color: Theme.lanSound
        }
    }
    MouseArea {
        anchors.fill: parent
        enabled: bar.seekable
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => bar.seek(mouse.x / width)
    }
}
