import QtQuick
import ".."

// KIT · ChannelRow — one device in a patch bay: is it the default, its name,
// where it lives, and its level.
//
//   OUT  ▸ speakers · headphones                    (section, first row only)
//   ▌● 01  Built-in Audio Analog Stereo   INT    ▕██████████▏ 100
//
//   level   0..1.5 (inputs may go past 100%: drawn in the warn colour)
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
    height: (section !== "" ? 22 : 0) + 30

    Text {
        visible: row.section !== ""
        x: 14
        y: 8
        text: row.section
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: 1.4
        color: Theme.surface2
    }

    Rectangle {
        y: row.section !== "" ? 22 : 0
        width: parent.width
        height: 30
        color: row.selected ? Theme.sigCell : "transparent"

        Rectangle {
            width: 2
            height: parent.height
            color: Theme.sigHot
            visible: row.selected
        }
        Row {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Text {
                width: 10
                text: row.isDefault ? "●" : "○"
                font.family: Theme.mono
                font.pixelSize: 10
                color: row.isDefault ? Theme.sigHot : Theme.surface1
            }
            Text {
                text: row.number
                font.family: Theme.mono
                font.pixelSize: 10
                color: Theme.surface2
            }
            Text {
                width: 250
                elide: Text.ElideRight
                text: row.name
                font.family: Theme.mono
                font.pixelSize: 12
                font.weight: row.isDefault || row.selected ? Font.Bold : Font.Normal
                color: row.selected ? Theme.sigHot : row.isDefault ? Theme.sigValue : Theme.sigLabel
            }
            Text {
                width: 34
                text: row.tag
                font.family: Theme.mono
                font.pixelSize: 9
                font.letterSpacing: 1
                color: Theme.sigLabel
            }
        }
        // level: ten cells; muted = the word instead of a number
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Meter {
                anchors.verticalCenter: parent.verticalCenter
                segments: 10
                cellWidth: 4
                cellHeight: 9
                bias: 0.02
                steps: 100
                value: row.level
                off: row.muted
                quiet: !row.isDefault
            }
            Text {
                width: 32
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
                text: row.muted ? "MUTE" : Math.round(row.level * 100)
                font.family: Theme.mono
                font.pixelSize: 10
                font.weight: row.muted ? Font.Bold : Font.Normal
                color: row.muted || row.level > 1.005 ? Theme.sigWarn : Theme.sigValue
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
