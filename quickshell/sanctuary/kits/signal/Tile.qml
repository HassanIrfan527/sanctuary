import QtQuick
import Quickshell.Widgets
import ".."

// KIT · Tile — one app in a strip of them (the column strip): its number, its
// icon, its name and window title.
//   lit       the one you're in      selected  the keyboard cursor
//   count     windows stacked in it (×2 shows when > 1)
//   last      no rule after it
// Signal: a channel strip cell — a lit cell gets the wash and a top bar.
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

    width: 96
    height: 84

    Rectangle {
        anchors.fill: parent
        color: cell.lit ? Theme.sigCell : "transparent"
    }
    Rectangle {
        width: parent.width
        height: 2
        color: Theme.sigHot
        visible: cell.lit
    }
    Rectangle {   // the rule between channels
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.sigRule
        visible: !cell.last
    }
    Text {
        x: 8
        y: 6
        text: cell.number
        font.family: Theme.mono
        font.pixelSize: 11
        font.weight: Font.Bold
        color: cell.lit ? Theme.sigHot : Theme.sigLabel
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: 7
        visible: cell.count > 1
        text: "×" + cell.count
        font.family: Theme.mono
        font.pixelSize: 9
        color: Theme.sigLabel
    }
    IconImage {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 14
        implicitSize: 28
        source: cell.icon
        opacity: cell.lit || cell.selected ? 1 : 0.7
    }
    Column {
        y: 48
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 12
        spacing: 2
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: cell.name
            font.family: Theme.mono
            font.pixelSize: 10
            font.weight: cell.lit || cell.selected ? Font.Bold : Font.Normal
            color: cell.selected ? Theme.sigHot : cell.lit ? Theme.sigValue : Theme.sigLabel
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: cell.title
            font.family: Theme.mono
            font.pixelSize: 8
            color: Theme.surface2
        }
    }
    Rectangle {   // the keyboard cursor
        anchors.fill: parent
        anchors.margins: 2
        color: "transparent"
        border.width: 1
        border.color: Theme.sigHot
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
