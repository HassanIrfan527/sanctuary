import QtQuick
import Quickshell
import Quickshell.Wayland

// COMMS — Discord voice without leaving your window. Mod+C, or click the VC
// cell on the bar. Same grammar as RIG: one letter per action, no SUPER.
//
//   COMMS                                        LIVE
//   #general · votel                              04
//   ▌harry · you                                   ●     green bar = speaking
//    ali                                         MUTE
//   M  MUTE      discord mic — not SUPER M
//   D  DEAFEN    hear no one
//   X  LEAVE     hang up
//   F  VESKTOP   switch to the window
//
// M here is DISCORD's mute (others see the red icon). SUPER M stays the
// system mic. Data: Comms.qml ← the SanctuaryComms Vencord plugin.
PanelWindow {
    id: win

    visible: Ui.commsOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-comms"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // The one-word state: what the header lamp and the bar cell say.
    readonly property string word: !Comms.linked ? "NO LINK"
        : !Comms.inCall ? "NOT IN VOICE"
        : Comms.selfDeaf ? "DEAF"
        : Comms.selfMute ? "MUTE" : "LIVE"
    readonly property bool live: word === "LIVE"

    readonly property var rows: {
        const r = [];
        if (Comms.inCall) {
            r.push({ key: "M", name: Comms.selfMute ? "UNMUTE" : "MUTE", desc: "discord mic — not SUPER M", act: "mute" });
            r.push({ key: "D", name: Comms.selfDeaf ? "UNDEAFEN" : "DEAFEN", desc: "hear no one", act: "deafen" });
            r.push({ key: "X", name: "LEAVE", desc: "hang up", act: "leave" });
        }
        r.push({ key: "F", name: "VESKTOP", desc: Comms.linked ? "switch to the window" : "open it", act: "focus" });
        return r;
    }
    property int cursor: 0

    onVisibleChanged: if (visible) cursor = 0

    function run(act) {
        Ui.commsOpen = false;
        if (act === "mute")
            Comms.mute();
        else if (act === "deafen")
            Comms.deafen();
        else if (act === "leave")
            Comms.leave();
        else if (act === "focus")
            Comms.focus();
    }

    function stateColor() {
        return live ? (Theme.signal ? Theme.sigHot : Theme.green)
             : (word === "MUTE" || word === "DEAF") ? Theme.red
             : Theme.signal ? Theme.sigLabel : Theme.inkMuted;
    }
    // A person's right-hand mark: speaking dot, or what they've switched off.
    function mark(m) {
        return m.deaf ? "DEAF" : m.mute ? "MUTE" : m.speaking ? "●" : "";
    }

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.commsOpen = false
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
                Ui.commsOpen = false;
            else if (k === Qt.Key_J || k === Qt.Key_Down || k === Qt.Key_Tab)
                win.cursor = (win.cursor + 1) % n;
            else if (k === Qt.Key_K || k === Qt.Key_Up || k === Qt.Key_Backtab)
                win.cursor = (win.cursor + n - 1) % n;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_L)
                win.run(win.rows[win.cursor].act);
            else {
                const row = win.rows.find(r => r.key === event.text.toUpperCase());
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
                color: win.word === "MUTE" || win.word === "DEAF" ? Theme.sigAlarm : Theme.sigHot
            }

            Column {
                id: sigCol
                x: 1
                y: 12
                width: parent.width - 2
                spacing: 2

                Item {   // COMMS ··· state word
                    width: parent.width
                    height: 18
                    Text {
                        x: 14
                        text: "COMMS"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigHot
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        text: win.word
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: win.stateColor()
                    }
                }

                Item {   // #channel · server ··· people count
                    visible: Comms.inCall
                    width: parent.width
                    height: 22
                    Text {
                        x: 14
                        width: parent.width - 80
                        elide: Text.ElideRight
                        text: "#" + Comms.channel + (Comms.guild !== "" ? "  ·  " + Comms.guild : "")
                        font.family: Theme.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.sigValue
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        text: Theme.pad(Comms.count, 2, "0")
                        font.family: Theme.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.sigValue
                    }
                }

                Text {   // why there's nothing
                    visible: !Comms.inCall
                    x: 14
                    bottomPadding: 6
                    text: Comms.linked ? "join a voice channel in Vesktop"
                                       : "vesktop closed, or SanctuaryComms off"
                    font.family: Theme.mono
                    font.pixelSize: 10
                    color: Theme.sigLabel
                }

                Repeater {   // the room
                    model: Comms.inCall ? Comms.members : []
                    delegate: Item {
                        id: who
                        required property var modelData
                        width: sigCol.width
                        height: 22
                        Rectangle {
                            width: 2
                            height: parent.height
                            color: Theme.sigHot
                            visible: who.modelData.speaking
                        }
                        Text {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 90
                            elide: Text.ElideRight
                            text: who.modelData.name + (who.modelData.me ? "  · you" : "")
                            font.family: Theme.mono
                            font.pixelSize: 11
                            color: who.modelData.speaking ? Theme.sigHot : Theme.sigValue
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: win.mark(who.modelData)
                            font.family: Theme.mono
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                            color: who.modelData.mute || who.modelData.deaf ? Theme.sigAlarm : Theme.sigHot
                        }
                    }
                }

                Rectangle {
                    x: 14
                    width: parent.width - 28
                    height: 1
                    color: Theme.sigRule
                }
                Item { width: 1; height: 4 }

                Repeater {   // the actions
                    model: win.rows
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
                            spacing: 12
                            Text {
                                text: row.modelData.key
                                font.family: Theme.mono
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: row.sel ? Theme.sigHot : Theme.surface2
                            }
                            Text {
                                width: 100
                                text: row.modelData.name
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: row.sel ? Theme.sigHot : Theme.sigValue
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

            Rectangle {   // shadow = state: green live, red muted, grey otherwise
                x: 6
                y: 6
                width: parent.width
                height: parent.height
                color: win.live ? Theme.green
                     : (win.word === "MUTE" || win.word === "DEAF") ? Theme.red : Theme.surface1
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
                        text: "COMMS"
                        font.family: Theme.display
                        font.weight: Theme.displayWeight
                        font.pixelSize: Theme.hasBangers ? 30 : 24
                        color: Theme.inkLine
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.word
                        font.family: Theme.sans
                        font.weight: Font.Black
                        font.pixelSize: 12
                        color: win.live ? Theme.inkLine : win.stateColor()
                    }
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Comms.inCall
                          ? "#" + Comms.channel + (Comms.guild !== "" ? "  ·  " + Comms.guild : "") + "  ·  " + Comms.count
                          : Comms.linked ? "join a voice channel in Vesktop" : "vesktop closed, or SanctuaryComms off"
                    font.family: Theme.sans
                    font.weight: Comms.inCall ? Font.Black : Font.Medium
                    font.pixelSize: Comms.inCall ? 13 : 11
                    color: Comms.inCall ? Theme.inkLine : Theme.inkSoft
                }

                Column {   // the room
                    visible: Comms.inCall
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: Comms.inCall ? Comms.members : []
                        delegate: Item {
                            id: iwho
                            required property var modelData
                            width: parent.width
                            height: 22
                            Rectangle {   // speaking: a peach highlighter stroke under the name
                                y: parent.height - 7
                                width: iname.implicitWidth + 8
                                height: 5
                                x: 4
                                color: Theme.peach
                                visible: iwho.modelData.speaking
                            }
                            Text {
                                id: iname
                                x: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, parent.width - 80)
                                elide: Text.ElideRight
                                text: iwho.modelData.name + (iwho.modelData.me ? "  · you" : "")
                                font.family: Theme.sans
                                font.weight: iwho.modelData.speaking ? Font.Black : Font.Bold
                                font.pixelSize: 12
                                color: Theme.inkLine
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: iwho.modelData.speaking && !iwho.modelData.mute && !iwho.modelData.deaf ? "" : win.mark(iwho.modelData)
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 10
                                color: Theme.red
                            }
                        }
                    }
                }

                Repeater {   // the actions
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
                            color: irow.sel ? Theme.peach : Theme.paperShade
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
                                    width: 100
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
