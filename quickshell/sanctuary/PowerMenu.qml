import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The power menu — Mod+Shift+Escape (scripts/sanctuary/power.sh open). Drawn in
// the current style; when Quickshell is down the same key opens the fzf menu.
//
// Same rules as the fzf one: no confirmation, no countdown — picking a row IS
// the decision. The safety margin is the order: `lock` is the top row and the
// cursor always opens on it, so a stray Enter locks rather than powers off.
// The actions themselves run in power.sh (`do VERB`), which toasts a failure.
//
//   j k ↑ ↓  move     1-5  pick directly     enter  pick     esc q  close
//   click a row to pick it; click outside to close
PanelWindow {
    id: win

    visible: Ui.powerOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // `verb` is what `power.sh do` takes. `danger` = ends the session: drawn
    // red when the cursor is on it, so the last look before Enter says so.
    readonly property var rows: [
        { verb: "lock",     name: "Lock",      desc: "back in with your password",       danger: false },
        { verb: "suspend",  name: "Suspend",   desc: "sleep, resume where you left off", danger: false },
        { verb: "logout",   name: "Log out",   desc: "quit niri",                        danger: true },
        { verb: "reboot",   name: "Reboot",    desc: "restart now",                      danger: true },
        { verb: "poweroff", name: "Shut down", desc: "power off now",                    danger: true }
    ]
    property int cursor: 0
    property string uptime: ""

    onVisibleChanged: {
        if (visible) {
            cursor = 0;
            uptimeFile.reload();
        }
    }

    // Signal's header readout. /proc/uptime: "seconds idle-seconds".
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: {
            const s = Math.floor(parseFloat(uptimeFile.text()));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            win.uptime = (d > 0 ? d + "D " : "") + h + "H " + Theme.pad(m, 2, "0") + "M";
        }
    }

    function choose(i) {
        Ui.powerOpen = false;
        Quickshell.execDetached([Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary/power.sh",
                                 "do", rows[i].verb]);
    }

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.powerOpen = false
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: 400
        height: Theme.signal ? sig.height : inkCard.height + 6
        focus: true

        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape || k === Qt.Key_Q)
                Ui.powerOpen = false;
            else if (k === Qt.Key_J || k === Qt.Key_Down || k === Qt.Key_Tab)
                win.cursor = (win.cursor + 1) % win.rows.length;
            else if (k === Qt.Key_K || k === Qt.Key_Up || k === Qt.Key_Backtab)
                win.cursor = (win.cursor + win.rows.length - 1) % win.rows.length;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_L)
                win.choose(win.cursor);
            else if (k >= Qt.Key_1 && k < Qt.Key_1 + win.rows.length)
                win.choose(k - Qt.Key_1);
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
        //   ┌ POWER ─────────────────────── UP 3H 12M ┐
        //   │▌1  LOCK       back in with your password │
        //   │ 2  SUSPEND    sleep, resume where you…   │
        //   │ …                                        │
        //   └ j k move · enter act · esc close ────────┘
        Rectangle {
            id: sig
            visible: Theme.signal
            width: parent.width
            height: sigCol.implicitHeight + 24
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
                y: 12
                width: parent.width - 2
                spacing: 2

                Item {
                    width: parent.width
                    height: 20
                    Text {
                        x: 14
                        text: "POWER"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigHot
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        text: win.uptime ? "UP " + win.uptime : ""
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        color: Theme.sigLabel
                    }
                }

                Repeater {
                    model: win.rows
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === win.cursor
                        readonly property color hot: modelData.danger ? Theme.sigAlarm : Theme.sigHot
                        width: sigCol.width
                        height: 30
                        color: sel ? Theme.sigCell : "transparent"

                        Rectangle {
                            width: 2
                            height: parent.height
                            color: row.hot
                            visible: row.sel
                        }
                        Row {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Text {
                                text: String(row.index + 1)
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: Theme.surface2
                            }
                            Text {
                                width: 90
                                text: row.modelData.name.toUpperCase()
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: row.sel ? row.hot : Theme.sigValue
                            }
                            Text {
                                text: row.modelData.desc
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: Theme.sigLabel
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.cursor = row.index
                            onClicked: win.choose(row.index)
                        }
                    }
                }

                Text {
                    x: 14
                    topPadding: 8
                    text: "j k move · enter act · esc close"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
            }
        }

        // ══ Ink / Paper ══════════════════════════════════════════════
        // The style picker's page, with one change: a row that ends the
        // session casts a red shadow when it is the selected one, not peach.
        Item {
            id: inkCard
            visible: Theme.ink
            width: parent.width - 6
            height: inkCol.implicitHeight + 36

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
                x: 18
                y: 16
                width: parent.width - 36
                spacing: 10

                Item {
                    width: parent.width
                    height: 34
                    InkHalftone {
                        anchors.fill: parent
                        from: 0.5
                        strength: 0.25
                        step: 6
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "POWER"
                        font.family: Theme.display
                        font.weight: Theme.displayWeight
                        font.pixelSize: Theme.hasBangers ? 30 : 24
                        color: Theme.inkLine
                    }
                }

                Repeater {
                    model: win.rows
                    delegate: Item {
                        id: irow
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === win.cursor
                        width: inkCol.width - 4
                        height: 40

                        Rectangle {
                            x: irow.sel ? 4 : 2
                            y: irow.sel ? 4 : 2
                            width: parent.width
                            height: parent.height
                            color: !irow.sel ? Theme.paperShade
                                 : irow.modelData.danger ? Theme.red : Theme.peach
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.paper
                            border.width: irow.sel ? Theme.inkStroke : 2
                            border.color: Theme.inkLine

                            Row {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12
                                Text {
                                    width: 96
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: irow.modelData.name.toUpperCase()
                                    font.family: Theme.sans
                                    font.weight: Font.Black
                                    font.pixelSize: 14
                                    color: Theme.inkLine
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: irow.modelData.desc
                                    font.family: Theme.sans
                                    font.weight: Font.Medium
                                    font.pixelSize: 11
                                    color: Theme.inkSoft
                                }
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(irow.index + 1)
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 10
                                color: Theme.inkMuted
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.cursor = irow.index
                            onClicked: win.choose(irow.index)
                        }
                    }
                }
            }
        }
    }
}
