import QtQuick
import ".."

// KIT · Picture — a framed image (cover art, a portrait). Hidden while there
// is no source. Signal: a cell-coloured box with a hairline edge.
Rectangle {
    property alias source: img.source
    property int size: 84

    visible: source != ""
    width: visible ? size : 0
    height: size
    color: Theme.sigCell
    border.width: 1
    border.color: Theme.sigRule
    Image {
        id: img
        anchors.fill: parent
        anchors.margins: 1
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: parent.size * 2
        sourceSize.height: parent.size * 2
    }
}
