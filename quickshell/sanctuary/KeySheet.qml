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
        width: sig.width
        height: sig.height
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

    }
}
