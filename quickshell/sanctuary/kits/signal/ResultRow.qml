import QtQuick
import ".."

// KIT · ResultRow — one launcher result: a mark, a title, what it is, a tag.
//   mark      a number (01) when `numbered`, else a glyph (◆ ⇄ =)
//   big       the answer row (CALC): taller, bigger title
//   quiet     a hint, not a result: dim title, never selected
//   tagLit    the tag lights (DESK, COPY, PIN)
//   tagTight  no letter spacing on the tag (12× launch counts)
Rectangle {
    id: row
    property string mark: ""
    property bool numbered: false
    property string title: ""
    property string sub: ""
    property string tag: ""
    property bool selected: false
    property bool big: false
    property bool quiet: false
    property bool tagLit: false
    property bool tagTight: false
    signal hovered()
    signal clicked(bool shift)

    width: parent ? parent.width : 0
    height: big ? 40 : 30
    color: selected ? Theme.sigCell : "transparent"

    Rectangle {
        width: 2
        height: parent.height
        color: Theme.sigHot
        visible: row.selected
    }
    Row {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14
        Text {
            width: 16
            anchors.verticalCenter: parent.verticalCenter
            text: row.mark
            font.family: Theme.mono
            font.pixelSize: row.numbered ? 10 : 12
            color: row.numbered ? Theme.surface2 : row.selected ? Theme.sigHot : Theme.sigLabel
        }
        Text {
            width: row.big ? 300 : 230
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: row.title
            font.family: Theme.mono
            font.pixelSize: row.big ? 20 : 12
            font.weight: row.selected || row.big ? Font.Bold : Font.Normal
            color: row.quiet ? Theme.sigLabel : row.selected || row.big ? Theme.sigHot : Theme.sigValue
        }
        Text {
            width: row.big ? 230 : 300
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: row.sub
            font.family: Theme.mono
            font.pixelSize: 10
            color: Theme.sigLabel
        }
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: row.tag
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: row.tagTight ? 0 : 1.2
        color: row.tagLit ? Theme.sigHot : Theme.surface2
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: row.quiet ? Qt.ArrowCursor : Qt.PointingHandCursor
        onEntered: row.hovered()
        onClicked: mouse => row.clicked(mouse.modifiers & Qt.ShiftModifier)
    }
}
