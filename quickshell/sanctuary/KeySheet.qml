import QtQuick
import Quickshell
import Quickshell.Wayland

// KEYS — the keybind cheat sheet, Mod+/ (scripts/sanctuary/keys.sh). Replaces
// niri's unstyled hotkey overlay, which is now only the fallback when
// Quickshell is down. The words come from Keymap.qml (hand-written).
//
//   ┌ KEYS ──────────────────────────────────────────── > rec_ ┐
//   │ LAUNCH                AUDIO                 WINDOWS        │
//   │ SUPER RETURN terminal SUPER M  system mic   SUPER W close  │
//   │ …                     …                     …              │
//   └ type to filter · backspace · esc close ────────────────────┘
//
// Read-only. Typing narrows by dimming: rows that don't match go faint, the
// layout never moves, so your eye stays where the key was.
PanelWindow {
    id: win

    visible: Ui.keysOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-keys"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string filter: ""
    onVisibleChanged: if (visible) filter = ""

    readonly property int keyW: 150
    readonly property int descW: 176

    function sectionsIn(col) {
        return Keymap.sections.filter(s => s.col === col);
    }
    // A row matches if the filter is in its keys, its words or its section.
    function hit(section, row) {
        if (filter === "")
            return true;
        const f = filter.toLowerCase();
        return row[0].toLowerCase().indexOf(f) >= 0
            || row[1].toLowerCase().indexOf(f) >= 0
            || section.name.toLowerCase().indexOf(f) >= 0;
    }
    function anyHit(section) {
        return section.rows.some(r => hit(section, r));
    }

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.keysOpen = false
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: Theme.signal ? sig.width : inkCard.width + 6
        height: Theme.signal ? sig.height : inkCard.height + 6
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                Ui.keysOpen = false;
            else if (event.key === Qt.Key_Backspace)
                win.filter = win.filter.slice(0, -1);
            else if (event.text !== "" && event.text >= " "
                     && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
                win.filter += event.text;
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
            width: sigBody.implicitWidth + 2 * 18
            height: sigCol.implicitHeight + 24
            color: Theme.sigFill
            border.width: 1
            border.color: Theme.sigRule

            SignalTicks {
                anchors.fill: parent
                anchors.margins: -3
                color: Theme.sigHot
            }

            Column {
                id: sigCol
                x: 18
                y: 12
                width: parent.width - 36
                spacing: 10

                Item {
                    width: parent.width
                    height: 16
                    Text {
                        text: "KEYS"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigHot
                    }
                    Text {
                        anchors.right: parent.right
                        text: win.filter === "" ? "TYPE TO FILTER" : "> " + win.filter.toUpperCase() + "_"
                        font.family: Theme.mono
                        font.pixelSize: win.filter === "" ? 9 : 10
                        font.weight: win.filter === "" ? Font.Normal : Font.Bold
                        font.letterSpacing: 1.4
                        color: win.filter === "" ? Theme.sigLabel : Theme.sigHot
                    }
                }

                Rectangle {   // hairline under the header
                    width: parent.width
                    height: 1
                    color: Theme.sigRule
                }

                Row {
                    id: sigBody
                    spacing: 28

                    Repeater {
                        model: 3
                        delegate: Column {
                            id: sigColumn
                            required property int index
                            spacing: 12

                            Repeater {
                                model: win.sectionsIn(sigColumn.index)
                                delegate: Column {
                                    id: sec
                                    required property var modelData
                                    spacing: 3

                                    Text {
                                        bottomPadding: 2
                                        text: sec.modelData.name
                                        font.family: Theme.mono
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.6
                                        color: win.filter !== "" && win.anyHit(sec.modelData) ? Theme.sigHot : Theme.sigLabel
                                    }

                                    Repeater {
                                        model: sec.modelData.rows
                                        delegate: Row {
                                            id: krow
                                            required property var modelData
                                            readonly property bool on: win.hit(sec.modelData, modelData)
                                            readonly property bool lit: on && win.filter !== ""
                                            spacing: 12
                                            Text {
                                                width: win.keyW
                                                text: krow.modelData[0]
                                                font.family: Theme.mono
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                font.letterSpacing: 0.6
                                                color: !krow.on ? Theme.surface0 : krow.lit ? Theme.sigHot : Theme.sigValue
                                            }
                                            Text {
                                                width: win.descW
                                                elide: Text.ElideRight
                                                text: krow.modelData[1]
                                                font.family: Theme.mono
                                                font.pixelSize: 10
                                                color: krow.on ? Theme.subtext0 : Theme.surface0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    topPadding: 2
                    text: "type to filter · backspace · esc close"
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
            width: inkBody.implicitWidth + 2 * 22
            height: inkCol.implicitHeight + 36

            Rectangle {   // the shadow carries identity (§4)
                x: 6
                y: 6
                width: parent.width
                height: parent.height
                color: Theme.teal
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
                y: 16
                width: parent.width - 44
                spacing: 12

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
                        text: "KEYS"
                        font.family: Theme.display
                        font.weight: Theme.displayWeight
                        font.pixelSize: Theme.hasBangers ? 30 : 24
                        color: Theme.inkLine
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.filter === "" ? "type to filter" : "› " + win.filter
                        font.family: Theme.sans
                        font.weight: win.filter === "" ? Font.Medium : Font.Black
                        font.pixelSize: win.filter === "" ? 11 : 14
                        color: win.filter === "" ? Theme.inkMuted : Theme.inkLine
                    }
                }

                Row {
                    id: inkBody
                    spacing: 28

                    Repeater {
                        model: 3
                        delegate: Column {
                            id: inkColumn
                            required property int index
                            spacing: 14

                            Repeater {
                                model: win.sectionsIn(inkColumn.index)
                                delegate: Column {
                                    id: isec
                                    required property var modelData
                                    readonly property bool lit: win.filter !== "" && win.anyHit(modelData)
                                    spacing: 3

                                    Item {   // section name on a peach underline when it holds a match
                                        width: ihead.implicitWidth
                                        height: ihead.implicitHeight + 3
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: 4
                                            color: Theme.peach
                                            visible: isec.lit
                                        }
                                        Text {
                                            id: ihead
                                            text: isec.modelData.name
                                            font.family: Theme.sans
                                            font.weight: Font.Black
                                            font.pixelSize: 12
                                            font.letterSpacing: 0.8
                                            color: Theme.inkLine
                                        }
                                    }

                                    Repeater {
                                        model: isec.modelData.rows
                                        delegate: Row {
                                            id: irow
                                            required property var modelData
                                            readonly property bool on: win.hit(isec.modelData, modelData)
                                            spacing: 12
                                            opacity: on ? 1 : 0.25
                                            Text {
                                                width: win.keyW
                                                text: irow.modelData[0]
                                                font.family: Theme.mono
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: Theme.inkLine
                                            }
                                            Text {
                                                width: win.descW
                                                elide: Text.ElideRight
                                                text: irow.modelData[1]
                                                font.family: Theme.sans
                                                font.weight: Font.Medium
                                                font.pixelSize: 11
                                                color: Theme.inkSoft
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "type to filter · backspace · esc close"
                    font.family: Theme.sans
                    font.weight: Font.Medium
                    font.pixelSize: 10
                    color: Theme.inkMuted
                }
            }
        }
    }
}
