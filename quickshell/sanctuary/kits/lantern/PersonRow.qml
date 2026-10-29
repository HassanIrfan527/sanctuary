import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · PersonRow — someone in a call: their name, whether they're speaking,
// and what they've switched off. Speaking is sound: cyan.
//   mark       the right-hand word or dot ("", "●", "MUTE", "DEAF")
//   markAlarm  the mark is something switched off (alarm colour)
Item {
    id: who
    property string name: ""
    property bool speaking: false
    property string mark: ""
    property bool markAlarm: false

    width: parent ? parent.width : 0
    height: 28
    Rectangle {
        x: 4
        width: 4
        height: parent.height
        color: Theme.lanSound
        visible: who.speaking
    }
    LText {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 90
        elide: Text.ElideRight
        text: G.plain(who.name)
        color: who.speaking ? Theme.lanSound : Theme.lanText
    }
    LText {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: G.plain(who.mark.toLowerCase())
        color: who.markAlarm ? Theme.lanAlarm : Theme.lanSound
    }
}
