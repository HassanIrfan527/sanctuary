import QtQuick
import "kit"

// The layout picker — Mod+Ctrl+Space, Mango only. Sets the layout of the tag
// you are looking at (Mango keeps one per tag; the others stay as they are).
// Mod+Alt+Space still cycles scroller → tile → grid → monocle → deck blind.
//
// Nine rows, one per layout family. Five have a vertical twin (the same idea
// turned 90°): V flips the card between the two, so every one of Mango's 14
// layouts is a number key away. Names match the word in the bar's WS cell.
//
//   j k ↑ ↓  move     1-9  pick directly     v  horizontal / vertical
//   enter l  pick     esc q  close           click a row to pick it
Popup {
    id: win

    name: "layouts"
    open: Ui.layoutOpen
    onDismissed: Ui.layoutOpen = false
    cardWidth: 460
    count: rows.length
    onChosen: i => choose(i)
    onKeyPressed: event => {
        if (event.key === Qt.Key_V) {
            vert = !vert;
            event.accepted = true;
        }
    }

    // h / v: Mango's layout names (setlayout takes these). hs / vs: the
    // symbols mmsg reports per tag, to light the live one. word: the bar's
    // word (Mango.qml). g: the glyph — boxes in a 1×1 frame, x y w h; the
    // vertical twin draws the same boxes transposed.
    readonly property var rows: [
        { h: "scroller",    hs: "S",  v: "vertical_scroller", vs: "VS", word: "SCROLL",  desc: "a strip of columns · niri",
          g: [[0, 0, .42, 1], [.46, 0, .42, 1], [.92, 0, .42, 1]] },
        { h: "tile",        hs: "T",  v: "vertical_tile",     vs: "VT", word: "TILE",    desc: "master left · stack right",
          g: [[0, 0, .56, 1], [.6, 0, .4, .47], [.6, .53, .4, .47]] },
        { h: "right_tile",  hs: "RT", v: "",                  vs: "",   word: "R-TILE",  desc: "master right · stack left",
          g: [[.44, 0, .56, 1], [0, 0, .4, .47], [0, .53, .4, .47]] },
        { h: "center_tile", hs: "CT", v: "",                  vs: "",   word: "CENTRE",  desc: "master centre · stacks either side",
          g: [[.26, 0, .48, 1], [0, 0, .22, 1], [.78, 0, .22, .47], [.78, .53, .22, .47]] },
        { h: "grid",        hs: "G",  v: "vertical_grid",     vs: "VG", word: "GRID",    desc: "everything at once, evenly",
          g: [[0, 0, .48, .46], [.52, 0, .48, .46], [0, .54, .48, .46], [.52, .54, .48, .46]] },
        { h: "monocle",     hs: "M",  v: "",                  vs: "",   word: "MONO",    desc: "one window, full tag · tabs on top",
          g: [[0, 0, .31, .18], [.345, 0, .31, .18], [.69, 0, .31, .18], [0, .26, 1, .74]] },
        { h: "deck",        hs: "K",  v: "vertical_deck",     vs: "VK", word: "DECK",    desc: "master + the stack as one card",
          g: [[0, 0, .56, 1], [.66, .14, .34, .86], [.6, 0, .34, .86]] },
        { h: "dwindle",     hs: "DW", v: "",                  vs: "",   word: "DWINDLE", desc: "each window halves the last",
          g: [[0, 0, .48, 1], [.52, 0, .48, .47], [.52, .53, .22, .47], [.78, .53, .22, .47]] },
        { h: "fair",        hs: "F",  v: "vertical_fair",     vs: "VF", word: "FAIR",    desc: "equal shares, no master",
          g: [[0, 0, .31, 1], [.345, 0, .31, 1], [.69, 0, .31, 1]] }
    ]

    readonly property var tag: Wm.focusedWorkspace
    readonly property string sym: tag && tag.layout ? tag.layout : ""
    readonly property int current: rows.findIndex(r => r.hs === sym || r.vs === sym)
    property bool vert: false

    onVisibleChanged: if (visible) {
        cursor = Math.max(0, current);
        vert = sym.startsWith("V");
    }

    function nameOf(r) { return vert && r.v ? r.v : r.h; }
    function wordOf(r) { return vert && r.v ? "V-" + r.word : r.word; }

    function choose(i) {
        Ui.layoutOpen = false;
        const r = rows[i];
        if ((vert && r.v ? r.vs : r.hs) !== sym)
            Wm.setLayout(nameOf(r));
    }

    // LAYOUT · TAG 3                         HORIZ │ VERT
    Panel {
        width: parent.width
        title: "LAYOUT" + (win.tag ? "  ·  TAG " + win.tag.idx : "")
        headerHeight: 22
        hint: "j k move · 1-9 pick · v vertical · enter pick · esc close"
        headerItems: Repeater {
            model: [{ label: "HORIZ", v: false }, { label: "VERT", v: true }]
            delegate: Tab {
                required property var modelData
                text: modelData.label
                on: win.vert === modelData.v
                onClicked: win.vert = modelData.v
            }
        }

        Repeater {
            model: win.rows
            delegate: MenuRow {
                id: row
                required property var modelData
                required property int index
                // in VERT, rows with no vertical twin stay pickable (they
                // pick their one version) but step back
                readonly property bool flat: win.vert && !modelData.v
                height: 34
                centred: true
                opacity: flat && !selected ? 0.45 : 1
                number: index + 1
                name: win.wordOf(modelData)
                desc: flat ? "no vertical · picks as is" : modelData.desc
                nameWidth: 76
                selected: index === win.cursor
                current: (win.vert && modelData.v ? modelData.vs : modelData.hs) === win.sym
                detail: current ? "● LIVE" : ""
                // the glyph: what the tag will look like
                lead: Boxes {
                    boxes: row.modelData.g
                    turn: win.vert && !!row.modelData.v
                    lit: row.current || row.selected
                }
                onHovered: win.cursor = index
                onClicked: win.choose(index)
            }
        }
    }
}
