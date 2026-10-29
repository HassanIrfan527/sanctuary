import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Prompt — where you type to find (launcher, wallpaper search).
//   chevron      the mark before the text (▸ = the magnifier; a mode's prefix
//                is printed in pink)
//   placeholder  shown while empty
//   large        the launcher's line: a well sunk into the paper
// keyPressed(event) gets every key first (set accepted to keep it);
// edited(text) on every change. focusInput() / text to drive it.
// Lantern: a still block cursor; no blinking (no motion in this style).
Rectangle {
    id: prompt
    property string chevron: "▸"
    property string placeholder: ""
    property bool large: false
    property alias text: input.text
    signal keyPressed(var event)
    signal edited(string text)

    function focusInput() { input.forceActiveFocus(); }

    width: parent ? parent.width : 0
    height: large ? 44 : 38
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        color: Theme.lanSunk
        Rectangle { width: parent.width; height: 2; color: Qt.rgba(0, 0, 0, 0.28) }
    }
    Icon {
        id: glass
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        name: prompt.chevron === "▸" ? "search" : ""
        color: Theme.lanDim
    }
    LText {
        id: chev
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        visible: !glass.known
        text: G.plain(prompt.chevron)
        color: Theme.lanPink
    }
    TextInput {
        id: input
        anchors.left: glass.known ? glass.right : chev.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        onTextChanged: prompt.edited(text)
        font.family: Theme.lanFont
        font.pixelSize: Theme.lanSize
        font.hintingPreference: Font.PreferNoHinting
        renderType: Text.NativeRendering
        antialiasing: false
        color: Theme.lanBright
        selectionColor: Theme.lanPink
        selectedTextColor: Theme.lanOnPink
        cursorDelegate: Item { width: 0 }
        Keys.onPressed: event => prompt.keyPressed(event)
        Rectangle {   // the block cursor, still
            visible: input.activeFocus
            x: input.cursorRectangle.x
            y: 1
            width: 10
            height: input.height - 3
            color: Theme.lanBright
        }
    }
    LText {
        anchors.left: input.left
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        elide: Text.ElideRight
        visible: input.text === ""
        text: G.plain(prompt.placeholder)
        color: Theme.lanDim
    }
}
