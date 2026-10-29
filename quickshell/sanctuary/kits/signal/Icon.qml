import QtQuick
import ".."

// KIT · Icon — a thing, by name (DESIGN-SYSTEM §3 rule 5). Signal draws
// glyph text, the way its parts always have: `name` is printed as given
// (a glyph like "◉"), in mono at `size`. Lantern maps the same names to
// Pixelarticons (kits/lantern/Icon.qml). A multi-letter name that isn't a
// glyph draws nothing (`known` is false), so icon names never print as words.
Text {
    property string name: ""
    property int size: 12
    readonly property bool known: name !== "" && name.length <= 2

    visible: known
    width: known ? implicitWidth : 0
    text: known ? name : ""
    font.family: Theme.mono
    font.pixelSize: size
    color: Theme.sigLabel
}
