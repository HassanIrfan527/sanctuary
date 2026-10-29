import QtQuick
import ".."

// KIT · Picture — a framed image (cover art). Hidden while there is no
// source. Lantern: sunk in a slot, and drawn in fat square pixels (4× from
// 64px up, else 2×), so a photo sits in the pixel world instead of on it.
Rectangle {
    property alias source: img.source
    property int size: 84

    readonly property int px: size >= 64 ? 4 : 2
    visible: source != ""
    width: visible ? size : 0
    height: size
    color: Theme.lanSunk
    Image {
        id: img
        x: 2
        y: 2
        width: parent.size - 4
        height: parent.size - 4
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: false
        mipmap: false
        sourceSize.width: Math.floor((parent.size - 4) / parent.px)
        sourceSize.height: Math.floor((parent.size - 4) / parent.px)
    }
}
