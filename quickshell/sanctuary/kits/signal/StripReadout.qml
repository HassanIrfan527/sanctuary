import QtQuick
import ".."

// KIT · StripReadout — a live value at the start of a button strip (● 03:12).
// Signal: bold, in the tone's colour, a hairline after it.
Item {
    property string text: ""
    property string tone: ""

    width: readout.implicitWidth + 24
    height: 32
    Text {
        id: readout
        anchors.centerIn: parent
        text: parent.text
        font.family: Theme.mono
        font.pixelSize: 12
        font.weight: Font.Bold
        color: parent.tone === "warn" ? Theme.sigWarn : parent.tone === "alarm" ? Theme.sigAlarm : Theme.sigValue
    }
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 12
        color: Theme.sigRule
    }
}
