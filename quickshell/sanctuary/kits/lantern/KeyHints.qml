import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · KeyHints — key hints that are also buttons, along a panel's foot:
//   [c] clear all   [d] dnd off   [esc] close
// hints: [{ key, label, act() }]
Item {
    id: foot
    property var hints: []

    width: parent ? parent.width : 0
    height: 40
    Rectangle {
        x: 8
        width: parent.width - 16
        height: 2
        color: Theme.lanSunk
    }
    Row {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        spacing: 18

        Repeater {
            model: foot.hints
            delegate: Item {
                id: hint
                required property var modelData
                width: hintRow.implicitWidth
                height: hintRow.implicitHeight
                Row {
                    id: hintRow
                    spacing: 6
                    LText {
                        text: G.plain(hint.modelData.key)
                        color: Theme.lanPink
                    }
                    LText {
                        text: G.plain(hint.modelData.label)
                        color: hintArea.containsMouse ? Theme.lanBright : Theme.lanDim
                    }
                }
                MouseArea {
                    id: hintArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hint.modelData.act()
                }
            }
        }
    }
}
