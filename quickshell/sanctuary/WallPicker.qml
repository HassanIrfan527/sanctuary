import QtQuick
import Quickshell
import Quickshell.Io
import "kit"

// The wallpaper picker — Mod+Shift+W (scripts/sanctuary/wallpaper.sh open).
// Drawn in the current style; when Quickshell is down the same key opens yazi.
//
// Two shelves: STILL (~/Pictures/Wallpapers, applied by awww) and LIVE
// (~/Videos/Wallpapers, played by mpvpaper through livewall.sh). Setting a still
// stops a live one — it is a layer above awww and would hide the change.
//
// Each shelf is a folder tree. Off search you see one folder at a time: its
// subfolders first (drawn folder tiles, the kit's FolderGlyph), then the pictures
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
Popup {
    id: win

    name: "wallpaper"
    open: Ui.wallOpen
    onDismissed: Ui.wallOpen = false
    cardWidth: 1000
    qCloses: false   // q is typed into the search

    readonly property string scripts: Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary/"

    property var all: []              // { type: "file", kind, path, thumb, name, dir }
    property var roots: ({ still: "", live: "" })
    property string currentKind: "still"
    property string currentPath: ""
    property string kind: "still"     // the shelf on show
    property string folder: ""        // where you are on it, relative to its root; "" = top
    property string query: ""
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
            prompt.text = "";
            lister.running = true;
            Qt.callLater(() => prompt.focusInput());
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

    // ══ a contact sheet ═════════════════════════════════════════════
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
    Panel {
        width: parent.width
        pad: 0
        vpad: 0
        spacing: 0

        // header: title, shelves, position
        TitleBar {
            title: "WALLPAPER"
            detail: Theme.pad(win.results.length ? win.cursor + 1 : 0, 3, "0") + "/"
                    + Theme.pad(win.results.length, 3, "0")
            Repeater {
                model: [{ k: "still", n: win.stillCount }, { k: "live", n: win.liveCount }]
                delegate: Tab {
                    required property var modelData
                    kind: "shelf"
                    text: modelData.k.toUpperCase() + " " + modelData.n
                    on: win.kind === modelData.k
                    onClicked: win.kind = modelData.k
                }
            }
            Label {   // where you are
                width: Math.min(implicitWidth, 460)
                role: "path"
                tone: win.searching ? "warn" : ""
                text: win.crumb.toUpperCase()
            }
        }

        // filter prompt
        Prompt {
            id: prompt
            placeholder: "search all folders"
            onEdited: t => win.query = t
            onKeyPressed: event => win.key(event)
        }

        Rule { inset: 0; height: 1 }
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

            delegate: PhotoTile {
                required property var modelData
                required property int index
                width: sigGrid.cellWidth
                height: sigGrid.cellHeight
                kind: modelData.type
                entry: modelData
                rev: win.thumbRev
                name: modelData.type === "up" ? "UP" : modelData.name
                sub: modelData.type === "up"
                     ? "TO " + (modelData.dir === "" ? "TOP" : modelData.dir.split("/").pop().toUpperCase())
                     : Theme.pad(modelData.count || 0, 3, "0") + " " + modelData.kind.toUpperCase()
                selected: index === win.cursor
                now: modelData.type === "file" ? modelData.path === win.currentPath : !!modelData.now
                live: modelData.kind === "live"
                onHovered: win.cursor = index
                onClicked: win.apply(index, false)
            }

            Label {
                anchors.centerIn: parent
                width: implicitWidth
                visible: win.results.length === 0
                role: "nomatch"
                text: lister.running ? "READING…" : "NO MATCH"
            }
        }

        Item { width: 1; height: 6 }
        Rule { inset: 0; height: 1 }

        // footer: the name under the cursor, the keys
        FooterBar {
            leftText: win.caption(win.picked)
            leftRole: "caption"
            leftWidth: width * 0.5
            rightText: win.hints
            rightRole: "fine"
        }
    }
}
