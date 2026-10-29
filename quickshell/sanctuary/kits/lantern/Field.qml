import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · Field — a text input with its label (password, run, …).
// Lantern: a well sunk into the paper (alarm frame on error), the label dim,
// the input bright, a block cursor that doesn't blink.
//   secret   draw dots instead of the text
//   accepted()  Enter · escaped()  Esc
Rectangle {
    id: field

    property string label: ""
    property bool secret: false
    property string tone: ""
    property alias text: input.text
    property alias inputEnabled: input.enabled
    signal accepted()
    signal escaped()

    function focusInput() { input.forceActiveFocus(); }

    width: parent ? parent.width : 200
    height: 36
    color: Theme.lanSunk
    Rectangle { width: parent.width; height: 2; color: Qt.rgba(0, 0, 0, 0.28) }
    Rectangle {
        anchors.fill: parent
        visible: field.tone === "alarm"
        color: "transparent"
        border.width: 2
        border.color: Theme.lanAlarm
    }

    LText {
        id: prompt
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: G.plain(field.label.toLowerCase())
        color: Theme.lanDim
    }
    TextInput {
        id: input
        x: prompt.x + prompt.implicitWidth + 12
        y: Math.round((field.height - height) / 2) + 1
        width: field.width - prompt.implicitWidth - 34
        focus: true
        echoMode: field.secret ? TextInput.Password : TextInput.Normal
        passwordCharacter: "*"
        font.family: Theme.lanFont
        font.pixelSize: Theme.lanSize
        font.hintingPreference: Font.PreferNoHinting
        renderType: Text.NativeRendering
        antialiasing: false
        color: Theme.lanBright
        selectionColor: Theme.lanPink
        selectedTextColor: Theme.lanOnPink
        clip: true
        cursorDelegate: Item { width: 0 }
        Keys.onReturnPressed: field.accepted()
        Keys.onEnterPressed: field.accepted()
        Keys.onEscapePressed: field.escaped()
        Rectangle {   // the block cursor, still
            visible: input.activeFocus
            x: input.cursorRectangle.x
            y: 2
            width: 10
            height: input.height - 4
            color: Theme.lanBright
        }
    }
}
