import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// The app launcher — Mod+Space (scripts/sanctuary/launcher.sh). Drawn in the
// current style; when Quickshell is down (fallback) the same key opens fsel.
//
// Type to filter. Ranking: name starts with the query > a word in the name
// starts with it > a word in the generic name / keywords starts with it >
// anywhere in the name > anywhere in generic name / keywords > comment >
// letters in order. Apps you launch often float up (counts in
// ~/.local/state/sanctuary/launches.json). Empty query = most-launched first.
//
//   enter  launch     ↑ ↓ · ctrl-j ctrl-k · ctrl-n ctrl-p  move     esc  close
//   click a row to launch it; click outside to close
PanelWindow {
    id: win

    visible: Ui.launcherOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property int cursor: 0
    readonly property int rows: Theme.signal ? 10 : 7

    // Every visible app, once. noDisplay entries are hidden by their own choice.
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    readonly property var results: rank(query)

    onVisibleChanged: {
        if (visible) {
            // Clear the fields themselves: a `text: query` binding would break
            // the moment you type, and the old query would come back next time.
            sigInput.text = "";
            inkInput.text = "";
            cursor = 0;
            Qt.callLater(() => (Theme.signal ? sigInput : inkInput).forceActiveFocus());
        }
    }
    onQueryChanged: cursor = 0

    // ── launch counts ─────────────────────────────────────────────────
    property var counts: ({})
    FileView {
        id: countsFile
        path: Quickshell.env("HOME") + "/.local/state/sanctuary/launches.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                win.counts = JSON.parse(countsFile.text()) || {};
            } catch (e) {
                win.counts = {};
            }
        }
    }
    function bump(id) {
        const c = Object.assign({}, counts);
        c[id] = (c[id] || 0) + 1;
        counts = c;
        countsFile.setText(JSON.stringify(c));
    }

    // ── ranking ───────────────────────────────────────────────────────
    function subsequence(hay, needle) {
        let i = 0;
        for (let j = 0; j < hay.length && i < needle.length; j++)
            if (hay[j] === needle[i])
                i++;
        return i === needle.length;
    }
    function score(a, q) {
        const name = a.name.toLowerCase();
        let s = 0;
        if (name.startsWith(q))
            s = 100;
        else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            s = 80;
        // A word in the description starting with the query ("te" → Terminal,
        // Text Editor) says more about intent than letters buried mid-name
        // ("te" → Bluetooth Adap-te-rs), so it outranks a plain substring.
        else if ((a.genericName || "").toLowerCase().split(/[\s\-_.]+/).some(w => w.startsWith(q))
                 || (a.keywords || []).some(k => k.toLowerCase().startsWith(q)))
            s = 65;
        else if (name.indexOf(q) >= 0)
            s = 60;
        else if ((a.genericName || "").toLowerCase().indexOf(q) >= 0
                 || (a.keywords || []).some(k => k.toLowerCase().indexOf(q) >= 0))
            s = 40;
        else if ((a.comment || "").toLowerCase().indexOf(q) >= 0)
            s = 25;
        else if (subsequence(name, q))
            s = 15;
        if (s === 0)
            return 0;
        return s + Math.log((counts[a.id] || 0) + 1) * 8;
    }
    function rank(q) {
        q = q.trim().toLowerCase();
        let list;
        if (q === "") {
            list = apps.slice().sort((a, b) => ((counts[b.id] || 0) - (counts[a.id] || 0))
                                              || a.name.localeCompare(b.name));
        } else {
            list = apps.map(a => ({ a: a, s: score(a, q) }))
                       .filter(x => x.s > 0)
                       .sort((x, y) => (y.s - x.s) || x.a.name.localeCompare(y.a.name))
                       .map(x => x.a);
        }
        return list;
    }

    function launch(i) {
        const e = results[i];
        if (!e)
            return;
        bump(e.id);
        Ui.launcherOpen = false;
        if (e.runInTerminal)
            Quickshell.execDetached(["kitty", "-e"].concat(e.command));
        else
            e.execute();
    }

    // Test hooks (IPC `debug launcherType` / `launcherEnter`): drive it without a keyboard.
    function typeText(t) { (Theme.signal ? sigInput : inkInput).text = t; }
    function enter() { launch(cursor); }
    Connections {
        target: Ui
        function onLauncherType(t) { win.typeText(t); }
        function onLauncherEnter() { win.enter(); }
    }

    function key(event) {
        const k = event.key, ctrl = event.modifiers & Qt.ControlModifier;
        const n = Math.min(results.length, rows);
        if (k === Qt.Key_Escape) {
            Ui.launcherOpen = false;
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            launch(cursor);
        } else if (k === Qt.Key_Down || (ctrl && (k === Qt.Key_J || k === Qt.Key_N))) {
            if (n > 0)
                cursor = (cursor + 1) % n;
        } else if (k === Qt.Key_Up || (ctrl && (k === Qt.Key_K || k === Qt.Key_P))) {
            if (n > 0)
                cursor = (cursor + n - 1) % n;
        } else {
            return;
        }
        event.accepted = true;
    }

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.launcherOpen = false
    }

    // ══ Signal: a run prompt on an instrument ════════════════════════
    //
    //   ┌ RUN ──────────────────────────────────── 50 APPS ┐
    //   │ ▸ fir▌                                           │
    //   ├──────────────────────────────────────────────────┤
    //   │▌01  Firefox        Web Browser             12×  │
    //   │ 02  Files          File Manager                 │
    //   │ enter run · ctrl-j/k move · esc         01/03    │
    //   └──────────────────────────────────────────────────┘
    Rectangle {
        id: sig
        visible: Theme.signal
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.18)
        width: 620
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

            // header
            Item {
                width: parent.width
                height: 30
                Text {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "RUN"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    color: Theme.sigHot
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.apps.length + " APPS"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1.4
                    color: Theme.sigLabel
                }
            }

            // prompt
            Item {
                width: parent.width
                height: 40
                Text {
                    id: chev
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▸"
                    font.family: Theme.mono
                    font.pixelSize: 15
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
                    font.pixelSize: 15
                    color: Theme.sigValue
                    selectionColor: Theme.surface1
                    cursorDelegate: Rectangle { width: 8; color: Theme.sigHot; opacity: 0.8 }
                    Keys.onPressed: event => win.key(event)
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.sigRule }

            // rows
            Repeater {
                model: Theme.signal ? win.results.slice(0, win.rows) : []
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === win.cursor
                    width: sigCol.width
                    height: 30
                    color: sel ? Theme.sigCell : "transparent"

                    Rectangle {
                        width: 2
                        height: parent.height
                        color: Theme.sigHot
                        visible: row.sel
                    }
                    Row {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        Text {
                            text: Theme.pad(row.index + 1, 2, "0")
                            font.family: Theme.mono
                            font.pixelSize: 10
                            color: Theme.surface2
                        }
                        Text {
                            width: 200
                            elide: Text.ElideRight
                            text: row.modelData.name
                            font.family: Theme.mono
                            font.pixelSize: 12
                            font.weight: row.sel ? Font.Bold : Font.Normal
                            color: row.sel ? Theme.sigHot : Theme.sigValue
                        }
                        Text {
                            width: 250
                            elide: Text.ElideRight
                            text: row.modelData.genericName || row.modelData.comment || ""
                            font.family: Theme.mono
                            font.pixelSize: 10
                            color: Theme.sigLabel
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: (win.counts[row.modelData.id] || 0) > 0 ? win.counts[row.modelData.id] + "×" : ""
                        font.family: Theme.mono
                        font.pixelSize: 9
                        color: Theme.surface2
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.cursor = row.index
                        onClicked: win.launch(row.index)
                    }
                }
            }

            // nothing matched: say so, once, quietly
            Item {
                visible: win.results.length === 0
                width: parent.width
                height: 30
                Text {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "no match"
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.surface2
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.sigRule }

            // footer
            Item {
                width: parent.width
                height: 28
                Text {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "enter run · ctrl-j/k move · esc close"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.pad(win.results.length ? win.cursor + 1 : 0, 2, "0") + "/"
                          + Theme.pad(win.results.length, 2, "0")
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.sigLabel
                }
            }
        }
    }

    // ══ Ink / Paper: a manga page ════════════════════════════════════
    //
    //   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    //   ┃ LAUNCH!                     ░░▒▒▓▓      ┃  ← lettered masthead, screentone
    //   ┃   ╭────────────────────────────╮       ┃
    //   ┃   │ fir▌                       │       ┃  ← the query in a speech bubble
    //   ┃   ╰──╲─────────────────────────╯       ┃
    //   ┃ ┌──┐ FIREFOX   web browser           ▉┃  ← selected: hard peach shadow
    //   ┃ └──┘                                    ┃
    //   ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
    Item {
        id: ink
        visible: Theme.ink
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.14)
        width: 560
        height: inkCol.implicitHeight + 40

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
            x: 22
            y: 18
            width: parent.width - 44
            spacing: 14

            // masthead
            Item {
                width: parent.width
                height: 40
                InkHalftone {
                    anchors.fill: parent
                    from: 0.45
                    strength: 0.25
                    step: 6
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "LAUNCH!"
                    font.family: Theme.display
                    font.weight: Theme.displayWeight
                    font.pixelSize: Theme.hasBangers ? 38 : 30
                    color: Theme.inkLine
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.results.length + " / " + win.apps.length
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 10
                    color: Theme.inkSoft
                }
            }

            // the query, in a speech bubble
            Item {
                width: parent.width
                height: 50 + 12
                InkBubbleShape {
                    x: 4 + Theme.inkShadow
                    y: 12 + Theme.inkShadow
                    width: parent.width - 12
                    height: 46
                    tail: 12
                    tailX: 70
                    fill: Theme.peach
                    stroke: "transparent"
                }
                InkBubbleShape {
                    x: 4
                    y: 12
                    width: parent.width - 12
                    height: 46
                    tail: 12
                    tailX: 70
                }
                TextInput {
                    id: inkInput
                    x: 24
                    y: 12 + (46 - height) / 2
                    width: parent.width - 60
                    onTextChanged: win.query = text
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 17
                    color: Theme.inkLine
                    selectionColor: Theme.paperShade
                    cursorDelegate: Rectangle { width: 3; color: Theme.inkLine }
                    Keys.onPressed: event => win.key(event)
                }
                Text {
                    x: 24
                    y: 12 + (46 - height) / 2
                    visible: win.query === ""
                    text: "what are we opening?"
                    font.family: Theme.sans
                    font.weight: Font.Bold
                    font.pixelSize: 15
                    color: Theme.inkMuted
                }
            }

            // results: small panels
            Column {
                width: parent.width
                spacing: 9
                Repeater {
                    model: Theme.ink ? win.results.slice(0, win.rows) : []
                    delegate: Item {
                        id: irow
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === win.cursor
                        width: parent.width - 6
                        height: 44

                        Rectangle {
                            x: irow.sel ? 5 : 2
                            y: irow.sel ? 5 : 2
                            width: parent.width
                            height: parent.height
                            color: irow.sel ? Theme.peach : Theme.paperShade
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.paper
                            border.width: irow.sel ? Theme.inkStroke : 2
                            border.color: Theme.inkLine

                            Row {
                                x: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Rectangle {   // the icon, in its own little panel
                                    width: 30
                                    height: 30
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.paper
                                    border.width: 2
                                    border.color: Theme.inkLine
                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 20
                                        // iconPath(…, true) answers "" for a missing icon; fall
                                        // back by hand (the string-fallback form didn't resolve).
                                        source: Quickshell.iconPath(irow.modelData.icon, true)
                                                || Quickshell.iconPath("application-x-executable", true)
                                        asynchronous: true
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 200
                                    elide: Text.ElideRight
                                    text: irow.modelData.name.toUpperCase()
                                    font.family: Theme.sans
                                    font.weight: Font.Black
                                    font.pixelSize: 13
                                    font.letterSpacing: 0.4
                                    color: Theme.inkLine
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 220
                                    elide: Text.ElideRight
                                    text: irow.modelData.genericName || irow.modelData.comment || ""
                                    font.family: Theme.sans
                                    font.weight: Font.Medium
                                    font.pixelSize: 11
                                    color: Theme.inkSoft
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.cursor = irow.index
                            onClicked: win.launch(irow.index)
                        }
                    }
                }

                Text {
                    visible: win.results.length === 0
                    text: "NOTHING BY THAT NAME."
                    font.family: Theme.display
                    font.weight: Theme.displayWeight
                    font.pixelSize: Theme.hasBangers ? 22 : 17
                    color: Theme.inkMuted
                }
            }
        }
    }
}
