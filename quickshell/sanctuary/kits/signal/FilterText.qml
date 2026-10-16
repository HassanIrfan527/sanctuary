import QtQuick
import ".."

// KIT · FilterText — what you've typed to narrow a panel, or the prompt to
// type. Signal: "TYPE TO FILTER" dim, then "> REC_" bold in the hot colour.
Text {
    property string filter: ""
    property string prompt: "TYPE TO FILTER"

    text: filter === "" ? prompt : "> " + filter.toUpperCase() + "_"
    font.family: Theme.mono
    font.pixelSize: filter === "" ? 9 : 10
    font.weight: filter === "" ? Font.Normal : Font.Bold
    font.letterSpacing: 1.4
    color: filter === "" ? Theme.sigLabel : Theme.sigHot
}
