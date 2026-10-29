import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · LogRow — one past notification in the centre:
//   ✉ Summary, bright                       discord · 22:41
//     the body, two lines at most…
// clicked() / rightClicked(). critical = the alarm colour.
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
    height: rcol.implicitHeight + 16
    color: area.containsMouse ? Theme.lanRaised : "transparent"

    Column {
        id: rcol
        x: 12
        y: 8
        width: parent.width - 24
        spacing: 2

        Item {
            width: parent.width
            height: 24
            Icon {
                id: appIcon
                name: row.critical ? "bell-ring" : (row.app.toLowerCase() || "bell")
                color: row.critical ? Theme.lanAlarm : Theme.lanDim
            }
            LText {
                x: appIcon.known ? 32 : 0
                y: 2
                width: parent.width - x - timeText.implicitWidth - 12
                elide: Text.ElideRight
                text: G.plain(row.summary)
                color: row.critical ? Theme.lanAlarm : Theme.lanBright
            }
            LText {
                id: timeText
                anchors.right: parent.right
                y: 2
                text: G.plain((row.app !== "" ? row.app.toLowerCase() + " · " : "") + row.time)
                color: Theme.lanDim
            }
        }
        LText {
            x: 32
            width: rcol.width - 32
            visible: text !== ""
            text: G.plain(row.body)
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.lanText
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        x: 8
        width: parent.width - 16
        height: 2
        color: Theme.lanSunk
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
