import QtQuick

// One wallpaper tile's picture (WallPicker.qml). Loads the cached thumbnail
// only — never the original: a missing thumbnail shows the file's name
// instead, and `rev` going up (new thumbnails made) makes it try again.
Item {
    id: root
    property var entry: null          // { kind, path, thumb, name }
    property int rev: 0
    property string fallbackFont: Theme.mono
    property color fallbackColor: Theme.overlay0
    property bool dim: false          // Signal: tiles off the cursor sit back a little

    property bool failed: false
    onRevChanged: failed = false
    onEntryChanged: failed = false

    clip: true

    Image {
        id: img
        anchors.fill: parent
        source: root.entry && !root.failed ? "file://" + root.entry.thumb : ""
        sourceSize.width: 480
        sourceSize.height: 270
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        opacity: status !== Image.Ready ? 0 : root.dim ? 0.78 : 1
        onStatusChanged: if (status === Image.Error) root.failed = true
        Behavior on opacity { NumberAnimation { duration: Theme.duration } }
    }

    Text {
        anchors.fill: parent
        anchors.margins: 10
        visible: img.status !== Image.Ready
        text: root.entry ? root.entry.name : ""
        wrapMode: Text.WrapAnywhere
        maximumLineCount: 3
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: root.fallbackFont
        font.pixelSize: 10
        color: root.fallbackColor
    }
}
