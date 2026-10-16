import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "kit"

// The notification centre: the message log. One row per notification —
// time, source, summary, then the body dimmed underneath. Key hints in the
// footer are also the buttons.
//
//   Mod+Shift+D  open / close      c  clear all     d  DND     esc q  close
//   click a row: its default action · right click: dismiss it
//   click anywhere outside the panel: close
//
// The window spans the whole screen (below the bar — Normal exclusion keeps the
// bar clickable) and is see-through; the panel sits at its right edge. That way
// a click outside the panel lands on our scrim instead of the app underneath.
PanelWindow {
    id: win

    visible: Ui.centreOpen
    color: "transparent"
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    WlrLayershell.namespace: "sanctuary-centre"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.centreOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.centreOpen = false
    }

    SidePanel {
        id: frame
        open: Ui.centreOpen
        height: parent.height - 6 - 8
        y: 6
        focus: true

        Keys.onEscapePressed: Ui.centreOpen = false
        Keys.onPressed: event => {
            if (event.text === "c") {
                Notifs.clearAll();
                event.accepted = true;
            } else if (event.text === "d") {
                Notifs.dnd = !Notifs.dnd;
                event.accepted = true;
            } else if (event.text === "q") {
                Ui.centreOpen = false;
                event.accepted = true;
            }
        }

        SideHeader {
            id: head
            title: "LOG"
            detail: Theme.pad(Notifs.count, 2, "0") + " ENTRIES  ·  DND " + (Notifs.dnd ? "ON" : "OFF")
            detailTone: Notifs.dnd ? "warn" : ""
        }

        ListView {
            id: list
            anchors {
                top: head.bottom
                left: parent.left
                right: parent.right
                bottom: foot.top
                topMargin: 4
                bottomMargin: 4
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel { values: Notifs.history.slice().reverse() }

            delegate: LogRow {
                required property var modelData
                readonly property var n: modelData
                width: list.width
                time: Qt.formatDateTime(Notifs.meta(n).time, "hh:mm")
                app: ((n?.appName ?? "") || "—").toLowerCase()
                summary: n?.summary ?? ""
                body: n?.body ?? ""
                critical: n?.urgency === NotificationUrgency.Critical
                onClicked: Notifs.activate(n)
                onRightClicked: n.dismiss()
            }
        }

        KeyHints {
            id: foot
            anchors.bottom: parent.bottom
            hints: [
                { key: "c", label: "clear all", act: () => Notifs.clearAll() },
                { key: "d", label: Notifs.dnd ? "dnd on" : "dnd off", act: () => Notifs.dnd = !Notifs.dnd },
                { key: "esc", label: "close", act: () => Ui.centreOpen = false }
            ]
        }
    }
}
