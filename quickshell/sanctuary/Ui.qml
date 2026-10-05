pragma Singleton
import QtQuick
import Quickshell

// Shell-wide UI state. Flipped by the IPC handlers in shell.qml (keybinds) and
// by clicks on the bar.
Singleton {
    property bool barShown: true    // Mod+Shift+A
    property bool centreOpen: false // Mod+Shift+D
    property bool pickerOpen: false // Mod+Shift+T
    property bool launcherOpen: false // Mod+Space
    signal launcherType(string text)  // debug hooks — see shell.qml `debug`
    signal launcherEnter()
    property bool playerOpen: false // right-click the music module
    property real playerX: 0        // screen x of that module's centre — the card hangs from it
    property bool powerOpen: false  // Mod+Shift+Escape
    property bool wallOpen: false   // Mod+Shift+W
    property bool rigOpen: false    // Mod+U, or click the ◉ cell — the recorders card
    property bool captureOpen: false // Ctrl+Print, or SCREEN in RIG — the region overlay
    // Right-click a tray icon: that app's menu, drawn by TrayMenu.qml.
    property var trayMenu: null     // the item's QsMenuHandle; null = closed
    property real trayX: 0          // screen x of the icon's centre — the menu hangs from it
}
