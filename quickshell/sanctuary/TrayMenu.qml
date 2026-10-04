import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

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
//   j k ↑ ↓  move     enter l →  pick / open submenu     h ← backspace  back
//   esc q  close
PanelWindow {
    id: win

    visible: Ui.trayMenu !== null
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-traymenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Submenus walked into, innermost last. The menu on screen is the top one.
    property var stack: []
    readonly property var menu: stack.length ? stack[stack.length - 1] : Ui.trayMenu
    readonly property var entries: opener.children ? opener.children.values : []
    property int cursor: -1

    readonly property int cardTop: (Theme.signal ? Theme.sigBarH : Theme.inkBarH) + 4
    readonly property int rowH: Theme.signal ? 28 : 34

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
    // The left gutters exist only when some entry in this menu uses them.
    readonly property bool hasChecks: entries.some(e => e.buttonType !== QsMenuButtonType.None)
    readonly property bool hasIcons: entries.some(e => iconOf(e) !== "")
    readonly property int textX: (Theme.signal ? 14 : 10) + (hasChecks ? 16 : 0) + (hasIcons ? 24 : 0)

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

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: win.close()
    }

    // Widest label, measured off-screen — the card fits its longest entry
    // (within limits) instead of a fixed width that clips or swims.
    Column {
        id: measure
        visible: false
        Repeater {
            model: win.entries
            Text {
                required property var modelData
                text: win.label(modelData)
                font.family: Theme.signal ? Theme.mono : Theme.sans
                font.pixelSize: Theme.signal ? 12 : 13
                font.weight: Theme.signal ? Font.Normal : Font.Bold
            }
        }
    }

    Item {
        id: card
        focus: true
        // Text + check + icon + submenu arrow + padding.
        width: Math.max(200, Math.min(420, measure.width + win.textX + (Theme.signal ? 48 : 64)))
        height: Theme.signal ? sig.height : inkCard.height + 6
        // Hung under the icon, kept on screen.
        x: Math.max(8, Math.min(win.width - width - 16, Ui.trayX - width / 2))
        y: win.cardTop

        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape || k === Qt.Key_Q)
                win.close();
            else if (k === Qt.Key_J || k === Qt.Key_Down || k === Qt.Key_Tab)
                win.step(1);
            else if (k === Qt.Key_K || k === Qt.Key_Up || k === Qt.Key_Backtab)
                win.step(-1);
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_L || k === Qt.Key_Right)
                win.activate(win.cursor);
            else if (k === Qt.Key_H || k === Qt.Key_Left || k === Qt.Key_Backspace)
                win.back();
            else
                return;
            event.accepted = true;
        }

        MouseArea {   // swallow clicks on the card
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        // ══ Signal ═══════════════════════════════════════════════════
        //
        //   ┌───────────────────────────┐
        //   │ ‹ BACK                     │  ← only inside a submenu
        //   │▌■ Show window              │
        //   │ ─────────────────────────  │
        //   │   Preferences            › │
        //   │   Quit                     │
        //   └───────────────────────────┘
        Rectangle {
            id: sig
            visible: Theme.signal
            width: parent.width
            height: sigCol.implicitHeight + 12
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
                y: 6
                width: parent.width - 2

                // back row, inside a submenu
                Rectangle {
                    visible: win.stack.length > 0
                    width: parent.width
                    height: win.rowH
                    color: backHover.containsMouse ? Theme.sigCell : "transparent"
                    Text {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "‹ " + (win.stack.length ? win.label(win.stack[win.stack.length - 1]).toUpperCase() : "")
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 1.6
                        color: Theme.sigHot
                    }
                    MouseArea {
                        id: backHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.back()
                    }
                }

                Repeater {
                    model: Theme.signal ? win.entries : []
                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === win.cursor
                        readonly property bool on: win.usable(modelData)
                        width: sigCol.width
                        visible: !win.strayRule(index)
                        height: visible ? (modelData.isSeparator ? 9 : win.rowH) : 0

                        Rectangle {   // separator
                            visible: row.modelData.isSeparator
                            x: 14
                            width: parent.width - 28
                            height: 1
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.sigRule
                        }

                        Rectangle {
                            visible: !row.modelData.isSeparator
                            anchors.fill: parent
                            color: row.sel ? Theme.sigCell : "transparent"

                            Rectangle {
                                width: 2
                                height: parent.height
                                color: Theme.sigHot
                                visible: row.sel
                            }

                            // Check / radio state: a small square lamp, lit when on.
                            Rectangle {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                visible: row.modelData.buttonType !== QsMenuButtonType.None
                                width: 7
                                height: 7
                                radius: row.modelData.buttonType === QsMenuButtonType.RadioButton ? 4 : 0
                                color: row.modelData.checkState === Qt.Checked ? Theme.sigHot : "transparent"
                                border.width: 1
                                border.color: row.modelData.checkState === Qt.Checked ? Theme.sigHot : Theme.surface2
                            }
                            IconImage {
                                x: 14 + (win.hasChecks ? 16 : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                visible: source != ""
                                implicitSize: 14
                                source: win.iconOf(row.modelData)
                                asynchronous: true
                                opacity: row.on ? 1 : 0.4
                            }
                            Text {
                                x: win.textX
                                width: parent.width - win.textX - 30
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: win.label(row.modelData)
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.weight: row.sel ? Font.Bold : Font.Normal
                                color: !row.on ? Theme.surface2 : row.sel ? Theme.sigHot : Theme.sigValue
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                visible: row.modelData.hasChildren
                                text: "›"
                                font.family: Theme.mono
                                font.pixelSize: 13
                                color: row.sel ? Theme.sigHot : Theme.sigLabel
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: row.on
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.cursor = row.index
                            onClicked: win.activate(row.index)
                        }
                    }
                }

                Text {
                    visible: win.entries.length === 0
                    x: 14
                    height: win.rowH
                    verticalAlignment: Text.AlignVCenter
                    text: "NO ENTRIES"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1.6
                    color: Theme.surface2
                }
            }
        }

        // ══ Ink / Paper ══════════════════════════════════════════════
        // A narrow panel with the hard mauve shadow. Rows are flat on the page;
        // the selected one is inked solid with paper-coloured lettering — the
        // same move as the focused workspace on the bar.
        Item {
            id: inkCard
            visible: Theme.ink
            width: parent.width - 6
            height: inkCol.implicitHeight + 16

            Rectangle {
                x: 6
                y: 6
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
                x: 8
                y: 8
                width: parent.width - 16

                Item {
                    visible: win.stack.length > 0
                    width: parent.width
                    height: win.rowH
                    Rectangle {
                        anchors.fill: parent
                        color: inkBack.containsMouse ? Theme.paperHover : "transparent"
                    }
                    Text {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "‹ " + (win.stack.length ? win.label(win.stack[win.stack.length - 1]).toUpperCase() : "")
                        font.family: Theme.sans
                        font.weight: Font.Black
                        font.pixelSize: 11
                        font.letterSpacing: 0.6
                        color: Theme.inkSoft
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: Theme.inkLine
                    }
                    MouseArea {
                        id: inkBack
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.back()
                    }
                }

                Repeater {
                    model: Theme.ink ? win.entries : []
                    delegate: Item {
                        id: irow
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === win.cursor
                        readonly property bool on: win.usable(modelData)
                        width: inkCol.width
                        visible: !win.strayRule(index)
                        height: visible ? (modelData.isSeparator ? 10 : win.rowH) : 0

                        Rectangle {   // separator: a ruled ink line
                            visible: irow.modelData.isSeparator
                            x: 6
                            width: parent.width - 12
                            height: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.inkMuted
                        }

                        Rectangle {
                            visible: !irow.modelData.isSeparator
                            anchors.fill: parent
                            color: irow.sel ? Theme.inkLine : "transparent"

                            // Check / radio: a small inked box, filled when on.
                            Rectangle {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                visible: irow.modelData.buttonType !== QsMenuButtonType.None
                                width: 10
                                height: 10
                                radius: irow.modelData.buttonType === QsMenuButtonType.RadioButton ? 5 : 0
                                color: irow.modelData.checkState === Qt.Checked
                                       ? (irow.sel ? Theme.paper : Theme.inkLine) : "transparent"
                                border.width: 2
                                border.color: irow.sel ? Theme.paper : Theme.inkLine
                            }
                            IconImage {
                                x: 10 + (win.hasChecks ? 16 : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                visible: source != ""
                                implicitSize: 16
                                source: win.iconOf(irow.modelData)
                                asynchronous: true
                                opacity: irow.on ? 1 : 0.4
                            }
                            Text {
                                x: win.textX
                                width: parent.width - win.textX - 28
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: win.label(irow.modelData)
                                font.family: Theme.sans
                                font.weight: Font.Bold
                                font.pixelSize: 13
                                color: !irow.on ? Theme.inkMuted : irow.sel ? Theme.paper : Theme.inkLine
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                visible: irow.modelData.hasChildren
                                text: "›"
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 16
                                color: irow.sel ? Theme.paper : Theme.inkSoft
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: irow.on
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.cursor = irow.index
                            onClicked: win.activate(irow.index)
                        }
                    }
                }

                Text {
                    visible: win.entries.length === 0
                    x: 10
                    height: win.rowH
                    verticalAlignment: Text.AlignVCenter
                    text: "NOTHING HERE."
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 11
                    color: Theme.inkMuted
                }
            }
        }
    }
}
