import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Pair — a line that names something and counts it:
//   #general · votel                              04
Item {
    property string text: ""
    property string value: ""

    width: parent ? parent.width : 0
    height: 26
    LText {
        x: 12
        width: parent.width - 80
        elide: Text.ElideRight
        text: G.plain(parent.text)
        color: Theme.lanBright
    }
    LText {
        anchors.right: parent.right
        anchors.rightMargin: 12
        text: G.plain(parent.value)
        color: Theme.lanText
    }
}
