import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Masthead — the top of the launcher: the style's name as a wordmark,
// a subtitle, the time and a readout. `kick()` when you typed; `active` =
// on screen. Lantern: a hanging sign — the name in the display face, lamp-lit,
// beside a lantern; the time in amber at the right. It doesn't move (kick and
// active do nothing here).
//
//   ▣ LANTERN                                          10:41
//     sanctuary // console                 citadel · up 3h 12m
Item {
    id: head
    property string word: ""
    property string subtitle: ""
    property string time: ""
    property string detail: ""
    property bool active: false

    function kick() { }

    width: parent ? parent.width : 0
    height: 76

    Icon {
        id: lamp
        x: 16
        y: 14
        name: Theme.harvest ? "sun" : "moon"
        size: 48
        color: Theme.lanAmber
    }
    LText {
        id: mark
        x: 76
        y: 12
        big: true
        text: G.plain(head.word)
        color: Theme.lanLamp
    }
    LText {
        x: 76
        anchors.top: mark.bottom
        text: G.plain(head.subtitle.toLowerCase())
        color: Theme.lanDim
    }
    Column {
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: 12
        spacing: 0
        LText {
            anchors.right: parent.right
            big: true
            text: G.plain(head.time)
            color: Theme.lanAmber
        }
        LText {
            anchors.right: parent.right
            text: G.plain(head.detail.toLowerCase())
            color: Theme.lanDim
        }
    }
    Rectangle {   // the sign's lower edge: a groove
        anchors.bottom: parent.bottom
        x: 8
        width: parent.width - 16
        height: 2
        color: Theme.lanSunk
    }
}
