import QtQuick
import ".."

// KIT · KeyHints — key hints that are also buttons, along a panel's foot:
//   [c] clear all   [d] dnd off   [esc] close
// hints: [{ key, label, act() }]
Item {
    id: foot
    property var hints: []

    width: parent ? parent.width : 0
    height: 36
    Rectangle {
        width: parent.width
        height: 1
        color: Theme.sigRule
    }
    Row {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
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
                    Text {
                        text: "[" + hint.modelData.key + "]"
                        font.family: Theme.mono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.sigHot
                    }
                    Text {
                        text: hint.modelData.label
                        font.family: Theme.mono
                        font.pixelSize: 10
                        color: hintArea.containsMouse ? Theme.sigValue : Theme.sigLabel
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
