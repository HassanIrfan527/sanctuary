import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · KeyLine — a key and what it does (KEYS, launcher help). The keys
// bright, the words in text colour. `dim` = filtered out (faint, still in
// place so nothing moves); `lit` = a match while filtering (pink: yours).
Row {
    id: line

    property string keys: ""
    property string text: ""
    property bool dim: false
    property bool lit: false
    property int keyWidth: 150
    property int textWidth: 176

    spacing: 12

    LText {
        width: line.keyWidth
        elide: Text.ElideRight
        text: G.plain(line.keys)
        color: line.dim ? Theme.lanSunk : line.lit ? Theme.lanPink : Theme.lanBright
    }
    LText {
        width: line.textWidth
        elide: Text.ElideRight
        text: G.plain(line.text)
        color: line.dim ? Theme.lanSunk : Theme.lanDim
    }
}
