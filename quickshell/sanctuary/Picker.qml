import QtQuick
import Quickshell
import Quickshell.Wayland

// The style picker — Mod+Shift+T. Drawn by Quickshell itself, in the style it
// is currently wearing. Picking restarts Quickshell in the new style (via
// scripts/sanctuary/shell.sh set), which also remembers it across reboots.
//
// It changes the bar, toasts and centre only. niri's layout is fixed
// (niri/layout.kdl) — nothing rewrites niri config.
//
//   j k ↑ ↓  move     1 2 3  pick directly     enter  pick     esc q  close
//   click a row to pick it; click outside to close
PanelWindow {
    id: win

    visible: Ui.pickerOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Order = the picker's rows. `word` is what shell.sh set takes.
    readonly property var styles: [
        { word: "signal", name: "Signal", desc: "instrument strip · live traces" },
        { word: "ink",    name: "Ink",    desc: "dark manga panels · bubbles" },
        { word: "paper",  name: "Paper",  desc: "light manga panels · bubbles" }
    ]
    readonly property int current: Math.max(0, styles.findIndex(s => s.word === Theme.word))
    property int cursor: current

    onVisibleChanged: if (visible) cursor = current

    function choose(i) {
        Ui.pickerOpen = false;
        if (i === current)
            return;
        Quickshell.execDetached([Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary/shell.sh",
                                 "set", styles[i].word]);
    }

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.pickerOpen = false
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: 420
        height: Theme.signal ? sig.height : inkCard.height + 6
        focus: true

        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape || k === Qt.Key_Q)
                Ui.pickerOpen = false;
            else if (k === Qt.Key_J || k === Qt.Key_Down)
                win.cursor = (win.cursor + 1) % win.styles.length;
            else if (k === Qt.Key_K || k === Qt.Key_Up)
                win.cursor = (win.cursor + win.styles.length - 1) % win.styles.length;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_L)
                win.choose(win.cursor);
            else if (k >= Qt.Key_1 && k < Qt.Key_1 + win.styles.length)
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

                Text {
                    x: 14
                    bottomPadding: 8
                    text: "STYLE"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    color: Theme.sigHot
                }

                Repeater {
                    model: win.styles
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool here: index === win.current
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
                            spacing: 12
                            Text {
                                text: String(row.index + 1)
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: Theme.surface2
                            }
                            Text {
                                width: 70
                                text: row.modelData.name
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: row.here ? Theme.sigHot : Theme.sigValue
                            }
                            Text {
                                text: row.modelData.desc
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: Theme.sigLabel
                            }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.here ? "● LIVE" : ""
                            font.family: Theme.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                            color: Theme.sigHot
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
                    text: "j k move · enter pick · esc close"
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

                Text {
                    text: "STYLE"
                    font.family: Theme.display
                    font.weight: Theme.displayWeight
                    font.pixelSize: Theme.hasBangers ? 30 : 24
                    color: Theme.inkLine
                }

                Repeater {
                    model: win.styles
                    delegate: Item {
                        id: irow
                        required property var modelData
                        required property int index
                        readonly property bool here: index === win.current
                        readonly property bool sel: index === win.cursor
                        width: inkCol.width - 4
                        height: 40

                        Rectangle {
                            x: irow.sel ? 4 : 2
                            y: irow.sel ? 4 : 2
                            width: parent.width
                            height: parent.height
                            color: irow.sel ? Theme.peach : Theme.paperShade
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: irow.here ? Theme.inkLine : Theme.paper
                            border.width: irow.sel ? Theme.inkStroke : 2
                            border.color: Theme.inkLine

                            Row {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: irow.modelData.name.toUpperCase()
                                    font.family: Theme.sans
                                    font.weight: Font.Black
                                    font.pixelSize: 14
                                    color: irow.here ? Theme.paper : Theme.inkLine
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: irow.modelData.desc
                                    font.family: Theme.sans
                                    font.weight: Font.Medium
                                    font.pixelSize: 11
                                    color: irow.here ? Theme.paperShade : Theme.inkSoft
                                }
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: irow.here ? "NOW" : String(irow.index + 1)
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 10
                                color: irow.here ? Theme.paper : Theme.inkMuted
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
