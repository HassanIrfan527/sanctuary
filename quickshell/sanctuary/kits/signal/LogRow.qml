import QtQuick
import ".."

// KIT · LogRow — one past notification in the centre:
//   22:41  discord     Summary in bold
//                      the body, two lines at most…
// clicked() / rightClicked(). critical = marked in the alarm colour.
Rectangle {
    id: row
    property string time: ""
    property string app: ""
    property string summary: ""
    property string body: ""
    property bool critical: false
    signal clicked()
    signal rightClicked()

    width: parent ? parent.width : 0
    height: rcol.implicitHeight + 14
    color: area.containsMouse ? Theme.sigCell : "transparent"

    Rectangle {
        x: 0
        width: 2
        height: parent.height
        color: row.critical ? Theme.sigAlarm : Theme.sigHot
        visible: area.containsMouse || row.critical
    }
    Column {
        id: rcol
        x: 14
        y: 7
        width: parent.width - 28
        spacing: 2

        Row {
            spacing: 10
            Text {
                text: row.time
                font.family: Theme.mono
                font.pixelSize: 10
                color: Theme.sigLabel
            }
            Text {
                width: 90
                elide: Text.ElideRight
                text: row.app
                font.family: Theme.mono
                font.pixelSize: 10
                color: row.critical ? Theme.sigAlarm : Theme.sigHot
            }
            Text {
                width: rcol.width - 150
                elide: Text.ElideRight
                text: row.summary
                font.family: Theme.mono
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.sigValue
            }
        }
        Text {
            x: 140
            width: rcol.width - 140
            visible: text !== ""
            text: row.body
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.family: Theme.mono
            font.pixelSize: 10
            color: Theme.subtext0
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        x: 14
        width: parent.width - 28
        height: 1
        color: Theme.sigRule
        opacity: 0.6
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? row.rightClicked() : row.clicked()
    }
}
