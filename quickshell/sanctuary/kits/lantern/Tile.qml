import QtQuick
import Quickshell.Widgets
import "Glyphs.js" as G
import ".."

// KIT · Tile — one app in a strip of them (the column strip): its number, its
// icon, its name and window title.
//   lit       the one you're in      selected  the keyboard cursor
//   count     windows stacked in it (×2 shows when > 1)
//   last      no groove after it
// Lantern: a cell of paper; the one you're in is raised; the cursor is the
// pink frame with the selected-tool marks.
Item {
    id: cell
    property string number: ""
    property int count: 1
    property string icon: ""
    property string name: ""
    property string title: ""
    property bool lit: false
    property bool selected: false
    property bool last: false
    signal hovered()
    signal clicked()

    width: 104
    height: 96

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        color: cell.lit ? Theme.lanRaised : "transparent"
    }
    Rectangle {   // the groove between columns
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: parent.height - 24
        color: Theme.lanSunk
        visible: !cell.last
    }
    LText {
        x: 10
        y: 6
        text: cell.number
        color: cell.lit ? Theme.lanPink : Theme.lanDim
    }
    LText {
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 6
        visible: cell.count > 1
        text: "×" + cell.count
        color: Theme.lanDim
    }
    IconImage {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 14
        implicitSize: 32
        source: cell.icon
        opacity: cell.lit || cell.selected ? 1 : 0.7
    }
    Column {
        y: 50
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 16
        spacing: 0
        LText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: G.plain(cell.name)
            color: cell.selected ? Theme.lanPink : cell.lit ? Theme.lanBright : Theme.lanText
        }
        LText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: G.plain(cell.title)
            color: Theme.lanDim
        }
    }
    Rectangle {   // the keyboard cursor
        anchors.fill: parent
        anchors.margins: 4
        color: "transparent"
        border.width: 2
        border.color: Theme.lanPink
        visible: cell.selected
    }
    Corners {
        anchors.fill: parent
        visible: cell.selected
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: cell.hovered()
        onClicked: cell.clicked()
    }
}
