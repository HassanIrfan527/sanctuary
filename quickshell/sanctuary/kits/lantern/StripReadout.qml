import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · StripReadout — a live value at the start of a button strip (● 03:12),
// in the tone's colour, a groove after it.
Item {
    property string text: ""
    property string tone: ""

    width: readout.implicitWidth + 24
    height: 36
    LText {
        id: readout
        anchors.centerIn: parent
        text: G.plain(parent.text)
        color: parent.tone === "warn" ? Theme.lanWarn : parent.tone === "alarm" ? Theme.lanAlarm : Theme.lanText
    }
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 20
        color: Theme.lanSunk
    }
}
