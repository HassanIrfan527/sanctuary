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
// Each shelf is a folder tree. Off search you see one folder at a time: its
// subfolders first (drawn folder tiles, FolderGlyph.qml), then the pictures
// directly in it, with a ".." tile at the head once you are inside. Typing
// searches every picture in every folder at once, folders matched by path too
// ("jjk" finds all of jjk/). The tree is built here from the file paths, so a
// folder with no pictures anywhere below it simply never appears.
//
// wallpaper.sh does the file work: `list` names every file and its thumbnail,
// `thumbs` makes the missing ones (480x270, cached in ~/.cache/sanctuary). A
// file with no thumbnail yet shows its name on a blank tile rather than
// decoding a 4K original on the spot — the first open after adding a folder of
// wallpapers fills in as they are made.
//
//   type  search all folders     ← → ↑ ↓ · ctrl-h j k l  move     tab  still / live
//   enter  open folder / set + close     shift-enter  set, stay open (try a few)
//   backspace  up a folder — only on an empty search box, and never on key
//              repeat: holding it to clear a word stops at the empty box
//   esc  close     click a tile to open / set it; click outside to close
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

    property var all: []              // { type: "file", kind, path, thumb, name, dir }
    property var roots: ({ still: "", live: "" })
    property string currentKind: "still"
    property string currentPath: ""
    property string kind: "still"     // the shelf on show
    property string folder: ""        // where you are on it, relative to its root; "" = top
    property string query: ""
    property int cursor: 0
    property int thumbRev: 0          // bumped when new thumbnails land → tiles retry

    readonly property int cols: 4
    readonly property int shown: 3    // rows visible before scrolling
    readonly property int stillCount: all.filter(w => w.kind === "still").length
    readonly property int liveCount: all.filter(w => w.kind === "live").length
    readonly property bool searching: query.trim() !== ""
    // What the grid shows: search hits, or the folder's ".." / subfolders / files.
    readonly property var results: {
        const shelf = all.filter(w => w.kind === kind);
        if (searching) {
            const words = query.trim().toLowerCase().split(/\s+/);
            return shelf.filter(w => {
                const hay = (w.dir + "/" + w.name).toLowerCase();
                return words.every(q => hay.indexOf(q) >= 0);
            });
        }
        const prefix = folder === "" ? "" : folder + "/";
        const nowDir = kind === currentKind ? dirOf(kind, currentPath) : null;
        const subs = {}, files = [];
        for (const w of shelf) {
            if (w.dir === folder) {
                files.push(w);
            } else if (w.dir.startsWith(prefix)) {
                const name = w.dir.substring(prefix.length).split("/")[0];
                const dir = prefix + name;
                if (!subs[dir])
                    subs[dir] = { type: "folder", kind: kind, dir: dir, name: name, thumb: w.thumb, path: "", count: 0,
                                  now: nowDir !== null && (nowDir === dir || nowDir.startsWith(dir + "/")) };
                subs[dir].count++;
            }
        }
        const folders = Object.values(subs).sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
        const up = folder === "" ? [] : [{ type: "up", kind: kind, dir: parentOf(folder), name: "..", thumb: "", path: "" }];
        return up.concat(folders, files);
    }
    readonly property var picked: results[cursor] || null
    readonly property string hints: (picked && picked.type !== "file" ? "enter open" : "enter set · shift-enter try")
                                    + (!searching && folder !== "" ? " · ⌫ up" : "") + " · tab still/live · esc close"
    // "/ dynamic-wallpapers / dark" — where you are, for the header
    readonly property string crumb: searching ? "all folders" : "/" + (folder === "" ? "" : " " + folder.split("/").join(" / "))

    onVisibleChanged: {
        if (visible) {
            sigInput.text = "";
            lister.running = true;
            Qt.callLater(() => sigInput.forceActiveFocus());
        }
    }
    onQueryChanged: cursor = 0
    onKindChanged: land()
    onCursorChanged: sigGrid.positionViewAtIndex(cursor, GridView.Contain)

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
        const out = [], r = {};
        for (const l of text.split("\n")) {
            const f = l.split("\t");
            if (f[0] === "current") {
                currentKind = f[1];
                currentPath = f[2] || "";
            } else if (f[0] === "root") {
                r[f[1]] = f[2] || "";
                roots = r;   // before the files below: dirOf reads it
            } else if (f.length === 3) {
                const base = f[1].substring(f[1].lastIndexOf("/") + 1);
                out.push({ type: "file", kind: f[0], path: f[1], thumb: f[2], name: base.replace(/\.[^.]+$/, ""),
                           dir: dirOf(f[0], f[1]) });
            }
        }
        all = out;
        // Open on the wallpaper you have now: its shelf, its folder.
        if (kind === currentKind)
            land();
        else
            kind = currentKind;   // → onKindChanged → land()
        sigGrid.positionViewAtIndex(cursor, GridView.Center);
        if (!thumber.running)
            thumber.running = true;
    }

    // The footer line for the tile under the cursor. Search hits say which
    // folder they came from, since they are mixed together.
    function caption(w) {
        if (!w)
            return "";
        if (w.type === "up")
            return ".. back to " + (w.dir === "" ? "the top" : w.dir);
        if (w.type === "folder")
            return w.name + "/  · " + w.count;
        return searching && w.dir !== "" ? w.dir + "/" + w.name : w.name;
    }

    // A file's folder relative to its shelf's root: "" at the top, "a/b" deeper.
    function dirOf(k, path) {
        const root = roots[k] || "";
        if (!root || !path.startsWith(root + "/"))
            return "";
        const rel = path.substring(root.length + 1);
        const cut = rel.lastIndexOf("/");
        return cut < 0 ? "" : rel.substring(0, cut);
    }
    function parentOf(dir) {
        const cut = dir.lastIndexOf("/");
        return cut < 0 ? "" : dir.substring(0, cut);
    }

    // On the shelf's current wallpaper if it has one, else the top of the shelf.
    function land() {
        const here = kind === currentKind;
        folder = here ? dirOf(kind, currentPath) : "";
        cursor = Math.max(0, here ? results.findIndex(w => w.path === currentPath) : 0);
    }
    function enter(dir) {
        folder = dir;
        // past the ".." tile, onto the first thing actually in the folder
        cursor = results.length > 1 ? 1 : 0;
    }
    function up() {
        const from = folder;
        folder = parentOf(folder);
        cursor = Math.max(0, results.findIndex(w => w.type === "folder" && w.dir === from));
    }

    // Tile i: folders open, ".." climbs, pictures get set.
    function apply(i, stay) {
        const w = results[i];
        if (!w)
            return;
        if (w.type === "folder")
            return enter(w.dir);
        if (w.type === "up")
            return up();
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
        else if (k === Qt.Key_Backspace && query === "" && folder !== "") {
            if (!event.isAutoRepeat)
                up();
        } else if (k === Qt.Key_Tab || k === Qt.Key_Backtab)
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
    //   ┌ WALLPAPER   STILL 445 · LIVE 21   / DYNAMIC-WALLPAPERS ── 002/003 ┐
    //   │ ▸ filter by name▌                                                  │
    //   ├────────────────────────────────────────────────────────────────────┤
    //   │ ┌───────┐ ┏━━━━━━━┓ ┌───────┐                                      │
    //   │ │ ┌┐ .. │ ┃ ┌┐    ┃ │ ┌┐    │      ← folder tiles: a drawn folder, │
    //   │ │ └──┘UP│ ┃ DARK  ┃ │ LIGHT │        the name, how many inside     │
    //   │ └───────┘ ┗━━━━━━━┛ └───────┘                                      │
    //   │ Dark/  · 15                                                        │
    //   └ enter open · ⌫ up · shift-enter try · tab still/live · esc ────────┘
    Rectangle {
        id: sig
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
                    Text {   // where you are
                        width: Math.min(implicitWidth, 460)
                        elide: Text.ElideLeft
                        text: win.crumb.toUpperCase()
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        color: win.searching ? Theme.sigWarn : Theme.sigLabel
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
                    text: "search all folders"
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
                model: win.results
                currentIndex: win.cursor
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: cellHeight * 2

                delegate: Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === win.cursor
                    readonly property bool isFile: modelData.type === "file"
                    readonly property bool now: isFile ? modelData.path === win.currentPath : !!modelData.now
                    width: sigGrid.cellWidth
                    height: sigGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        color: Theme.sigCell
                        border.width: tile.sel ? 2 : 1
                        border.color: tile.sel ? Theme.sigHot : Theme.sigRule

                        Thumb {
                            visible: tile.isFile
                            anchors.fill: parent
                            anchors.margins: tile.sel ? 2 : 1
                            entry: tile.isFile ? tile.modelData : null
                            rev: win.thumbRev
                            fallbackFont: Theme.mono
                            fallbackColor: Theme.sigLabel
                            dim: !tile.sel
                        }

                        // A folder: the first picture inside, barely there behind
                        // a drawn folder, its name, and how many it holds.
                        Thumb {
                            visible: tile.modelData.type === "folder"
                            anchors.fill: parent
                            anchors.margins: tile.sel ? 2 : 1
                            opacity: tile.sel ? 0.22 : 0.12
                            entry: visible ? tile.modelData : null
                            rev: win.thumbRev
                            fallbackColor: "transparent"
                        }
                        Column {
                            visible: !tile.isFile
                            anchors.centerIn: parent
                            spacing: 7
                            FolderGlyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 46
                                height: 34
                                line: tile.sel ? Theme.sigHot : Theme.sigLabel
                                fill: Theme.sigCell
                                label: tile.modelData.type === "up" ? ".." : ""
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(implicitWidth, tile.width - 30)
                                elide: Text.ElideMiddle
                                text: (tile.modelData.type === "up" ? "UP" : tile.modelData.name).toUpperCase()
                                font.family: Theme.mono
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                font.letterSpacing: 1.4
                                color: tile.sel ? Theme.sigValue : Theme.subtext0
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(implicitWidth, tile.width - 30)
                                elide: Text.ElideLeft
                                text: tile.modelData.type === "up"
                                      ? "TO " + (tile.modelData.dir === "" ? "TOP" : tile.modelData.dir.split("/").pop().toUpperCase())
                                      : Theme.pad(tile.modelData.count || 0, 3, "0") + " " + tile.modelData.kind.toUpperCase()
                                font.family: Theme.mono
                                font.pixelSize: 8
                                font.letterSpacing: 1.2
                                color: Theme.sigLabel
                            }
                        }

                        Rectangle {   // status tags, top-left
                            visible: tile.now || (tile.isFile && tile.modelData.kind === "live")
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
                    text: win.caption(win.picked)
                    font.family: Theme.mono
                    font.pixelSize: 10
                    color: Theme.sigValue
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.hints
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
            }
        }
    }

}
