import QtQuick
import ".."

// KIT · PersonRow — someone in a call: their name, whether they're speaking,
// and what they've switched off.
//   ▌harry · you                                   ●     speaking
//    ali                                         MUTE
//   mark       the right-hand word or dot ("", "●", "MUTE", "DEAF")
//   markAlarm  the mark is something switched off (alarm colour)
Item {
    id: who
    property string name: ""
    property bool speaking: false
    property string mark: ""
    property bool markAlarm: false

    width: parent ? parent.width : 0
    height: 22
    Rectangle {
        width: 2
        height: parent.height
        color: Theme.sigHot
        visible: who.speaking
    }
    Text {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 90
        elide: Text.ElideRight
        text: who.name
        font.family: Theme.mono
        font.pixelSize: 11
        color: who.speaking ? Theme.sigHot : Theme.sigValue
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: who.mark
        font.family: Theme.mono
        font.pixelSize: 9
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        color: who.markAlarm ? Theme.sigAlarm : Theme.sigHot
    }
}
