pragma Singleton
import QtQuick
import Quickshell

// "The compositor", whichever one this session runs. The shell talks only to
// Wm; Wm hands each call to Niri.qml or Mango.qml. Both expose the same
// functions and the same niri-shaped objects, so nothing else has to know.
//
// Mango's tags come through as workspaces (see Mango.qml's header).
Singleton {
    id: root

    readonly property bool isMango: Mango.active
    readonly property bool isNiri: !Mango.active
    readonly property var backend: Mango.active ? Mango : Niri

    readonly property var workspaces: backend.workspaces
    readonly property var windows: backend.windows
    readonly property int focusedId: backend.focusedId
    readonly property var focusedWindow: backend.focusedWindow
    readonly property var focusedWorkspace: backend.focusedWorkspace

    function workspacesOn(output) { return backend.workspacesOn(output); }
    function windowCount(wsId) { return backend.windowCount(wsId); }
    function columnsOf(wsId) { return backend.columnsOf(wsId); }
    function layoutOn(output) { return backend.layoutOn(output); }
    function setLayout(name) { backend.setLayout(name); }

    function focusWorkspace(idx) { backend.focusWorkspace(idx); }
    function workspaceUp() { backend.workspaceUp(); }
    function workspaceDown() { backend.workspaceDown(); }
    function windowLeft() { backend.windowLeft(); }
    function windowRight() { backend.windowRight(); }

    // The WS cell's wheel, shared by every bar style. Plain scroll walks
    // workspaces; Shift+scroll walks the windows of this one (up = left).
    // Some stacks turn Shift+wheel into a horizontal wheel, so x counts too.
    function wheel(w) {
        const d = w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x;
        if (d === 0)
            return;
        if (w.modifiers & Qt.ShiftModifier)
            d > 0 ? windowLeft() : windowRight();
        else
            d > 0 ? workspaceUp() : workspaceDown();
    }
    function focusColumn(n) { backend.focusColumn(n); }
    function focusWindow(id) { backend.focusWindow(id); }
    function toggleApp(appId, cmd) { backend.toggleApp(appId, cmd); }
}
