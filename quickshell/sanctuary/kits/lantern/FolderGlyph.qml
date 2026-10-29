import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · FolderGlyph — a folder. Lantern: the Pixelarticons folder at 2×,
// in `line`; `label` (".." for the way up) printed beneath it.
Item {
    id: root
    property color line: Theme.lanDim
    property color fill: "transparent"
    property int stroke: 1
    property string label: ""
    property string labelFont: Theme.lanFont
    property int labelSize: Theme.lanSize
    property int labelWeight: Font.Normal

    implicitWidth: 48
    implicitHeight: 48 + (label !== "" ? 20 : 0)

    Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        name: "folder"
        size: 48
        color: root.line
    }
    LText {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 44
        visible: root.label !== ""
        text: G.plain(root.label)
        color: root.line
    }
}
