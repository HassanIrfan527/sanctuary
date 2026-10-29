import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · FilterText — what you've typed to narrow a panel, or the prompt to
// type. Lantern: the prompt dim; what you typed bright, with a block cursor.
LText {
    property string filter: ""
    property string prompt: "type to filter"

    text: G.plain(filter === "" ? prompt.toLowerCase() : filter + "▌")
    color: filter === "" ? Theme.lanDim : Theme.lanBright
}
