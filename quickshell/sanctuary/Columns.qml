import QtQuick
import Quickshell
import "kit"

// The column strip: what Mod+1..9 points at on this workspace, left to right.
// niri scrolls sideways forever, so past three columns you lose track of which
// number is which window — this is the map. It is only ever on screen when
// asked for: Mod+Grave (the key left of 1, scripts/sanctuary/columns.sh) opens
// it with the keyboard, current column lit:
//
//   1-9  jump to that column     h l ← →  move     enter space  go
//   esc q `  close               click a cell = go
//
// It closes itself after 4s of no input.
//
// No automatic flash on column / workspace switches: tried on 2026-10-08 and
// dropped the same day, Harry found it distracting.
Popup {
    id: win

    name: "columns"
    open: Ui.columnsOpen
    onDismissed: Ui.columnsOpen = false
    cardWidth: strip.implicitWidth
    // Low on the screen, centred: the map sits over the windows it maps.
    centred: false
    cardX: Math.round((width - cardWidth) / 2)   // whole pixels, as a centre anchor would
    cardY: height - 56 - cardHeight
    onKeyPressed: event => key(event)

    readonly property var ws: Wm.focusedWorkspace
    readonly property var cols: ws ? Wm.columnsOf(ws.id) : []
    // niri's column number (1-based, what Mod+N takes) of the focused window.
    readonly property int focusedCol: {
        const f = Wm.focusedWindow;
        if (!f || !ws || f.workspace_id !== ws.id || !f.layout || !f.layout.pos_in_scrolling_layout)
            return -1;
        return f.layout.pos_in_scrolling_layout[0];
    }

    // A column of several windows (stacked or tabbed) is shown by the one you
    // were last in, or its top one.
    function face(c) {
        return c.windows.find(w => w.id === Wm.focusedId) || c.windows[0];
    }
    function entry(w) {
        return DesktopEntries.heuristicLookup(w.app_id || "");
    }
    function appName(w) {
        const e = entry(w);
        return e ? e.name : (w.app_id || "?");
    }
    function icon(w) {
        const e = entry(w);
        return Quickshell.iconPath(e ? e.icon : (w.app_id || ""), true)
            || Quickshell.iconPath("application-x-executable", true);
    }
    // Only 1-9 have a bind; a 10th column still shows, numberless.
    function num(c) {
        return c.index <= 9 ? String(c.index) : "·";
    }

    function go(c) {
        if (!c)
            return;
        Wm.focusColumn(c.index);
        Ui.columnsOpen = false;
    }

    onOpenChanged: {
        if (open) {
            const i = cols.findIndex(c => c.index === focusedCol);
            cursor = Math.max(0, i);
            idle.restart();
        }
    }

    Timer {
        id: idle
        interval: 4000
        onTriggered: Ui.columnsOpen = false
    }

    function key(event) {
        idle.restart();
        const k = event.key;
        const n = cols.length;
        if (k === Qt.Key_QuoteLeft)
            Ui.columnsOpen = false;
        else if (k >= Qt.Key_1 && k <= Qt.Key_9)
            go(cols.find(c => c.index === k - Qt.Key_0));
        else if (n === 0)
            return;
        else if (k === Qt.Key_H || k === Qt.Key_Left)
            cursor = (cursor + n - 1) % n;
        else if (k === Qt.Key_L || k === Qt.Key_Right)
            cursor = (cursor + 1) % n;
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            go(cols[cursor]);
        else
            return;
        event.accepted = true;
    }

    Fade {
        shown: win.visible

        Panel {
            id: strip
            width: implicitWidth
            fit: true
            vpad: 10
            inset: 12
            spacing: 6
            headerHeight: 12
            hintGap: 0
            hintCaps: true
            title: "COLUMNS"
            detail: "WS " + (win.ws ? win.ws.idx : "?") + " · " + win.cols.length + " COL"
            hint: win.cols.length ? "1-9 JUMP · H L MOVE · ENTER GO · ESC CLOSE" : "NO COLUMNS ON THIS WORKSPACE"

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: win.cols
                    delegate: Tile {
                        required property var modelData
                        required property int index
                        readonly property var w: win.face(modelData)
                        number: win.num(modelData)
                        count: modelData.windows.length
                        icon: win.icon(w)
                        name: win.appName(w)
                        title: w.title || ""
                        lit: modelData.index === win.focusedCol
                        selected: index === win.cursor
                        last: index === win.cols.length - 1
                        onHovered: { win.cursor = index; idle.restart(); }
                        onClicked: win.go(modelData)
                    }
                }
            }
        }
    }
}
