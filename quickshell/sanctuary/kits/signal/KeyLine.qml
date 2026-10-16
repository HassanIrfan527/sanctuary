import QtQuick
import ".."

// KIT · KeyLine — a key and what it does (KEYS, launcher help). Signal: the
// keys bold, the words dimmer. `dim` = filtered out (faint, still in place so
// nothing moves); `lit` = a match while filtering.
Row {
    id: line

    property string keys: ""
    property string text: ""
    property bool dim: false
    property bool lit: false
    property int keyWidth: 150
    property int textWidth: 176

    spacing: 12

    Text {
        width: line.keyWidth
        text: line.keys
        font.family: Theme.mono
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.6
        color: line.dim ? Theme.surface0 : line.lit ? Theme.sigHot : Theme.sigValue
    }
    Text {
        width: line.textWidth
        elide: Text.ElideRight
        text: line.text
        font.family: Theme.mono
        font.pixelSize: 10
        color: line.dim ? Theme.surface0 : Theme.subtext0
    }
}
