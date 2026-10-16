import QtQuick
import ".."

// KIT · Field — a text input with its label (PASSWORD, RUN, …).
// Signal: a cell-coloured box, hairline edge (alarm on error), the label in
// small caps, the input after it.
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
    height: 32
    color: Theme.sigCell
    border.width: 1
    border.color: tone === "alarm" ? Theme.sigAlarm : Theme.sigRule

    Text {
        id: prompt
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        text: field.label
        font.family: Theme.mono
        font.pixelSize: 9
        font.weight: Font.Bold
        font.letterSpacing: 1.4
        color: Theme.sigLabel
    }
    TextInput {
        id: input
        x: prompt.x + prompt.implicitWidth + 12
        y: (field.height - height) / 2
        width: field.width - prompt.implicitWidth - 34
        focus: true
        echoMode: field.secret ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        font.family: Theme.mono
        font.pixelSize: 14
        color: Theme.sigValue
        selectionColor: Theme.surface1
        clip: true
        Keys.onReturnPressed: field.accepted()
        Keys.onEnterPressed: field.accepted()
        Keys.onEscapePressed: field.escaped()
    }
}
