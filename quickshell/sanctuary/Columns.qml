import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// The column strip: what Mod+1..9 points at on this workspace, left to right.
// niri scrolls sideways forever, so past three columns you lose track of which
// number is which window — this is the map. It is only ever on screen when
// asked for: Mod+Grave (the key left of 1, scripts/sanctuary/columns.sh) opens
// it with the keyboard, current column lit:
//
//   1-9  jump to that column     h l ← →  move     enter space  go
//   esc q `  close               click a cell = go
//
// It closes itself after 4s of no input.
//
// No automatic flash on column / workspace switches: tried on 2026-10-08 and
// dropped the same day, Harry found it distracting.
PanelWindow {
    id: win

    readonly property bool peek: Ui.columnsOpen

    visible: peek
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-columns"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: peek ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var ws: Niri.focusedWorkspace
    readonly property var cols: ws ? Niri.columnsOf(ws.id) : []
    // niri's column number (1-based, what Mod+N takes) of the focused window.
    readonly property int focusedCol: {
        const f = Niri.focusedWindow;
        if (!f || !ws || f.workspace_id !== ws.id || !f.layout || !f.layout.pos_in_scrolling_layout)
            return -1;
        return f.layout.pos_in_scrolling_layout[0];
    }
    property int cursor: 0   // index into cols, peek only

    // A column of several windows (stacked or tabbed) is shown by the one you
    // were last in, or its top one.
    function face(c) {
        return c.windows.find(w => w.id === Niri.focusedId) || c.windows[0];
    }
    function entry(w) {
        return DesktopEntries.heuristicLookup(w.app_id || "");
    }
    function appName(w) {
        const e = entry(w);
        return e ? e.name : (w.app_id || "?");
    }
    function icon(w) {
        const e = entry(w);
        return Quickshell.iconPath(e ? e.icon : (w.app_id || ""), true)
            || Quickshell.iconPath("application-x-executable", true);
    }
    // Only 1-9 have a bind; a 10th column still shows, numberless.
    function num(c) {
        return c.index <= 9 ? String(c.index) : "·";
    }

    function go(c) {
        if (!c)
            return;
        Niri.focusColumn(c.index);
        Ui.columnsOpen = false;
    }

    onPeekChanged: {
        if (peek) {
            const i = cols.findIndex(c => c.index === focusedCol);
            cursor = Math.max(0, i);
            idle.restart();
            if (Theme.ink)
                slam.restart();
        }
    }

    Timer {
        id: idle
        interval: 4000
        onTriggered: Ui.columnsOpen = false
    }

    function key(event) {
        idle.restart();
        const k = event.key;
        const n = cols.length;
        if (k === Qt.Key_Escape || k === Qt.Key_Q || k === Qt.Key_QuoteLeft)
            Ui.columnsOpen = false;
        else if (k >= Qt.Key_1 && k <= Qt.Key_9)
            go(cols.find(c => c.index === k - Qt.Key_0));
        else if (n === 0)
            return;
        else if (k === Qt.Key_H || k === Qt.Key_Left)
            cursor = (cursor + n - 1) % n;
        else if (k === Qt.Key_L || k === Qt.Key_Right)
            cursor = (cursor + 1) % n;
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            go(cols[cursor]);
        else
            return;
        event.accepted = true;
    }

    MouseArea {   // scrim: click outside = close
        id: scrim
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        enabled: win.peek
        onClicked: Ui.columnsOpen = false
    }

    Item {
        id: body
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 56
        width: Theme.signal ? sig.width : inkCol.width
        height: Theme.signal ? sig.height : inkCol.height
        opacity: win.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

        focus: true
        Keys.onPressed: event => win.key(event)

        MouseArea {   // swallow clicks between the cells
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            enabled: win.peek
        }

        // ══ Signal: a channel strip ═══════════════════════════════════
        Rectangle {
            id: sig
            visible: Theme.signal
            // One or two columns make a strip narrower than the peek's hint line.
            width: Math.max(sigRow.implicitWidth, win.peek ? sigHint.implicitWidth + 24 : 0) + 2
            height: sigCol.implicitHeight + (win.peek ? 20 : 2)
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
                y: win.peek ? 10 : 1
                width: sig.width - 2
                spacing: 6

                Item {
                    visible: win.peek
                    width: parent.width
                    height: 12
                    Text {
                        x: 12
                        text: "COLUMNS"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigHot
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        text: "WS " + (win.ws ? win.ws.idx : "?") + " · " + win.cols.length + " COL"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        color: Theme.sigLabel
                    }
                }

                Row {
                    id: sigRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: Theme.signal ? win.cols : []
                        delegate: Item {
                            id: cell
                            required property var modelData
                            required property int index
                            readonly property var w: win.face(modelData)
                            readonly property bool lit: modelData.index === win.focusedCol
                            readonly property bool sel: win.peek && index === win.cursor
                            width: 96
                            height: win.peek ? 84 : 70

                            Rectangle {
                                anchors.fill: parent
                                color: cell.lit ? Theme.sigCell : "transparent"
                            }
                            Rectangle {
                                width: parent.width
                                height: 2
                                color: Theme.sigHot
                                visible: cell.lit
                            }
                            Rectangle {   // the rule between channels
                                anchors.right: parent.right
                                width: 1
                                height: parent.height
                                color: Theme.sigRule
                                visible: cell.index < win.cols.length - 1
                            }
                            Text {
                                x: 8
                                y: 6
                                text: win.num(cell.modelData)
                                font.family: Theme.mono
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: cell.lit ? Theme.sigHot : Theme.sigLabel
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                y: 7
                                visible: cell.modelData.windows.length > 1
                                text: "×" + cell.modelData.windows.length
                                font.family: Theme.mono
                                font.pixelSize: 9
                                color: Theme.sigLabel
                            }
                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 14
                                implicitSize: 28
                                source: win.icon(cell.w)
                                opacity: cell.lit || cell.sel ? 1 : 0.7
                            }
                            Column {
                                y: 48
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 12
                                spacing: 2
                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: win.appName(cell.w)
                                    font.family: Theme.mono
                                    font.pixelSize: 10
                                    font.weight: cell.lit || cell.sel ? Font.Bold : Font.Normal
                                    color: cell.sel ? Theme.sigHot : cell.lit ? Theme.sigValue : Theme.sigLabel
                                }
                                Text {
                                    visible: win.peek
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: cell.w.title || ""
                                    font.family: Theme.mono
                                    font.pixelSize: 8
                                    color: Theme.surface2
                                }
                            }
                            Rectangle {   // the peek cursor
                                anchors.fill: parent
                                anchors.margins: 2
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.sigHot
                                visible: cell.sel
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: win.peek
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: { win.cursor = cell.index; idle.restart(); }
                                onClicked: win.go(cell.modelData)
                            }
                        }
                    }
                }

                Text {
                    id: sigHint
                    visible: win.peek
                    x: 12
                    text: win.cols.length ? "1-9 JUMP · H L MOVE · ENTER GO · ESC CLOSE" : "NO COLUMNS ON THIS WORKSPACE"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    color: Theme.sigLabel
                }
            }
        }

        // ══ Ink / Paper: a row of panels, a comic strip ═══════════════
        Column {
            id: inkCol
            visible: Theme.ink
            spacing: 10

            Row {
                id: inkRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                transformOrigin: Item.Bottom

                Repeater {
                    model: Theme.ink ? win.cols : []
                    delegate: InkPanel {
                        id: icell
                        required property var modelData
                        required property int index
                        readonly property var w: win.face(modelData)
                        readonly property bool lit: modelData.index === win.focusedCol
                        readonly property bool sel: win.peek && index === win.cursor
                        accent: lit ? Theme.peach : sel ? Theme.lavender : Theme.surface1
                        hot: lit || sel
                        interactive: win.peek
                        padX: 8
                        implicitHeight: 66
                        onClicked: win.go(modelData)

                        Item {
                            width: 76
                            height: 54
                            Text {
                                text: win.num(icell.modelData)
                                font.family: Theme.display
                                font.weight: Theme.displayWeight
                                font.pixelSize: Theme.hasBangers ? 24 : 18
                                color: Theme.inkLine
                            }
                            Text {
                                anchors.right: parent.right
                                y: 2
                                visible: icell.modelData.windows.length > 1
                                text: "×" + icell.modelData.windows.length
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 10
                                color: Theme.inkSoft
                            }
                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 4
                                implicitSize: 28
                                source: win.icon(icell.w)
                            }
                            Text {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: win.appName(icell.w).toUpperCase()
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 10
                                color: icell.lit || icell.sel ? Theme.inkLine : Theme.inkSoft
                            }
                        }
                        HoverHandler {
                            enabled: win.peek
                            onHoveredChanged: if (hovered) { win.cursor = icell.index; idle.restart(); }
                        }
                    }
                }
            }

            InkPanel {
                visible: win.peek
                anchors.horizontalCenter: parent.horizontalCenter
                accent: Theme.surface1
                implicitHeight: 26
                padX: 10
                Text {
                    text: win.cols.length ? "1-9 JUMP · H L MOVE · ENTER GO · ESC CLOSE" : "NO COLUMNS HERE!"
                    font.family: Theme.sans
                    font.weight: Font.Bold
                    font.pixelSize: 10
                    color: Theme.inkMuted
                }
            }
        }

        NumberAnimation {
            id: slam
            target: inkRow
            property: "scale"
            from: 1.08
            to: 1
            duration: Theme.quick
            easing.type: Easing.OutCubic
        }
    }
}
