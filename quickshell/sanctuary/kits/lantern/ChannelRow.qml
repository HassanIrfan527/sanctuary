import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · ChannelRow — one device in a patch bay: is it the default, its name,
// where it lives, and its level.
//
//   out  ▸ speakers · headphones                    (section, first row only)
//   ▸ ■ 01  Built-in Audio Analog Stereo   int   [▮▮▮▮▮▮▮▮▮▮] 100
//
//   level   0..1.5 (inputs may go past 100%: the number turns warn)
// Lantern: the default device is yours (a pink square); the level is sound
// (cyan pips); the selected row raised with the pink pointer.
Item {
    id: row

    property string section: ""
    property bool isDefault: false
    property string number: ""
    property string name: ""
    property string tag: ""
    property real level: 0
    property bool muted: false
    property bool selected: false

    signal hovered()
    signal clicked()
    signal rightClicked()
    signal wheeled(int direction)

    width: parent ? parent.width : 0
    height: (section !== "" ? 28 : 0) + 36

    LText {
        visible: row.section !== ""
        x: 12
        y: 6
        text: G.plain(row.section.toLowerCase())
        color: Theme.lanAmber
    }

    Rectangle {
        y: row.section !== "" ? 28 : 0
        width: parent.width
        height: 36
        color: row.selected ? Theme.lanRaised : "transparent"

        Icon {
            x: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: row.selected
            name: "chevron-right"
            color: Theme.lanPink
        }
        Row {
            x: 26
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Rectangle {   // the default: a pink square; the rest an empty well
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 10
                color: row.isDefault ? Theme.lanPink : Theme.lanSunk
            }
            LText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: row.number
                color: Theme.lanDim
            }
            LText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                width: 240
                elide: Text.ElideRight
                text: G.plain(row.name)
                color: row.selected ? Theme.lanBright : row.isDefault ? Theme.lanText : Theme.lanDim
            }
            LText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                width: 34
                text: G.plain(row.tag.toLowerCase())
                color: Theme.lanDim
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Meter {
                anchors.verticalCenter: parent.verticalCenter
                segments: 10
                cellWidth: 4
                cellHeight: 10
                bias: 0.02
                steps: 100
                value: row.level
                off: row.muted
                quiet: !row.isDefault
            }
            LText {
                width: 36
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: row.muted ? "mute" : Math.round(row.level * 100)
                color: row.muted || row.level > 1.005 ? Theme.lanWarn : Theme.lanText
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered()
            onClicked: mouse => mouse.button === Qt.RightButton ? row.rightClicked() : row.clicked()
            onWheel: wheel => row.wheeled(wheel.angleDelta.y > 0 ? 1 : -1)
        }
    }
}
