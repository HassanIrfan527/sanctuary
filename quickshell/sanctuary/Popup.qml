import QtQuick
import Quickshell
import Quickshell.Wayland
import "kit"

// The shape every menu shares, drawn by nobody: a full-screen see-through
// window over everything, a card in the middle, click outside = close,
// the keyboard while it is open, and list keys for menus that are lists.
//
//   Popup {
//       name: "power"                 // layer-shell namespace: sanctuary-power
//       open: Ui.powerOpen
//       onDismissed: Ui.powerOpen = false
//       count: rows.length            // list keys on: j k ↑ ↓ · 1-9 · enter l
//       onChosen: i => …
//       Panel { … }                   // the card (a kit part)
//   }
//
// Esc (and q, unless qCloses is off) dismisses. Keys it doesn't use arrive in keyPressed(event):
// set event.accepted = true there when you use one.
PanelWindow {
    id: pop

    required property string name
    property bool open: false
    property real cardWidth: 400
    property int count: 0            // list length; 0 = no list keys
    property int cursor: 0
    property bool tabMoves: false    // Tab / Shift+Tab move the cursor too
    property bool numberKeys: true   // 1-9 pick a row directly
    property bool qCloses: true      // false where q is typed (a filter field)
    property bool clickAway: true    // click outside = dismiss
    property bool dim: false         // darken what's behind (a prompt that must be answered)
    property bool centred: true      // false: the card sits at cardX, cardY (hung under a bar cell)
    property real cardX: 0
    property real cardY: 0
    readonly property real cardHeight: card.height
    default property alias content: holder.data

    signal dismissed()
    signal chosen(int index)
    signal keyPressed(var event)

    visible: open
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-" + name
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Scrim {
        anchors.fill: parent
        dim: pop.dim
    }
    MouseArea {   // click outside = close (or, with clickAway off, swallow it)
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: if (pop.clickAway) pop.dismissed()
    }

    Item {
        id: card
        anchors.centerIn: pop.centred ? parent : undefined
        x: pop.centred ? 0 : pop.cardX
        y: pop.centred ? 0 : pop.cardY
        width: pop.cardWidth
        height: holder.childrenRect.height
        focus: true

        Keys.onPressed: event => {
            const k = event.key, n = pop.count;
            if (k === Qt.Key_Escape || (pop.qCloses && k === Qt.Key_Q))
                pop.dismissed();
            else if (n > 0 && (k === Qt.Key_J || k === Qt.Key_Down || (pop.tabMoves && k === Qt.Key_Tab)))
                pop.cursor = (pop.cursor + 1) % n;
            else if (n > 0 && (k === Qt.Key_K || k === Qt.Key_Up || (pop.tabMoves && k === Qt.Key_Backtab)))
                pop.cursor = (pop.cursor + n - 1) % n;
            else if (n > 0 && (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_L))
                pop.chosen(pop.cursor);
            else if (n > 0 && pop.numberKeys && k >= Qt.Key_1 && k < Qt.Key_1 + Math.min(9, n))
                pop.chosen(k - Qt.Key_1);
            else {
                pop.keyPressed(event);
                return;
            }
            event.accepted = true;
        }

        MouseArea {   // swallow clicks on the card
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Item {
            id: holder
            width: parent.width
        }
    }
}
