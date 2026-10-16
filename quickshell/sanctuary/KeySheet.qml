import QtQuick
import "kit"

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
Popup {
    id: win

    name: "keys"
    open: Ui.keysOpen
    onDismissed: Ui.keysOpen = false
    cardWidth: sheet.implicitWidth
    qCloses: false
    onKeyPressed: event => {
        if (event.key === Qt.Key_Backspace)
            filter = filter.slice(0, -1);
        else if (event.text !== "" && event.text >= " "
                 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
            filter += event.text;
        event.accepted = true;
    }

    property string filter: ""
    onVisibleChanged: if (visible) filter = ""

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

    Panel {
        id: sheet
        width: implicitWidth
        fit: true
        pad: 18
        inset: 0
        spacing: 10
        headerHeight: 16
        ruled: true
        hintGap: 2
        title: "KEYS"
        hint: "type to filter · backspace · esc close"
        headerItems: FilterText { filter: win.filter }

        Row {
            spacing: 28

            Repeater {
                model: 3
                delegate: Column {
                    id: column
                    required property int index
                    spacing: 12

                    Repeater {
                        model: win.sectionsIn(column.index)
                        delegate: Column {
                            id: sec
                            required property var modelData
                            spacing: 3

                            Heading {
                                text: sec.modelData.name
                                lit: win.filter !== "" && win.anyHit(sec.modelData)
                            }
                            Repeater {
                                model: sec.modelData.rows
                                delegate: KeyLine {
                                    required property var modelData
                                    readonly property bool on: win.hit(sec.modelData, modelData)
                                    keys: modelData[0]
                                    text: modelData[1]
                                    dim: !on
                                    lit: on && win.filter !== ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
