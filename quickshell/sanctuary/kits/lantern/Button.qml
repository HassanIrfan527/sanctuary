import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Button — something to press (transport, actions). `hint` = its key,
// printed underneath. Lantern: a little wooden button; a glyph it knows
// (▶ ‖ ▶|) is drawn as its icon. Hover = pink (it's yours to press).
Item {
    id: btn
    property string text: ""
    property string hint: ""
    signal clicked()

    width: 56
    height: 36
    Rectangle { x: 2; width: parent.width - 4; height: parent.height; color: Theme.lanOutline }
    Rectangle { y: 2; width: parent.width; height: parent.height - 4; color: Theme.lanOutline }
    Rectangle {
        x: 2
        y: 2
        width: parent.width - 4
        height: parent.height - 4
        color: area.containsMouse ? Theme.lanPink : Theme.lanWood
        Rectangle { width: parent.width; height: 2; color: area.containsMouse ? Theme.lanPinkHi : Theme.lanWoodLit }
    }
    Icon {
        id: glyph
        anchors.centerIn: parent
        name: btn.text
        color: area.containsMouse ? Theme.lanOnPink : "#fff0cc"
    }
    LText {
        anchors.centerIn: parent
        visible: !glyph.known
        text: G.plain(btn.text)
        color: area.containsMouse ? Theme.lanOnPink : "#fff0cc"
    }
    LText {
        anchors.top: parent.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        visible: btn.hint !== ""
        text: G.plain(btn.hint)
        color: Theme.lanDim
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
