import QtQuick
import ".."

// KIT · Prompt — where you type to find (launcher, wallpaper search).
//   chevron      the mark before the text (▸, or a mode's prefix)
//   placeholder  shown while empty
//   large        the launcher's console line: taller, on a cell, bigger type
// keyPressed(event) gets every key first (set accepted to keep it);
// edited(text) on every change. focusInput() / text to drive it.
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
    height: large ? 42 : 34
    color: large ? Theme.sigCell : "transparent"

    Text {
        id: chev
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        text: prompt.chevron
        font.family: Theme.mono
        font.pixelSize: prompt.large ? 15 : 13
        font.weight: prompt.large ? Font.Bold : Font.Normal
        color: Theme.sigHot
    }
    TextInput {
        id: input
        anchors.left: chev.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        onTextChanged: prompt.edited(text)
        font.family: Theme.mono
        font.pixelSize: prompt.large ? 15 : 13
        color: Theme.sigValue
        selectionColor: Theme.surface1
        cursorDelegate: Rectangle { width: prompt.large ? 8 : 7; color: Theme.sigHot; opacity: 0.8 }
        Keys.onPressed: event => prompt.keyPressed(event)
    }
    Text {
        anchors.left: chev.right
        anchors.leftMargin: prompt.large ? 18 : 10
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === ""
        text: prompt.placeholder
        font.family: Theme.mono
        font.pixelSize: prompt.large ? 12 : 13
        color: Theme.surface2
    }
}
