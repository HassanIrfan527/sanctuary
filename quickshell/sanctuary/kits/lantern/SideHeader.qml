import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · SideHeader — a side panel's name and its readout, a groove under.
// Lantern: the name in the display face, lamp-lit; detailTone "warn" for a
// state you'd want to notice (DND ON).
Item {
    property string title: ""
    property string detail: ""
    property string detailTone: ""

    width: parent ? parent.width : 0
    height: 48
    LText {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        big: true
        text: G.plain(parent.title.toLowerCase())
        color: Theme.lanLamp
    }
    LText {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: G.plain(parent.detail.toLowerCase())
        color: parent.detailTone === "warn" ? Theme.lanWarn : Theme.lanDim
    }
    Rectangle {
        anchors.bottom: parent.bottom
        x: 8
        width: parent.width - 16
        height: 2
        color: Theme.lanSunk
    }
}
