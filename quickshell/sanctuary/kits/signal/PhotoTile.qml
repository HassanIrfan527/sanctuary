import QtQuick
import ".."

// KIT · PhotoTile — one tile on a contact sheet (the wallpaper picker): a
// picture, or a folder (a drawn folder over its first picture, its name, how
// many it holds), or the way up.
//   kind      "file" | "folder" | "up"
//   entry     what Thumb loads ({ kind, path, thumb, name }) · rev  retry stamp
//   name, sub the folder tile's two lines
//   now       it's the wallpaper you have now · live  it's a live one
// Signal: a cell with a hairline (2px hot when selected); files off the cursor
// sit back a little.
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

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        color: Theme.sigCell
        border.width: tile.selected ? 2 : 1
        border.color: tile.selected ? Theme.sigHot : Theme.sigRule

        Thumb {
            visible: tile.isFile
            anchors.fill: parent
            anchors.margins: tile.selected ? 2 : 1
            entry: tile.isFile ? tile.entry : null
            rev: tile.rev
            fallbackFont: Theme.mono
            fallbackColor: Theme.sigLabel
            dim: !tile.selected
        }

        // A folder: the first picture inside, barely there behind a drawn
        // folder, its name, and how many it holds.
        Thumb {
            visible: tile.kind === "folder"
            anchors.fill: parent
            anchors.margins: tile.selected ? 2 : 1
            opacity: tile.selected ? 0.22 : 0.12
            entry: visible ? tile.entry : null
            rev: tile.rev
            fallbackColor: "transparent"
        }
        Column {
            visible: !tile.isFile
            anchors.centerIn: parent
            spacing: 7
            FolderGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 46
                height: 34
                line: tile.selected ? Theme.sigHot : Theme.sigLabel
                fill: Theme.sigCell
                label: tile.kind === "up" ? ".." : ""
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, tile.width - 30)
                elide: Text.ElideMiddle
                text: tile.name.toUpperCase()
                font.family: Theme.mono
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.4
                color: tile.selected ? Theme.sigValue : Theme.subtext0
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, tile.width - 30)
                elide: Text.ElideLeft
                text: tile.sub
                font.family: Theme.mono
                font.pixelSize: 8
                font.letterSpacing: 1.2
                color: Theme.sigLabel
            }
        }

        Rectangle {   // status tags, top-left
            visible: tile.now || (tile.isFile && tile.live)
            x: 6
            y: 6
            width: tagText.implicitWidth + 10
            height: 15
            color: Theme.sigFill
            Text {
                id: tagText
                anchors.centerIn: parent
                text: tile.now ? "● NOW" : "▶ LIVE"
                font.family: Theme.mono
                font.pixelSize: 8
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                color: tile.now ? Theme.sigHot : Theme.sigLabel
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
