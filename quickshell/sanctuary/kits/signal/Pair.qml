import QtQuick
import ".."

// KIT · Pair — a line that names something and counts it:
//   #general · votel                              04
// Signal: both in bold value type; the name elides first.
Item {
    property string text: ""
    property string value: ""

    width: parent ? parent.width : 0
    height: 22
    Text {
        x: 14
        width: parent.width - 80
        elide: Text.ElideRight
        text: parent.text
        font.family: Theme.mono
        font.pixelSize: 12
        font.weight: Font.Bold
        color: Theme.sigValue
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        text: parent.value
        font.family: Theme.mono
        font.pixelSize: 12
        font.weight: Font.Bold
        color: Theme.sigValue
    }
}
