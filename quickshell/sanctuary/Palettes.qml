import QtQuick
import Quickshell
import "kit"

// The palette picker — Mod+Shift+C. Signal's colours only; shape, font and
// layout stay. Rows come from palettes/signal.json (Theme.palettes), so a new
// palette is a JSON entry + `palette.py build`, never an edit here.
//
// Moving the cursor previews the palette on the desk at once (Quickshell only);
// enter keeps it — scripts/sanctuary/palette.sh set then re-points kitty,
// starship and niri — and esc puts the old one back.
//
//   j k ↑ ↓  preview     1-9  pick directly     enter  keep     esc q  back
Popup {
    id: win

    name: "palettes"
    open: Ui.paletteOpen
    onDismissed: Ui.paletteOpen = false
    cardWidth: 420
    count: Theme.palettes.length
    onChosen: i => choose(i)

    property string was: "default"     // the palette when the picker opened
    property bool kept: false
    readonly property int current: Math.max(0, Theme.palettes.findIndex(p => p.word === was))

    onVisibleChanged: {
        if (visible) {
            was = Theme.paletteWord;
            kept = false;
            cursor = current;
        } else if (!kept) {
            Theme.paletteWord = was;
        }
    }
    onCursorChanged: if (visible && Theme.palettes[cursor])
        Theme.paletteWord = Theme.palettes[cursor].word

    function choose(i) {
        const p = Theme.palettes[i];
        kept = true;
        Ui.paletteOpen = false;
        if (!p || p.word === was)
            return;
        Theme.paletteWord = p.word;
        Quickshell.execDetached([Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary/palette.sh",
                                 "set", p.word]);
    }

    Panel {
        width: parent.width
        title: "PALETTE"
        hint: "j k preview · enter keep · esc back"

        Repeater {
            model: Theme.palettes
            delegate: MenuRow {
                required property var modelData
                required property int index
                number: index + 1
                name: modelData.name
                desc: modelData.desc
                selected: index === win.cursor
                current: index === win.current
                detail: current ? "● LIVE" : ""
                onHovered: win.cursor = index
                onClicked: win.choose(index)
            }
        }
    }
}
