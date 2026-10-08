pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// niri state from `niri msg --json event-stream`. Quickshell has no built-in
// niri module, but niri's stream does the hard part: the first lines it prints
// are the FULL state (WorkspacesChanged, WindowsChanged), and every line after
// is a delta. So this is a reducer, nothing more.
//
// Arrays and maps are replaced, never mutated in place. QML only re-evaluates a
// binding when the property is reassigned, so a mutation would update nothing.
Singleton {
    id: root

    property var workspaces: []   // niri's workspace objects
    property var windows: ({})    // id -> niri window object
    property int focusedId: -1
    property bool overview: false

    readonly property var focusedWindow: windows[focusedId] ?? null

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx);
    }

    function windowCount(wsId) {
        let n = 0;
        for (const id in windows)
            if (windows[id].workspace_id === wsId)
                n++;
        return n;
    }

    readonly property var focusedWorkspace: workspaces.find(w => w.is_focused) ?? null

    // The scrolling layout of one workspace, left to right: one entry per
    // column, its windows top to bottom. Index 0 is what Mod+1 focuses.
    // Floating windows have no column (pos_in_scrolling_layout is null) and
    // are left out.
    function columnsOf(wsId) {
        const cols = {};
        for (const id in windows) {
            const w = windows[id];
            const pos = w.layout ? w.layout.pos_in_scrolling_layout : null;
            if (w.workspace_id !== wsId || !pos)
                continue;
            (cols[pos[0]] = cols[pos[0]] || []).push(w);
        }
        return Object.keys(cols).map(Number).sort((a, b) => a - b).map(c => ({
            index: c,
            windows: cols[c].sort((a, b) => a.layout.pos_in_scrolling_layout[1] - b.layout.pos_in_scrolling_layout[1])
        }));
    }

    function focusColumn(n) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-column", String(n)]);
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }
    function workspaceUp() {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"]);
    }
    function workspaceDown() {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"]);
    }

    // A "popup app": a floating kitty with its own app-id (btop, the mixer).
    // Open it if it isn't, close it if it is — so the same click dismisses it.
    function toggleApp(appId, cmd) {
        for (const id in windows) {
            if (windows[id].app_id === appId) {
                Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", String(id)]);
                return;
            }
        }
        Quickshell.execDetached(cmd);
    }

    function _patchWorkspaces(fn) {
        workspaces = workspaces.map(w => {
            const c = Object.assign({}, w);
            fn(c);
            return c;
        });
    }

    function handle(ev) {
        if (ev.WorkspacesChanged) {
            workspaces = ev.WorkspacesChanged.workspaces;
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id;
            const focused = ev.WorkspaceActivated.focused;
            const target = workspaces.find(w => w.id === id);
            const out = target ? target.output : null;
            _patchWorkspaces(w => {
                if (w.output === out)
                    w.is_active = (w.id === id);
                if (focused)
                    w.is_focused = (w.id === id);
            });
        } else if (ev.WorkspaceUrgencyChanged) {
            const u = ev.WorkspaceUrgencyChanged;
            _patchWorkspaces(w => {
                if (w.id === u.id)
                    w.is_urgent = u.urgent;
            });
        } else if (ev.WorkspaceActiveWindowChanged) {
            const a = ev.WorkspaceActiveWindowChanged;
            _patchWorkspaces(w => {
                if (w.id === a.workspace_id)
                    w.active_window_id = a.active_window_id;
            });
        } else if (ev.WindowsChanged) {
            const m = {};
            let f = -1;
            for (const w of ev.WindowsChanged.windows) {
                m[w.id] = w;
                if (w.is_focused)
                    f = w.id;
            }
            windows = m;
            focusedId = f;
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window;
            const m = Object.assign({}, windows);
            m[w.id] = w;
            windows = m;
            if (w.is_focused)
                focusedId = w.id;
        } else if (ev.WindowClosed) {
            const id = ev.WindowClosed.id;
            const m = Object.assign({}, windows);
            delete m[id];
            windows = m;
            if (focusedId === id)
                focusedId = -1;
        } else if (ev.WindowLayoutsChanged) {
            // Columns moved (Mod+Shift+N, a window opened or closed beside
            // them): each change is an [id, layout] pair.
            const m = Object.assign({}, windows);
            for (const c of ev.WindowLayoutsChanged.changes) {
                if (m[c[0]])
                    m[c[0]] = Object.assign({}, m[c[0]], { layout: c[1] });
            }
            windows = m;
        } else if (ev.WindowFocusChanged) {
            focusedId = ev.WindowFocusChanged.id ?? -1;
        } else if (ev.WindowUrgencyChanged) {
            const u = ev.WindowUrgencyChanged;
            if (windows[u.id]) {
                const m = Object.assign({}, windows);
                m[u.id] = Object.assign({}, m[u.id], { is_urgent: u.urgent });
                windows = m;
            }
        } else if (ev.OverviewOpenedOrClosed) {
            overview = ev.OverviewOpenedOrClosed.is_open;
        }
    }

    Process {
        id: stream
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.handle(JSON.parse(line));
                } catch (e) {
                    console.warn("niri: unparsable event:", line.slice(0, 120));
                }
            }
        }
        // niri restarting (or a config reload that drops the socket) ends the
        // stream. Reconnect; the first lines of a new stream are full state.
        onExited: reconnect.start()
    }

    Timer {
        id: reconnect
        interval: 1000
        onTriggered: stream.running = true
    }
}
