import QtQuick
import ".."

// KIT · TrackLine — what's playing, small, with how far along as a hairline.
Column {
    id: line
    property string text: ""
    property real progress: 0

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    spacing: 2
    Text {
        id: track
        width: Math.min(implicitWidth, 150)
        elide: Text.ElideRight
        text: line.text
        font.family: Theme.mono
        font.pixelSize: 10
        color: Theme.sigValue
    }
    Rectangle {   // position, as a hairline meter
        width: track.width
        height: 1
        color: Theme.surface0
        Rectangle {
            width: parent.width * line.progress
            height: 1
            color: Theme.sigHot
        }
    }
}
