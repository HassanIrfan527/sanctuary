import QtQuick
import Quickshell
import Quickshell.Wayland

// RIG — the recorders, Mod+U (or click the ◉ cell on the bar). One letter per
// action, so it is two keypresses and never a menu to walk (DESIGN-BRIEF §1).
// Rows change with what is running:
//
//   idle          S  SCREEN      drag a region · mic on, sys off
//                 M  MEETING     you + them, two files
//                 P  PRACTICE    mic only
//   screen on     S  STOP SCREEN 03:12          D  PAUSE / RESUME SCREEN
//   audio on      M  STOP AUDIO  41:05          P  PAUSE / RESUME AUDIO
//
//   letter  act     j k ↑ ↓  move     enter  act     esc q  close
PanelWindow {
    id: win

    visible: Ui.rigOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-rig"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // key: the letter · name/desc: the words · hot: "rec" red, "warn" yellow,
    // "" normal · act: what it does.
    readonly property var rows: {
        const r = [];
        if (!Rec.scrActive) {
            r.push({ key: "S", name: "SCREEN", desc: "drag a region · mic on, sys off", hot: "", act: "screen" });
        } else if (Rec.scrSaving) {
            r.push({ key: "S", name: "SAVING", desc: "joining the recording…", hot: "warn", act: "" });
        } else {
            r.push({ key: "S", name: "STOP SCREEN", desc: Rec.clock(Rec.scrMs) + " · saves to Videos/Recordings", hot: "rec", act: "scr-stop" });
            r.push({ key: "D", name: Rec.scrPaused ? "RESUME SCREEN" : "PAUSE SCREEN", desc: Rec.scrPaused ? "paused" : "Ctrl+Alt+Print", hot: Rec.scrPaused ? "warn" : "", act: "scr-pause" });
        }
        if (!Rec.audActive) {
            r.push({ key: "M", name: "MEETING", desc: "you + them, two files", hot: "", act: "meeting" });
            r.push({ key: "P", name: "PRACTICE", desc: "mic only", hot: "", act: "practice" });
        } else {
            r.push({ key: "M", name: "STOP AUDIO", desc: Rec.clock(Rec.audMs) + (Rec.audSolo ? " · practice" : " · meeting"), hot: "rec", act: "aud-stop" });
            r.push({ key: "P", name: Rec.audPaused ? "RESUME AUDIO" : "PAUSE AUDIO", desc: Rec.audPaused ? "paused" : "stop joins the parts", hot: Rec.audPaused ? "warn" : "", act: "aud-pause" });
        }
        return r;
    }
    property int cursor: 0

    onVisibleChanged: if (visible) cursor = 0

    function run(act) {
        if (act === "")
            return;
        Ui.rigOpen = false;
        if (act === "screen")
            Ui.captureOpen = true;
        else if (act === "scr-stop")
            Rec.screen(["stop"]);
        else if (act === "scr-pause")
            Rec.screen(["pause-toggle"]);
        else if (act === "meeting")
            Rec.audio(["start"]);
        else if (act === "practice")
            Rec.audio(["start", "--solo"]);
        else if (act === "aud-stop")
            Rec.audio(["stop"]);
        else if (act === "aud-pause")
            Rec.audio(["pause-toggle"]);
    }

    function hotColor(h) {
        return h === "rec" ? Theme.red : h === "warn" ? Theme.yellow : Theme.signal ? Theme.sigHot : Theme.peach;
    }

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.rigOpen = false
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: 400
        height: Theme.signal ? sig.height : inkCard.height + 6
        focus: true

        Keys.onPressed: event => {
            const k = event.key;
            const n = win.rows.length;
            if (k === Qt.Key_Escape || k === Qt.Key_Q)
                Ui.rigOpen = false;
            else if (k === Qt.Key_J || k === Qt.Key_Down || k === Qt.Key_Tab)
                win.cursor = (win.cursor + 1) % n;
            else if (k === Qt.Key_K || k === Qt.Key_Up || k === Qt.Key_Backtab)
                win.cursor = (win.cursor + n - 1) % n;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_L)
                win.run(win.rows[win.cursor].act);
            else {
                const letter = event.text.toUpperCase();
                const row = win.rows.find(r => r.key === letter);
                if (!row)
                    return;
                win.run(row.act);
            }
            event.accepted = true;
        }

        MouseArea {   // swallow clicks on the card
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        // ══ Signal ═══════════════════════════════════════════════════
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
                color: Rec.any ? Theme.sigAlarm : Theme.sigHot
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
                        text: "RIG"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigHot
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        text: Rec.any ? "● REC" : "STANDBY"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        color: Rec.any ? Theme.sigAlarm : Theme.sigLabel
                    }
                }

                Repeater {
                    model: win.rows
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === win.cursor
                        readonly property color hot: win.hotColor(modelData.hot)
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
                                text: row.modelData.key
                                font.family: Theme.mono
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: row.sel ? row.hot : Theme.surface2
                            }
                            Text {
                                width: 120
                                text: row.modelData.name
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: row.modelData.hot !== "" ? row.hot : row.sel ? row.hot : Theme.sigValue
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
                            onClicked: win.run(row.modelData.act)
                        }
                    }
                }

                Text {
                    x: 14
                    topPadding: 8
                    text: "letter act · j k move · esc close"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
            }
        }

        // ══ Ink / Paper ══════════════════════════════════════════════
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
                color: Rec.any ? Theme.red : Theme.teal
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
                        text: "RIG"
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
                            color: irow.modelData.hot !== "" ? win.hotColor(irow.modelData.hot)
                                 : irow.sel ? Theme.peach : Theme.paperShade
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
                                    width: 124
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: irow.modelData.name
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
                                text: irow.modelData.key
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 11
                                color: Theme.inkMuted
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.cursor = irow.index
                            onClicked: win.run(irow.modelData.act)
                        }
                    }
                }
            }
        }
    }
}
