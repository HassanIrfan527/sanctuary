import QtQuick
import ".."

// KIT (Lantern only) · LText — every word Lantern prints: Jersey 15 at 20px,
// or Jersey 10 at 32px when `big` (the clock, titles). Drawn as hard pixels:
// native rendering with antialiasing off, the only way Qt keeps a pixel font
// from blurring (2026-10-16 test: 0 grey pixels this way, ~50% otherwise).
Text {
    property bool big: false

    font.family: big ? Theme.lanDisplay : Theme.lanFont
    font.pixelSize: big ? Theme.lanBig : Theme.lanSize
    font.hintingPreference: Font.PreferNoHinting
    renderType: Text.NativeRendering
    antialiasing: false
    color: Theme.lanText
}
