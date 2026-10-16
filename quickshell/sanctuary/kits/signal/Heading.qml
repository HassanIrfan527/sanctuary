import QtQuick
import ".."

// KIT · Heading — a group's name inside a panel (a KEYS section, …).
// Signal: bold small caps, dim; hot when `lit` (something in the group matches).
Text {
    property bool lit: false
    bottomPadding: 2
    font.family: Theme.mono
    font.pixelSize: 9
    font.weight: Font.Bold
    font.letterSpacing: 1.6
    color: lit ? Theme.sigHot : Theme.sigLabel
}
