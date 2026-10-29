import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · PhotoTile — one tile on a contact sheet (the wallpaper picker): a
// picture, or a folder (the pixel folder over its first picture, its name,
// how many it holds), or the way up.
//   kind      "file" | "folder" | "up"
//   entry     what Thumb loads ({ kind, path, thumb, name }) · rev  retry stamp
//   name, sub the folder tile's two lines
//   now       it's the wallpaper you have now · live  it's a live one
// Lantern: a slot sunk into the paper; the selected one framed pink with the
// selected-tool marks; "now" is a pink tag (it's yours).
Item {
    id: tile
    property string kind: "file"
    property var entry: null
    property int rev: 0
    property string name: ""
    property string sub: ""
    property bool selected: false
    property bool now: false
    property bool live: false
    signal hovered()
    signal clicked()

    readonly property bool isFile: kind === "file"

    Slot {
        id: slot
        anchors.fill: parent
        anchors.margins: 6
        on: tile.selected

        Thumb {
            visible: tile.isFile
            anchors.fill: parent
            anchors.margins: 2
            z: -1
            entry: tile.isFile ? tile.entry : null
            rev: tile.rev
            dim: !tile.selected
        }

        // a folder: its first picture, barely there, behind the folder
        Thumb {
            visible: tile.kind === "folder"
            anchors.fill: parent
            anchors.margins: 2
            z: -1
            opacity: tile.selected ? 0.22 : 0.12
            entry: visible ? tile.entry : null
            rev: tile.rev
            fallbackColor: "transparent"
        }
        Column {
            visible: !tile.isFile
            anchors.centerIn: parent
            spacing: 2
            FolderGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                line: tile.selected ? Theme.lanPink : Theme.lanDim
                label: tile.kind === "up" ? ".." : ""
            }
            LText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, tile.width - 30)
                elide: Text.ElideMiddle
                text: G.plain(tile.name.toLowerCase())
                color: tile.selected ? Theme.lanBright : Theme.lanText
            }
            LText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, tile.width - 30)
                elide: Text.ElideLeft
                text: G.plain(tile.sub)
                color: Theme.lanDim
            }
        }

        Rectangle {   // status tags, top-left
            visible: tile.now || (tile.isFile && tile.live)
            x: 6
            y: 6
            width: tagText.implicitWidth + 12
            height: 20
            color: tile.now ? Theme.lanPink : Theme.lanSunk
            LText {
                id: tagText
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: tile.now ? "now" : "live"
                color: tile.now ? Theme.lanOnPink : Theme.lanDim
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.hovered()
        onClicked: tile.clicked()
    }
}
