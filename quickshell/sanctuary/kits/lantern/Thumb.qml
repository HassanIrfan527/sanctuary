import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Thumb — one contact-sheet tile's picture (PhotoTile). Loads the cached
// thumbnail only — never the original: a missing thumbnail shows the file's
// name instead, and `rev` going up (new thumbnails made) makes it try again.
// Lantern: the real picture, smooth (it's a preview of what you'll get).
Item {
    id: root
    property var entry: null          // { kind, path, thumb, name }
    property int rev: 0
    property string fallbackFont: Theme.lanFont
    property color fallbackColor: Theme.lanDim
    property bool dim: false          // tiles off the cursor sit back a little

    property bool failed: false
    onRevChanged: failed = false
    onEntryChanged: failed = false

    clip: true

    Image {
        id: img
        anchors.fill: parent
        source: root.entry && root.entry.thumb && !root.failed ? "file://" + root.entry.thumb : ""
        sourceSize.width: 480
        sourceSize.height: 270
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        opacity: status !== Image.Ready ? 0 : root.dim ? 0.8 : 1
        onStatusChanged: if (status === Image.Error) root.failed = true
    }

    LText {
        anchors.fill: parent
        anchors.margins: 10
        visible: img.status !== Image.Ready
        text: G.plain(root.entry ? root.entry.name : "")
        wrapMode: Text.WrapAnywhere
        maximumLineCount: 3
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.fallbackColor
    }
}
