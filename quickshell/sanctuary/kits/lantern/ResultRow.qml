import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · ResultRow — one launcher result: a slot, a title, what it is, a tag.
//   mark      a number (01) when `numbered`, else a glyph (◆ ⇄ =) drawn as its icon
//   big       the answer row (calc): the display face, lamp-lit
//   quiet     a hint, not a result: dim, never selected
//   tagLit    the tag lights (desk, copy, pin)
//   tagTight  (Lantern: no letter spacing anywhere; ignored)
// Lantern: a shop row — the icon in a slot sunk into the paper; the selected
// row raised, its slot framed pink with the selected-tool marks.
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

    // web results say which engine by their tag, not the glyph
    readonly property string iconName: ({ DUC: "search", YOU: "play", GIT: "github", WIK: "book-open", URL: "external-link" })[tag] || mark

    width: parent ? parent.width : 0
    height: big ? 48 : 40
    color: selected ? Theme.lanRaised : "transparent"

    Row {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        Slot {
            anchors.verticalCenter: parent.verticalCenter
            on: row.selected
            Icon {
                id: glyph
                anchors.centerIn: parent
                visible: !row.numbered && known
                name: row.numbered ? "" : row.iconName
                color: row.selected ? Theme.lanPink : Theme.lanDim
            }
            LText {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                visible: row.numbered || !glyph.known
                text: G.plain(row.mark)
                color: row.selected ? Theme.lanPink : Theme.lanDim
            }
        }
        LText {
            width: row.big ? 300 : 230
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            big: row.big
            elide: Text.ElideRight
            text: G.plain(row.title)
            color: row.quiet ? Theme.lanDim : row.big ? Theme.lanLamp : row.selected ? Theme.lanBright : Theme.lanText
        }
        LText {
            width: row.big ? 200 : 270
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            elide: Text.ElideRight
            text: G.plain(row.sub)
            color: Theme.lanDim
        }
    }
    LText {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: G.plain(row.tag.toLowerCase())
        color: row.tagLit ? Theme.lanPink : Theme.lanDim
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: row.quiet ? Qt.ArrowCursor : Qt.PointingHandCursor
        onEntered: row.hovered()
        onClicked: mouse => row.clicked(mouse.modifiers & Qt.ShiftModifier)
    }
}
