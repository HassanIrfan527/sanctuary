import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The wallpaper picker — Mod+Shift+W (scripts/sanctuary/wallpaper.sh open).
// Drawn in the current style; when Quickshell is down the same key opens yazi.
//
// Two shelves: STILL (~/Pictures/Wallpapers, applied by awww) and LIVE
// (~/Videos/Wallpapers, played by mpvpaper through livewall.sh). Setting a still
// stops a live one — it is a layer above awww and would hide the change.
//
// wallpaper.sh does the file work: `list` names every file and its thumbnail,
// `thumbs` makes the missing ones (480x270, cached in ~/.cache/sanctuary). A
// file with no thumbnail yet shows its name on a blank tile rather than
// decoding a 4K original on the spot — the first open after adding a folder of
// wallpapers fills in as they are made.
//
//   type  filter by name     ← → ↑ ↓ · ctrl-h j k l  move     tab  still / live
//   enter  set + close       shift-enter  set, stay open (try a few)     esc  close
//   click a tile to set it; click outside to close
PanelWindow {
    id: win

    visible: Ui.wallOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property string scripts: Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary/"

    property var all: []              // { kind, path, thumb, name }
    property string currentKind: "still"
    property string currentPath: ""
    property string kind: "still"     // the shelf on show
    property string query: ""
    property int cursor: 0
    property int thumbRev: 0          // bumped when new thumbnails land → tiles retry

    readonly property int cols: 4
    readonly property int shown: 3    // rows visible before scrolling
    readonly property int stillCount: all.filter(w => w.kind === "still").length
    readonly property int liveCount: all.filter(w => w.kind === "live").length
    readonly property var results: {
        const words = query.trim().toLowerCase().split(/\s+/).filter(w => w);
        return all.filter(w => w.kind === kind && words.every(q => w.name.toLowerCase().indexOf(q) >= 0));
    }
    readonly property var picked: results[cursor] || null

    onVisibleChanged: {
        if (visible) {
            sigInput.text = "";
            inkInput.text = "";
            lister.running = true;
            Qt.callLater(() => (Theme.signal ? sigInput : inkInput).forceActiveFocus());
        }
    }
    onQueryChanged: cursor = 0
    onKindChanged: cursor = Math.max(0, kind === currentKind ? results.findIndex(w => w.path === currentPath) : 0)
    onCursorChanged: (Theme.signal ? sigGrid : inkGrid).positionViewAtIndex(cursor, GridView.Contain)

    // ── data ──────────────────────────────────────────────────────────
    Process {
        id: lister
        command: [win.scripts + "wallpaper.sh", "list"]
        stdout: StdioCollector {
            id: listOut
            onStreamFinished: win.parse(listOut.text)
        }
    }
    Process {
        id: thumber
        command: [win.scripts + "wallpaper.sh", "thumbs"]
        stdout: StdioCollector {
            id: thumbOut
            onStreamFinished: {
                if (parseInt(thumbOut.text) > 0)
                    win.thumbRev++;
            }
        }
    }

    function parse(text) {
        const out = [];
        for (const l of text.split("\n")) {
            const f = l.split("\t");
            if (f[0] === "current") {
                currentKind = f[1];
                currentPath = f[2] || "";
            } else if (f.length === 3) {
                const base = f[1].substring(f[1].lastIndexOf("/") + 1);
                out.push({ kind: f[0], path: f[1], thumb: f[2], name: base.replace(/\.[^.]+$/, "") });
            }
        }
        all = out;
        // Open on the wallpaper you have now, on its shelf.
        kind = currentKind;
        cursor = Math.max(0, results.findIndex(w => w.path === currentPath));
        (Theme.signal ? sigGrid : inkGrid).positionViewAtIndex(cursor, GridView.Center);
        if (!thumber.running)
            thumber.running = true;
    }

    function apply(i, stay) {
        const w = results[i];
        if (!w)
            return;
        if (w.kind === "live")
            Quickshell.execDetached([scripts + "livewall.sh", "start", w.path]);
        else
            Quickshell.execDetached([scripts + "wallpaper.sh", "set", w.path]);
        currentKind = w.kind;
        currentPath = w.path;
        if (!stay)
            Ui.wallOpen = false;
    }

    function key(event) {
        const k = event.key, ctrl = event.modifiers & Qt.ControlModifier;
        const n = results.length;
        const move = d => { if (n > 0) cursor = Math.max(0, Math.min(n - 1, cursor + d)); };
        if (k === Qt.Key_Escape)
            Ui.wallOpen = false;
        else if (k === Qt.Key_Return || k === Qt.Key_Enter)
            apply(cursor, event.modifiers & Qt.ShiftModifier);
        else if (k === Qt.Key_Tab || k === Qt.Key_Backtab)
            kind = kind === "still" ? "live" : "still";
        else if (k === Qt.Key_Right || (ctrl && k === Qt.Key_L))
            move(1);
        else if (k === Qt.Key_Left || (ctrl && k === Qt.Key_H))
            move(-1);
        else if (k === Qt.Key_Down || (ctrl && k === Qt.Key_J))
            move(cols);
        else if (k === Qt.Key_Up || (ctrl && k === Qt.Key_K))
            move(-cols);
        else if (k === Qt.Key_PageDown)
            move(cols * shown);
        else if (k === Qt.Key_PageUp)
            move(-cols * shown);
        else
            return;
        event.accepted = true;
    }

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.wallOpen = false
    }

    // ══ Signal: a contact sheet on the instrument ════════════════════
    //
    //   ┌ WALLPAPER   STILL 402 · LIVE 23 ─────────────── 007/402 ┐
    //   │ ▸ anime▌                                                 │
    //   ├──────────────────────────────────────────────────────────┤
    //   │ ┏━━━━━━━┓ ┌───────┐ ┌───────┐ ┌───────┐                  │
    //   │ ┃ ● NOW ┃ │       │ │       │ │       │                  │
    //   │ ┗━━━━━━━┛ └───────┘ └───────┘ └───────┘                  │
    //   │ aesthetic_deer                                           │
    //   └ enter set · shift-enter try · tab still/live · esc ──────┘
    Rectangle {
        id: sig
        visible: Theme.signal
        anchors.centerIn: parent
        width: 1000
        height: sigCol.implicitHeight
        color: Theme.sigFill
        border.width: 1
        border.color: Theme.sigRule

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // swallow

        SignalTicks {
            anchors.fill: parent
            anchors.margins: -3
        }

        Column {
            id: sigCol
            width: parent.width

            // header: title, shelves, position
            Item {
                width: parent.width
                height: 30
                Row {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18
                    Text {
                        text: "WALLPAPER"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigHot
                    }
                    Repeater {
                        model: [{ k: "still", n: win.stillCount }, { k: "live", n: win.liveCount }]
                        delegate: Text {
                            required property var modelData
                            text: modelData.k.toUpperCase() + " " + modelData.n
                            font.family: Theme.mono
                            font.pixelSize: 9
                            font.weight: win.kind === modelData.k ? Font.Bold : Font.Normal
                            font.letterSpacing: 1.4
                            color: win.kind === modelData.k ? Theme.sigValue : Theme.sigLabel
                            font.underline: win.kind === modelData.k
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.kind = parent.modelData.k
                            }
                        }
                    }
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.pad(win.results.length ? win.cursor + 1 : 0, 3, "0") + "/"
                          + Theme.pad(win.results.length, 3, "0")
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1.4
                    color: Theme.sigLabel
                }
            }

            // filter prompt
            Item {
                width: parent.width
                height: 34
                Text {
                    id: chev
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▸"
                    font.family: Theme.mono
                    font.pixelSize: 13
                    color: Theme.sigHot
                }
                TextInput {
                    id: sigInput
                    anchors.left: chev.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    onTextChanged: win.query = text
                    font.family: Theme.mono
                    font.pixelSize: 13
                    color: Theme.sigValue
                    selectionColor: Theme.surface1
                    cursorDelegate: Rectangle { width: 7; color: Theme.sigHot; opacity: 0.8 }
                    Keys.onPressed: event => win.key(event)
                }
                Text {
                    anchors.left: chev.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: win.query === ""
                    text: "filter by name"
                    font.family: Theme.mono
                    font.pixelSize: 13
                    color: Theme.surface2
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.sigRule }
            Item { width: 1; height: 6 }

            GridView {
                id: sigGrid
                x: 10
                width: parent.width - 20
                // Exactly `shown` rows, snapping row by row: no sliver of a
                // fourth row peeking in at the bottom.
                height: cellHeight * win.shown
                clip: true
                snapMode: GridView.SnapToRow
                cellWidth: Math.floor(width / win.cols)
                cellHeight: Math.round(cellWidth * 9 / 16)
                model: Theme.signal ? win.results : []
                currentIndex: win.cursor
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: cellHeight * 2

                delegate: Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === win.cursor
                    readonly property bool now: modelData.path === win.currentPath
                    width: sigGrid.cellWidth
                    height: sigGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        color: Theme.sigCell
                        border.width: tile.sel ? 2 : 1
                        border.color: tile.sel ? Theme.sigHot : Theme.sigRule

                        Thumb {
                            anchors.fill: parent
                            anchors.margins: tile.sel ? 2 : 1
                            entry: tile.modelData
                            rev: win.thumbRev
                            fallbackFont: Theme.mono
                            fallbackColor: Theme.sigLabel
                            dim: !tile.sel
                        }

                        Rectangle {   // status tags, top-left
                            visible: tile.now || tile.modelData.kind === "live"
                            x: 6
                            y: 6
                            width: tagText.implicitWidth + 10
                            height: 15
                            color: Theme.sigFill
                            Text {
                                id: tagText
                                anchors.centerIn: parent
                                text: tile.now ? "● NOW" : "▶ LIVE"
                                font.family: Theme.mono
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                font.letterSpacing: 1.2
                                color: tile.now ? Theme.sigHot : Theme.sigLabel
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.cursor = tile.index
                        onClicked: win.apply(tile.index, false)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: win.results.length === 0
                    text: lister.running ? "READING…" : "NO MATCH"
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.6
                    color: Theme.surface2
                }
            }

            Item { width: 1; height: 6 }
            Rectangle { width: parent.width; height: 1; color: Theme.sigRule }

            // footer: the name under the cursor, the keys
            Item {
                width: parent.width
                height: 28
                Text {
                    x: 14
                    width: parent.width * 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideMiddle
                    text: win.picked ? win.picked.name : ""
                    font.family: Theme.mono
                    font.pixelSize: 10
                    color: Theme.sigValue
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "enter set · shift-enter try · tab still/live · esc close"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
            }
        }
    }

    // ══ Ink / Paper: a page of panels ════════════════════════════════
    //
    //   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    //   ┃ WALLPAPER  [STILL] [LIVE]      ┌ filter ───────┐ ┃
    //   ┃ ┏━━━━━┓▉ ┌─────┐ ┌─────┐ ┌─────┐               ┃  ← selected: thick
    //   ┃ ┗━━━━━┛▉ └─────┘ └─────┘ └─────┘               ┃    ink + peach shadow
    //   ┃ AESTHETIC_DEER                        7 / 402  ┃
    //   ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
    Item {
        id: ink
        visible: Theme.ink
        anchors.centerIn: parent
        width: 1000
        height: inkCol.implicitHeight + 36

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // swallow

        Rectangle {   // hard shadow
            x: 7
            y: 7
            width: parent.width
            height: parent.height
            color: Theme.mauve
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.paper
            border.width: Theme.inkStroke
            border.color: Theme.inkLine
        }

        Column {
            id: inkCol
            x: 20
            y: 16
            width: parent.width - 40
            spacing: 12

            // masthead: title, shelves, filter
            Item {
                width: parent.width
                height: 40
                InkHalftone {
                    anchors.fill: parent
                    from: 0.35
                    strength: 0.22
                    step: 6
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "WALLPAPER"
                        font.family: Theme.display
                        font.weight: Theme.displayWeight
                        font.pixelSize: Theme.hasBangers ? 34 : 26
                        color: Theme.inkLine
                    }
                    Repeater {
                        model: [{ k: "still", n: win.stillCount }, { k: "live", n: win.liveCount }]
                        delegate: Item {
                            id: shelf
                            required property var modelData
                            readonly property bool on: win.kind === modelData.k
                            anchors.verticalCenter: parent.verticalCenter
                            width: shelfText.implicitWidth + 20
                            height: 26
                            Rectangle {
                                x: 3
                                y: 3
                                width: parent.width
                                height: parent.height
                                color: shelf.on ? Theme.peach : Theme.paperShade
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: shelf.on ? Theme.inkLine : Theme.paper
                                border.width: 2
                                border.color: Theme.inkLine
                                Text {
                                    id: shelfText
                                    anchors.centerIn: parent
                                    text: shelf.modelData.k.toUpperCase() + " " + shelf.modelData.n
                                    font.family: Theme.sans
                                    font.weight: Font.Black
                                    font.pixelSize: 11
                                    color: shelf.on ? Theme.paper : Theme.inkLine
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.kind = shelf.modelData.k
                            }
                        }
                    }
                }
                // the filter, in a small inked box on the right
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 280
                    height: 32
                    color: Theme.paper
                    border.width: 2
                    border.color: Theme.inkLine
                    TextInput {
                        id: inkInput
                        x: 12
                        width: parent.width - 24
                        anchors.verticalCenter: parent.verticalCenter
                        onTextChanged: win.query = text
                        font.family: Theme.sans
                        font.weight: Font.Black
                        font.pixelSize: 14
                        color: Theme.inkLine
                        selectionColor: Theme.paperShade
                        cursorDelegate: Rectangle { width: 3; color: Theme.inkLine }
                        Keys.onPressed: event => win.key(event)
                        clip: true
                    }
                    Text {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: win.query === ""
                        text: "find one…"
                        font.family: Theme.sans
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        color: Theme.inkMuted
                    }
                }
            }

            GridView {
                id: inkGrid
                width: parent.width
                height: cellHeight * win.shown
                clip: true
                snapMode: GridView.SnapToRow
                cellWidth: Math.floor(width / win.cols)
                cellHeight: Math.round((cellWidth - 14) * 9 / 16) + 14
                model: Theme.ink ? win.results : []
                currentIndex: win.cursor
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: cellHeight * 2

                delegate: Item {
                    id: itile
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === win.cursor
                    readonly property bool now: modelData.path === win.currentPath
                    width: inkGrid.cellWidth
                    height: inkGrid.cellHeight

                    Item {
                        x: 3
                        y: 3
                        width: parent.width - 14
                        height: parent.height - 14

                        Rectangle {   // hard shadow
                            x: itile.sel ? 6 : 3
                            y: itile.sel ? 6 : 3
                            width: parent.width
                            height: parent.height
                            color: itile.sel ? Theme.peach : Theme.paperShade
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.paperDim
                            border.width: itile.sel ? Theme.inkStroke + 1 : 2
                            border.color: Theme.inkLine

                            Thumb {
                                anchors.fill: parent
                                anchors.margins: parent.border.width
                                entry: itile.modelData
                                rev: win.thumbRev
                                fallbackFont: Theme.sans
                                fallbackColor: Theme.inkMuted
                            }
                        }
                        Rectangle {   // NOW / LIVE: a lettered tag stuck on the panel
                            visible: itile.now || itile.modelData.kind === "live"
                            x: -2
                            y: -2
                            width: itag.implicitWidth + 12
                            height: 18
                            color: itile.now ? Theme.inkLine : Theme.paper
                            border.width: 2
                            border.color: Theme.inkLine
                            Text {
                                id: itag
                                anchors.centerIn: parent
                                text: itile.now ? "NOW" : "LIVE"
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 9
                                font.letterSpacing: 0.8
                                color: itile.now ? Theme.paper : Theme.inkLine
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.cursor = itile.index
                        onClicked: win.apply(itile.index, false)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: win.results.length === 0
                    text: lister.running ? "HOLD ON…" : "NOTHING BY THAT NAME."
                    font.family: Theme.display
                    font.weight: Theme.displayWeight
                    font.pixelSize: Theme.hasBangers ? 22 : 17
                    color: Theme.inkMuted
                }
            }

            // caption: the name under the cursor, and where you are
            Item {
                width: parent.width
                height: 18
                Text {
                    width: parent.width * 0.6
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideMiddle
                    text: win.picked ? win.picked.name.toUpperCase() : ""
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 12
                    color: Theme.inkLine
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (win.results.length ? win.cursor + 1 : 0) + " / " + win.results.length
                          + "   ·   enter set · shift-enter try · tab still/live"
                    font.family: Theme.sans
                    font.weight: Font.Bold
                    font.pixelSize: 10
                    color: Theme.inkSoft
                }
            }
        }
    }
}
