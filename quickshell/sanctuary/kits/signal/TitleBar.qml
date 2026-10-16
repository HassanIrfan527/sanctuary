import QtQuick
import ".."

// KIT · TitleBar — a card's name line with things beside it (shelf tabs, where
// you are) and a readout at the right (002/017).
Item {
    id: bar
    property string title: ""
    property string detail: ""
    default property alias content: row.data

    width: parent ? parent.width : 0
    height: 30
    Row {
        id: row
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18
        Text {
            text: bar.title
            font.family: Theme.mono
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 2
            color: Theme.sigHot
        }
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: bar.detail
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: 1.4
        color: Theme.sigLabel
    }
}
