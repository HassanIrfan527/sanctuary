import QtQuick
import ".."

// KIT · SideHeader — a side panel's name and its readout, with a rule under.
// detailTone "warn" for a state you'd want to notice (DND ON).
Item {
    property string title: ""
    property string detail: ""
    property string detailTone: ""

    width: parent ? parent.width : 0
    height: 40
    Text {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        text: parent.title
        font.family: Theme.mono
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 2
        color: Theme.sigHot
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: parent.detail
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: 1.2
        color: parent.detailTone === "warn" ? Theme.sigWarn : Theme.sigLabel
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.sigRule
    }
}
