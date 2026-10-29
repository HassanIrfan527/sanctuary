import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · TrackLine — what's playing, on the bar, with how far along as a 2px
// groove under it, filled cyan (sound).
Item {
    id: line
    property string text: ""
    property real progress: 0

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: track.width
    height: 28
    LText {
        id: track
        y: 1
        width: Math.min(implicitWidth, 140)
        elide: Text.ElideRight
        text: G.plain(line.text)
    }
    Rectangle {
        y: 24
        width: track.width
        height: 2
        color: Theme.lanSunk
        Rectangle {
            width: Math.floor(parent.width * Math.max(0, Math.min(1, line.progress)) / 2) * 2
            height: 2
            color: Theme.lanSound
        }
    }
}
