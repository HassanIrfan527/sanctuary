import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · TitleBar — a card's name line with things beside it (shelf tabs, where
// you are) and a readout at the right (002/017).
Item {
    id: bar
    property string title: ""
    property string detail: ""
    default property alias content: row.data

    width: parent ? parent.width : 0
    height: 34
    Row {
        id: row
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18
        LText {
            text: G.plain(bar.title.toLowerCase())
            color: Theme.lanBright
        }
    }
    LText {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: G.plain(bar.detail)
        color: Theme.lanDim
    }
}
