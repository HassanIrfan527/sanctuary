import QtQuick
import Quickshell
import "kit"

// The style picker — Mod+Shift+T. Drawn by Quickshell itself, in the style it
// is currently wearing. Picking restarts Quickshell in the new style (via
// scripts/sanctuary/shell.sh set), which also remembers it across reboots.
//
// It changes the bar, toasts and centre only. niri's layout is fixed
// (niri/layout.kdl) — nothing rewrites niri config.
//
//   j k ↑ ↓  move     1 2 3  pick directly     enter  pick     esc q  close
//   click a row to pick it; click outside to close
Popup {
    id: win

    name: "picker"
    open: Ui.pickerOpen
    onDismissed: Ui.pickerOpen = false
    cardWidth: 420
    count: styles.length
    onChosen: i => choose(i)

    // Order = the picker's rows. `word` is what shell.sh set takes.
    readonly property var styles: [
        { word: "signal", name: "Signal", desc: "instrument strip · live traces" },
        { word: "flare",  name: "Flare",  desc: "signal in daylight · parchment + ember" }
    ]
    readonly property int current: Math.max(0, styles.findIndex(s => s.word === Theme.word))

    onVisibleChanged: if (visible) cursor = current

    function choose(i) {
        Ui.pickerOpen = false;
        if (i === current)
            return;
        Quickshell.execDetached([Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary/shell.sh",
                                 "set", styles[i].word]);
    }

    Panel {
        width: parent.width
        title: "STYLE"
        hint: "j k move · enter pick · esc close"

        Repeater {
            model: win.styles
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
