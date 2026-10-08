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
    property bool patchOpen: false  // Mod+O — audio in/out switcher (Patch.qml)
    property bool rigOpen: false    // Mod+U, or click the ◉ cell — the recorders card
    property bool captureOpen: false // Ctrl+Print, or SCREEN in RIG — the region overlay
    property bool columnsOpen: false // Mod+Grave — the column strip, held open to pick from
    property bool keysOpen: false   // Mod+/ — the keybind cheat sheet (KeySheet.qml)
    property bool commsOpen: false  // Mod+C, or click the VC cell — Discord voice (CommsCard.qml)
    // Right-click a tray icon: that app's menu, drawn by TrayMenu.qml.
    property var trayMenu: null     // the item's QsMenuHandle; null = closed
    property real trayX: 0          // screen x of the icon's centre — the menu hangs from it
}
