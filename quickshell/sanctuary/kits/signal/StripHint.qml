import QtQuick
import ".."

// KIT · StripHint — an instruction on a button strip (DRAG A REGION).
Item {
    property string text: ""
    width: hint.implicitWidth + 24
    height: 32
    Text {
        id: hint
        anchors.centerIn: parent
        text: parent.text
        font.family: Theme.mono
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        color: Theme.sigValue
    }
}
