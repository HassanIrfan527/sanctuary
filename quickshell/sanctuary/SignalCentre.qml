import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Signal's notification centre: the message log. One row per notification —
// time, source, summary, then the body dimmed underneath. Key hints in the
// footer are also the buttons.
//
//   Mod+Shift+D  open / close      c  clear all     d  DND     esc  close
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

    Rectangle {
        id: frame
        width: 440
        height: parent.height - 6 - 8
        y: 6
        color: Theme.sigFill
        border.width: 1
        border.color: Theme.sigRule
        focus: true

        MouseArea {   // swallow clicks on the panel's empty parts
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        // Only the slide offset animates — never x itself. The window's width is
        // 0 for a moment when it's shown, then becomes the screen width; if x
        // were animated, the panel would glide across from the left edge.
        property real slide: Ui.centreOpen ? 0 : 32
        x: parent.width - width - 8 + slide
        opacity: Ui.centreOpen ? 1 : 0
        Behavior on slide { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

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

        SignalTicks {
            anchors.fill: parent
            anchors.margins: -3
        }

        // ── header ───────────────────────────────────────────────────
        Item {
            id: head
            width: parent.width
            height: 40
            Text {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "LOG"
                font.family: Theme.mono
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: Theme.sigHot
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.pad(Notifs.count, 2, "0") + " ENTRIES  ·  DND "
                      + (Notifs.dnd ? "ON" : "OFF")
                font.family: Theme.mono
                font.pixelSize: 9
                font.letterSpacing: 1.2
                color: Notifs.dnd ? Theme.sigWarn : Theme.sigLabel
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.sigRule
            }
        }

        // ── rows ─────────────────────────────────────────────────────
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

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var n: modelData
                readonly property bool critical: n?.urgency === NotificationUrgency.Critical
                width: list.width
                height: rcol.implicitHeight + 14
                color: area.containsMouse ? Theme.sigCell : "transparent"

                Rectangle {
                    x: 0
                    width: 2
                    height: parent.height
                    color: row.critical ? Theme.sigAlarm : Theme.sigHot
                    visible: area.containsMouse || row.critical
                }

                Column {
                    id: rcol
                    x: 14
                    y: 7
                    width: parent.width - 28
                    spacing: 2

                    Row {
                        spacing: 10
                        Text {
                            text: Qt.formatDateTime(Notifs.meta(row.n).time, "hh:mm")
                            font.family: Theme.mono
                            font.pixelSize: 10
                            color: Theme.sigLabel
                        }
                        Text {
                            width: 90
                            elide: Text.ElideRight
                            text: ((row.n?.appName ?? "") || "—").toLowerCase()
                            font.family: Theme.mono
                            font.pixelSize: 10
                            color: row.critical ? Theme.sigAlarm : Theme.sigHot
                        }
                        Text {
                            width: rcol.width - 150
                            elide: Text.ElideRight
                            text: (row.n?.summary ?? "")
                            font.family: Theme.mono
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.sigValue
                        }
                    }
                    Text {
                        x: 140
                        width: rcol.width - 140
                        visible: text !== ""
                        text: (row.n?.body ?? "")
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.family: Theme.mono
                        font.pixelSize: 10
                        color: Theme.subtext0
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    x: 14
                    width: parent.width - 28
                    height: 1
                    color: Theme.sigRule
                    opacity: 0.6
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            row.n.dismiss();
                        else
                            Notifs.activate(row.n);
                    }
                }
            }
        }

        // ── footer: key hints that are also buttons ──────────────────
        Item {
            id: foot
            anchors.bottom: parent.bottom
            width: parent.width
            height: 36
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.sigRule
            }
            Row {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18

                Repeater {
                    model: [
                        { key: "c", label: "clear all", act: () => Notifs.clearAll() },
                        { key: "d", label: Notifs.dnd ? "dnd on" : "dnd off", act: () => Notifs.dnd = !Notifs.dnd },
                        { key: "esc", label: "close", act: () => Ui.centreOpen = false }
                    ]
                    delegate: Item {
                        id: hint
                        required property var modelData
                        width: hintRow.implicitWidth
                        height: hintRow.implicitHeight
                        Row {
                            id: hintRow
                            spacing: 6
                            Text {
                                text: "[" + hint.modelData.key + "]"
                                font.family: Theme.mono
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.sigHot
                            }
                            Text {
                                text: hint.modelData.label
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: hintArea.containsMouse ? Theme.sigValue : Theme.sigLabel
                            }
                        }
                        MouseArea {
                            id: hintArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hint.modelData.act()
                        }
                    }
                }
            }
        }
    }
}
