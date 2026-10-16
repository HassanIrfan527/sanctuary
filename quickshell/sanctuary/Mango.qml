pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Mango state from `mmsg watch …`. The twin of Niri.qml: same functions, same
// object shapes, so Wm.qml can hand either one to the bar. Only runs inside a
// Mango session ($MANGO_INSTANCE_SIGNATURE set).
//
// Mango has TAGS, not workspaces. Here a tag is dressed as a niri workspace:
//   id    "<output>:<tag>"   (tags are per monitor, so the output is part of it)
//   idx   the tag number, 1–9
// so SignalBar's WS cell and Columns work unchanged.
//
// Each `mmsg watch` prints the FULL current state as its first line, then one
// full line per change (src/ipc/ipc.c in mangowc). So unlike niri there are no
// deltas to apply — every line simply replaces what we had.
Singleton {
    id: root

    readonly property bool active: (Quickshell.env("MANGO_INSTANCE_SIGNATURE") || "") !== ""

    property var workspaces: []   // every tag on every monitor, niri-shaped
    property var windows: ({})    // id -> window, niri-shaped (app_id, title, workspace_id …)
    property int focusedId: -1
    property string focusedOutput: ""
    property bool overview: false

    readonly property var focusedWindow: windows[focusedId] ?? null

    // Like niri's dynamic workspaces: only tags with windows, plus the one
    // being looked at.
    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output && (w.is_active || w.client_count > 0))
                         .sort((a, b) => a.idx - b.idx);
    }

    function windowCount(wsId) {
        const w = workspaces.find(t => t.id === wsId);
        return w ? w.client_count : 0;
    }

    readonly property var focusedWorkspace: {
        const out = focusedOutput || (workspaces.length ? workspaces[0].output : "");
        return workspaces.find(w => w.output === out && w.is_active) ?? null;
    }

    // The layout of the tag being viewed on `output`, as a short word for the
    // bar. Symbols are Mango's own (layouts[] in src/layout/arrange.c).
    readonly property var _layoutWords: ({
        "S": "SCROLL", "T": "TILE", "G": "GRID", "M": "MONO", "K": "DECK",
        "CT": "CENTRE", "RT": "R-TILE", "DW": "DWINDLE", "F": "FAIR",
        "VS": "V-SCROLL", "VT": "V-TILE", "VG": "V-GRID", "VK": "V-DECK", "VF": "V-FAIR"
    })
    function layoutOn(output) {
        const w = workspaces.find(t => t.output === output && t.is_active);
        return w ? (_layoutWords[w.layout] || w.layout) : "";
    }

    // The columns of one tag, left to right, each with its windows top to
    // bottom. Mango's scroller can stack windows in a column (scroller_stack,
    // SUPER+CTRL+H/L); a stack shares one x, so windows are grouped by x.
    // Floating ones are left out, as on niri. wm.sh focus-column counts the
    // same way, so SUPER+N and the strip agree.
    function columnsOf(wsId) {
        const cols = {};
        for (const id in windows) {
            const w = windows[id];
            if (w.workspace_id === wsId && !w.is_floating)
                (cols[w.x] = cols[w.x] || []).push(w);
        }
        return Object.keys(cols).map(Number).sort((a, b) => a - b).map((x, i) => ({
            index: i + 1,
            windows: cols[x].sort((a, b) => a.y - b.y)
        }));
    }

    function focusColumn(n) {
        const ws = focusedWorkspace;
        const col = ws ? columnsOf(ws.id).find(c => c.index === n) : null;
        if (col)
            focusWindow(col.windows[0].id);
    }

    // This tag's layout, by Mango's name (scroller, vertical_tile, …). Mango
    // keeps one layout per tag, so only the tag being viewed changes.
    function setLayout(name) {
        Quickshell.execDetached(["mmsg", "dispatch", "setlayout," + name]);
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached(["mmsg", "dispatch", "view," + idx]);
    }
    // Prev / next through all nine tags, empty ones too — the same as
    // SUPER+P/N in binds.conf, so the wheel and the keys agree. An empty tag
    // appears in the cell while it is the one being viewed.
    function workspaceUp() {
        Quickshell.execDetached(["mmsg", "dispatch", "viewtoleft"]);
    }
    function workspaceDown() {
        Quickshell.execDetached(["mmsg", "dispatch", "viewtoright"]);
    }
    // Shift+scroll on the WS cell: the neighbouring window on this tag.
    // focusdir finds nothing past the last one, so it stops at the edge
    // (focus_window_or_workspace would spill onto the next tag instead).
    function windowLeft() {
        Quickshell.execDetached(["mmsg", "dispatch", "focusdir,left"]);
    }
    function windowRight() {
        Quickshell.execDetached(["mmsg", "dispatch", "focusdir,right"]);
    }

    // A window can sit on a tag that isn't shown: show its tag, then focus it.
    function focusWindow(id) {
        const w = windows[id];
        if (w && w.tags.length)
            Quickshell.execDetached(["mmsg", "dispatch", "view," + w.tags[0]]);
        Quickshell.execDetached(["mmsg", "dispatch", "focusid", "client," + id]);
    }

    // Same as Niri.toggleApp: open the popup app, or close it if it's open.
    function toggleApp(appId, cmd) {
        for (const id in windows) {
            if (windows[id].app_id === appId) {
                Quickshell.execDetached(["mmsg", "dispatch", "killclient", "client," + id]);
                return;
            }
        }
        Quickshell.execDetached(cmd);
    }

    // ── reducers: one full JSON line in, state out ──────────────────────

    // {"all_tags":[{"monitor":"DP-3","tags":[{"index":1,"is_active":true,
    //   "is_urgent":false,"layout":"S","client_count":2}, …]}]}
    function _tags(j) {
        const out = [];
        for (const m of j.all_tags || []) {
            for (const t of m.tags || []) {
                out.push({
                    id: m.monitor + ":" + t.index,
                    idx: t.index,
                    name: "",
                    output: m.monitor,
                    is_active: t.is_active,
                    is_focused: t.is_active && (focusedOutput === "" || m.monitor === focusedOutput),
                    is_urgent: t.is_urgent,
                    layout: t.layout,
                    client_count: t.client_count
                });
            }
        }
        workspaces = out;
    }

    // Mango client → the niri window fields the shell reads.
    function _window(c) {
        const tags = c.tags || [];
        return {
            id: c.id,
            app_id: c.appid || "",
            title: c.title || "",
            output: c.monitor,
            tags: tags,
            workspace_id: tags.length ? c.monitor + ":" + tags[0] : "",
            is_floating: c.is_floating,
            is_focused: c.is_focused,
            is_urgent: c.is_urgent,
            x: c.x,
            y: c.y
        };
    }

    // {"clients":[{…}, …]}
    function _clients(j) {
        const m = {};
        let f = -1;
        for (const c of j.clients || []) {
            m[c.id] = _window(c);
            if (c.is_focused)
                f = c.id;
        }
        windows = m;
        if (f !== -1)
            focusedId = f;
    }

    // One client, or {"id":null,…} when nothing has focus. Also carries the
    // freshest title, so a terminal renaming itself shows up straight away.
    function _focus(c) {
        if (c.id === null || c.id === undefined) {
            focusedId = -1;
            return;
        }
        const m = Object.assign({}, windows);
        m[c.id] = _window(c);
        windows = m;
        focusedId = c.id;
        if (c.monitor && c.monitor !== focusedOutput) {
            focusedOutput = c.monitor;
            _patchFocusedOutput();
        }
    }

    function _patchFocusedOutput() {
        workspaces = workspaces.map(w => Object.assign({}, w, { is_focused: w.is_active && w.output === focusedOutput }));
    }

    // ── the streams ─────────────────────────────────────────────────────

    component Watch: Process {
        id: proc
        required property string what
        property var handler
        running: root.active
        command: ["mmsg", "watch", what]
        stdout: SplitParser {
            onRead: line => {
                if (!line.trim())
                    return;
                try {
                    proc.handler(JSON.parse(line));
                } catch (e) {
                    console.warn("mango: unparsable", proc.what, "line:", line.slice(0, 120));
                }
            }
        }
        // Mango restarting or the socket dropping ends the stream; the first
        // line of a new one is the full state again.
        onExited: if (root.active) retry.start()
        property Timer retry: Timer {
            interval: 1000
            onTriggered: proc.running = true
        }
    }

    Watch { what: "all-tags"; handler: j => root._tags(j) }
    Watch { what: "all-clients"; handler: j => root._clients(j) }
    Watch { what: "focusing-client"; handler: j => root._focus(j) }
}
