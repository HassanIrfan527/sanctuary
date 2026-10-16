import QtQuick
import Quickshell
import Quickshell.Io
import "kit"

// The power menu — Mod+Shift+Escape (scripts/sanctuary/power.sh open). Drawn in
// the current style; when Quickshell is down the same key opens the fzf menu.
//
// Same rules as the fzf one: no confirmation, no countdown — picking a row IS
// the decision. The safety margin is the order: `lock` is the top row and the
// cursor always opens on it, so a stray Enter locks rather than powers off.
// The actions themselves run in power.sh (`do VERB`), which toasts a failure.
//
//   j k ↑ ↓  move     1-5  pick directly     enter  pick     esc q  close
//   click a row to pick it; click outside to close
Popup {
    id: win

    name: "power"
    open: Ui.powerOpen
    onDismissed: Ui.powerOpen = false
    cardWidth: 400
    count: rows.length
    tabMoves: true
    onChosen: i => choose(i)

    // `verb` is what `power.sh do` takes. `danger` = ends the session: drawn
    // in the alarm colour when the cursor is on it, so the last look before
    // Enter says so.
    readonly property var rows: [
        { verb: "lock",     name: "Lock",      desc: "back in with your password",       danger: false },
        { verb: "suspend",  name: "Suspend",   desc: "sleep, resume where you left off", danger: false },
        { verb: "logout",   name: "Log out",   desc: "quit niri",                        danger: true },
        { verb: "reboot",   name: "Reboot",    desc: "restart now",                      danger: true },
        { verb: "poweroff", name: "Shut down", desc: "power off now",                    danger: true }
    ]
    property string uptime: ""

    onVisibleChanged: {
        if (visible) {
            cursor = 0;
            uptimeFile.reload();
        }
    }

    // The header readout. /proc/uptime: "seconds idle-seconds".
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: {
            const s = Math.floor(parseFloat(uptimeFile.text()));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            win.uptime = (d > 0 ? d + "D " : "") + h + "H " + Theme.pad(m, 2, "0") + "M";
        }
    }

    function choose(i) {
        Ui.powerOpen = false;
        Quickshell.execDetached([Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary/power.sh",
                                 "do", rows[i].verb]);
    }

    //   ┌ POWER ─────────────────────── UP 3H 12M ┐
    //   │▌1  LOCK       back in with your password │
    //   │ 2  SUSPEND    sleep, resume where you…   │
    //   └ j k move · enter act · esc close ────────┘
    Panel {
        width: parent.width
        title: "POWER"
        detail: win.uptime ? "UP " + win.uptime : ""
        hint: "j k move · enter act · esc close"

        Repeater {
            model: win.rows
            delegate: MenuRow {
                required property var modelData
                required property int index
                number: index + 1
                name: modelData.name.toUpperCase()
                desc: modelData.desc
                nameWidth: 90
                danger: modelData.danger
                selected: index === win.cursor
                litWhenSelected: true
                onHovered: win.cursor = index
                onClicked: win.choose(index)
            }
        }
    }
}
