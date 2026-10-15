import QtQuick
import Quickshell
import Quickshell.Wayland

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
//
// Signal only, like Mango's look (look-signal.conf); other styles come later.
PanelWindow {
    id: win

    visible: Ui.layoutOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-layouts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
    property int cursor: 0
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

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.layoutOpen = false
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: 460
        height: sig.height
        focus: true

        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape || k === Qt.Key_Q)
                Ui.layoutOpen = false;
            else if (k === Qt.Key_J || k === Qt.Key_Down)
                win.cursor = (win.cursor + 1) % win.rows.length;
            else if (k === Qt.Key_K || k === Qt.Key_Up)
                win.cursor = (win.cursor + win.rows.length - 1) % win.rows.length;
            else if (k === Qt.Key_V)
                win.vert = !win.vert;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_L)
                win.choose(win.cursor);
            else if (k >= Qt.Key_1 && k <= Qt.Key_9)
                win.choose(k - Qt.Key_1);
            else
                return;
            event.accepted = true;
        }

        MouseArea {   // swallow clicks on the card
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Rectangle {
            id: sig
            width: parent.width
            height: sigCol.implicitHeight + 24
            color: Theme.sigFill
            border.width: 1
            border.color: Theme.sigRule

            SignalTicks {
                anchors.fill: parent
                anchors.margins: -3
            }

            Column {
                id: sigCol
                x: 1
                y: 12
                width: parent.width - 2
                spacing: 2

                // LAYOUT · TAG 3                         HORIZ │ VERT
                Item {
                    width: parent.width
                    height: 22

                    Text {
                        x: 14
                        anchors.top: parent.top
                        text: "LAYOUT" + (win.tag ? "  ·  TAG " + win.tag.idx : "")
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigHot
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.top: parent.top
                        spacing: 8
                        Repeater {
                            model: [{ label: "HORIZ", v: false }, { label: "VERT", v: true }]
                            delegate: Text {
                                required property var modelData
                                text: modelData.label
                                font.family: Theme.mono
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1.4
                                color: win.vert === modelData.v ? Theme.sigHot : Theme.surface2
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.vert = parent.modelData.v
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: win.rows
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        // in VERT, rows with no vertical twin stay pickable
                        // (they pick their one version) but step back
                        readonly property bool flat: win.vert && !modelData.v
                        readonly property bool here: (win.vert && modelData.v ? modelData.vs : modelData.hs) === win.sym
                        readonly property bool sel: index === win.cursor
                        width: sigCol.width
                        height: 34
                        color: sel ? Theme.sigCell : "transparent"
                        opacity: flat && !sel ? 0.45 : 1

                        Rectangle {
                            width: 2
                            height: parent.height
                            color: Theme.sigHot
                            visible: row.sel
                        }
                        Row {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(row.index + 1)
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: Theme.surface2
                            }
                            // the glyph: what the tag will look like
                            Item {
                                id: glyph
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                height: 20
                                clip: true
                                readonly property bool turn: win.vert && !!row.modelData.v
                                readonly property color ink: row.here || row.sel ? Theme.sigHot : Theme.sigLabel
                                Repeater {
                                    model: row.modelData.g
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        readonly property var b: glyph.turn
                                            ? [modelData[1], modelData[0], modelData[3], modelData[2]]
                                            : modelData
                                        x: Math.round(b[0] * glyph.width)
                                        y: Math.round(b[1] * glyph.height)
                                        width: Math.max(2, Math.round(b[2] * glyph.width))
                                        height: Math.max(2, Math.round(b[3] * glyph.height))
                                        color: index === 0 ? Qt.rgba(glyph.ink.r, glyph.ink.g, glyph.ink.b, 0.25) : Theme.sigFill
                                        border.width: 1
                                        border.color: glyph.ink
                                    }
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 76
                                text: win.wordOf(row.modelData)
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: row.here ? Theme.sigHot : Theme.sigValue
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.flat ? "no vertical · picks as is" : row.modelData.desc
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: Theme.sigLabel
                            }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.here ? "● LIVE" : ""
                            font.family: Theme.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                            color: Theme.sigHot
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.cursor = row.index
                            onClicked: win.choose(row.index)
                        }
                    }
                }

                Text {
                    x: 14
                    topPadding: 8
                    text: "j k move · 1-9 pick · v vertical · enter pick · esc close"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
            }
        }
    }
}
