import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · StripHint — an instruction on a button strip (drag a region).
Item {
    property string text: ""
    width: hint.implicitWidth + 24
    height: 36
    LText {
        id: hint
        anchors.centerIn: parent
        text: G.plain(parent.text.toLowerCase())
        color: Theme.lanText
    }
}
