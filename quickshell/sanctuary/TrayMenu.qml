import QtQuick
import Quickshell
import "kit"

// A tray app's menu — right-click its icon (Tray.qml). Drawn by us, in the
// current style. The tray item's own `display()` hands the menu to Qt's native
// QMenu instead, which knows nothing of these styles and comes out as a plain
// white Fusion box — that is the whole reason this file exists.
//
// QsMenuOpener reads the app's DBus menu into entries; we draw each one.
// Submenus open IN PLACE (the card's contents swap, a "back" row appears at
// the top) rather than cascading off to the side — one card, one place to look.
//
// Same full-screen see-through layer as Player.qml: a click anywhere outside the
// card closes it, and the card gets the keyboard.
//
//   ┌───────────────────────────┐
//   │ ‹ BACK                     │  ← only inside a submenu
//   │▌■ Show window              │
//   │ ─────────────────────────  │
//   │   Preferences            › │
//   │   Quit                     │
//   └───────────────────────────┘
//
//   j k ↑ ↓  move     enter l →  pick / open submenu     h ← backspace  back
//   esc q  close
Popup {
    id: win

    name: "traymenu"
    open: Ui.trayMenu !== null
    onDismissed: close()
    cardWidth: measure.cardWidth
    // Hung under the icon, kept on screen.
    centred: false
    cardX: Math.max(8, Math.min(width - cardWidth - 16, Ui.trayX - cardWidth / 2))
    cardY: Theme.barH + 4
    cursor: -1
    onKeyPressed: event => {
        const k = event.key;
        if (k === Qt.Key_J || k === Qt.Key_Down || k === Qt.Key_Tab)
            step(1);
        else if (k === Qt.Key_K || k === Qt.Key_Up || k === Qt.Key_Backtab)
            step(-1);
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_L || k === Qt.Key_Right)
            activate(cursor);
        else if (k === Qt.Key_H || k === Qt.Key_Left || k === Qt.Key_Backspace)
            back();
        else
            return;
        event.accepted = true;
    }

    // Submenus walked into, innermost last. The menu on screen is the top one.
    property var stack: []
    readonly property var menu: stack.length ? stack[stack.length - 1] : Ui.trayMenu
    readonly property var entries: opener.children ? opener.children.values : []

    QsMenuOpener {
        id: opener
        menu: win.menu
    }

    onVisibleChanged: {
        stack = [];
        cursor = -1;
    }
    onMenuChanged: cursor = -1

    function close() {
        Ui.trayMenu = null;
    }

    // DBus menu labels carry GTK mnemonics: "_Quit" means Alt+Q. Drop the single
    // underscores, keep a doubled one as a literal "_".
    function label(e) {
        return String(e.text || "").replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_");
    }
    // Named icons arrive as "image://icon/NAME". Resolve the name ourselves:
    // when the theme lacks it, Quickshell draws a magenta "missing" checkerboard
    // (blueman's *-symbolic icons do this) — better no icon at all. Icons the
    // app sends as pixels (image://dbusmenu/…) pass through.
    function iconOf(e) {
        const s = String(e.icon || "");
        if (!s.startsWith("image://icon/"))
            return s;
        return Quickshell.iconPath(s.substring(13).split("?")[0], true);
    }
    function checkOf(e) {
        return e.buttonType === QsMenuButtonType.RadioButton ? "radio"
             : e.buttonType !== QsMenuButtonType.None ? "box" : "none";
    }

    // Apps send separators carelessly (nm-applet ends on one). Draw one only
    // between two real entries.
    function strayRule(i) {
        if (!entries[i].isSeparator)
            return false;
        let before = false, after = false;
        for (let j = i - 1; j >= 0 && !entries[j].isSeparator; j--) before = true;
        for (let j = i + 1; j < entries.length; j++) {
            if (entries[j].isSeparator)
                break;
            after = true;
        }
        return !before || !after;
    }

    function usable(e) {
        return e && !e.isSeparator && e.enabled;
    }

    function activate(i) {
        const e = entries[i];
        if (!usable(e))
            return;
        if (e.hasChildren) {
            stack = stack.concat([e]);
        } else {
            e.triggered();
            close();
        }
    }
    function back() {
        if (stack.length)
            stack = stack.slice(0, -1);
        else
            close();
    }
    // Move to the next row you could actually pick, skipping separators and
    // greyed-out entries.
    function step(dir) {
        const n = entries.length;
        if (n === 0)
            return;
        let i = cursor;
        for (let tries = 0; tries < n; tries++) {
            i = (i + dir + n) % n;
            if (usable(entries[i])) {
                cursor = i;
                return;
            }
        }
    }

    Measure {
        id: measure
        texts: win.entries.map(e => win.label(e))
        checks: win.entries.some(e => e.buttonType !== QsMenuButtonType.None)
        icons: win.entries.some(e => win.iconOf(e) !== "")
    }

    Panel {
        width: parent.width
        vpad: 6
        spacing: 0

        BackRow {
            visible: win.stack.length > 0
            text: win.stack.length ? win.label(win.stack[win.stack.length - 1]) : ""
            onClicked: win.back()
        }

        Repeater {
            model: win.entries
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: parent.width
                visible: !win.strayRule(index)
                height: visible ? (modelData.isSeparator ? 9 : 28) : 0

                Rule {
                    visible: row.modelData.isSeparator
                }
                MenuItem {
                    visible: !row.modelData.isSeparator
                    text: win.label(row.modelData)
                    check: win.checkOf(row.modelData)
                    checked: row.modelData.checkState === Qt.Checked
                    icon: win.iconOf(row.modelData)
                    usable: win.usable(row.modelData)
                    submenu: row.modelData.hasChildren
                    selected: row.index === win.cursor
                    hasChecks: measure.checks
                    textX: measure.textX
                    onHovered: win.cursor = row.index
                    onClicked: win.activate(row.index)
                }
            }
        }

        Label {
            visible: win.entries.length === 0
            x: 14
            width: implicitWidth
            height: 28
            verticalAlignment: Text.AlignVCenter
            role: "none"
            text: "NO ENTRIES"
        }
    }
}
