import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Ink's notification centre: one tall panel on the right, a screentoned
// masthead, each notification a small panel of its own. Built to be CLEARED,
// not browsed (§1 — Harry opens the centre to empty it).
//
//   Mod+Shift+D  open / close      c  clear all     d  DND     esc  close
//   click an entry: its default action · right click: dismiss it
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
    // Grab the keyboard while open, so esc / c / d work without a click first.
    WlrLayershell.keyboardFocus: Ui.centreOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.centreOpen = false
    }

    Item {
        id: frame
        width: 420 - 6              // the 6 is room for the hard shadow
        height: parent.height - 6 - 12 - 6
        y: 6
        focus: true

        MouseArea {   // swallow clicks on the panel's empty parts
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

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

        // Slide in from the right, ease-out.
        // Only the slide offset animates — never x itself. The window's width is
        // 0 for a moment when it's shown, then becomes the screen width; if x
        // were animated, the panel would glide across from the left edge.
        property real slide: Ui.centreOpen ? 0 : 40
        x: parent.width - 420 - 12 + slide
        opacity: Ui.centreOpen ? 1 : 0
        Behavior on slide { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

        Rectangle {   // hard shadow
            x: 6
            y: 6
            width: parent.width
            height: parent.height
            color: Theme.mauve
        }

        Rectangle {
            id: page
            anchors.fill: parent
            color: Theme.paper
            border.width: Theme.inkStroke
            border.color: Theme.inkLine

            // ── masthead ─────────────────────────────────────────────
            Rectangle {
                id: mast
                x: Theme.inkStroke
                y: Theme.inkStroke
                width: parent.width - Theme.inkStroke * 2
                height: 64
                color: Theme.paper

                InkHalftone {
                    anchors.fill: parent
                    from: 0.25
                    strength: 0.28
                    step: 6
                }
                Row {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "INBOX"
                        font.family: Theme.display
                        font.weight: Theme.displayWeight
                        font.pixelSize: Theme.hasBangers ? 38 : 30
                        color: Theme.inkLine
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: count.implicitWidth + 14
                        height: 26
                        color: Theme.inkLine
                        Text {
                            id: count
                            anchors.centerIn: parent
                            text: String(Notifs.count)
                            font.family: Theme.sans
                            font.weight: Font.Black
                            font.pixelSize: 14
                            color: Theme.paper
                        }
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Theme.inkStroke
                    color: Theme.inkLine
                }
            }

            // ── the list ─────────────────────────────────────────────
            ListView {
                id: list
                anchors {
                    top: mast.bottom
                    left: parent.left
                    right: parent.right
                    bottom: foot.top
                    margins: 14
                }
                clip: true
                spacing: 12
                boundsBehavior: Flickable.StopAtBounds
                // Newest first. ScriptModel diffs, so a new arrival inserts one
                // row instead of rebuilding the list.
                model: ScriptModel { values: Notifs.history.slice().reverse() }

                delegate: Item {
                    id: entry
                    required property var modelData
                    readonly property var n: modelData
                    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
                    width: list.width - 6
                    height: col.implicitHeight + 20 + 4

                    Rectangle {
                        x: 4
                        y: 4
                        width: parent.width - 4
                        height: parent.height - 4
                        color: entry.critical ? Theme.red : Theme.paperShade
                    }
                    Rectangle {
                        width: parent.width - 4
                        height: parent.height - 4
                        color: area.containsMouse ? Theme.paperHover : Theme.paper
                        border.width: 2
                        border.color: Theme.inkLine

                        Column {
                            id: col
                            x: 12
                            y: 10
                            width: parent.width - 24
                            spacing: 3

                            Row {
                                spacing: 8
                                Rectangle {
                                    width: app.implicitWidth + 10
                                    height: app.implicitHeight + 2
                                    color: Theme.inkLine
                                    visible: app.text !== ""
                                    Text {
                                        id: app
                                        anchors.centerIn: parent
                                        text: ((entry.n?.appName ?? "") || "").toUpperCase()
                                        font.family: Theme.sans
                                        font.weight: Font.Black
                                        font.pixelSize: 8
                                        font.letterSpacing: 1
                                        color: Theme.paper
                                    }
                                }
                                Text {
                                    text: Notifs.stamp(Notifs.meta(entry.n).time)
                                    font.family: Theme.sans
                                    font.weight: Font.Bold
                                    font.pixelSize: 9
                                    color: Theme.inkMuted
                                }
                            }
                            Text {
                                width: parent.width
                                text: (entry.n?.summary ?? "")
                                elide: Text.ElideRight
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 13
                                color: Theme.inkLine
                            }
                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: (entry.n?.body ?? "")
                                textFormat: Text.StyledText
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.family: Theme.sans
                                font.pixelSize: 11
                                color: Theme.inkSoft
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton)
                                    entry.n.dismiss();
                                else
                                    Notifs.activate(entry.n);
                            }
                        }
                    }
                }
            }

            // ── footer: the two things the centre is for ─────────────
            Row {
                id: foot
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 14
                }
                height: 34
                spacing: 12

                Rectangle {
                    width: (foot.width - foot.spacing) * 0.62
                    height: parent.height
                    color: clearArea.pressed ? Theme.inkSoft : Theme.inkLine
                    Text {
                        anchors.centerIn: parent
                        text: "CLEAR ALL  ·  C"
                        font.family: Theme.sans
                        font.weight: Font.Black
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        color: Theme.paper
                    }
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }
                Rectangle {
                    width: (foot.width - foot.spacing) * 0.38
                    height: parent.height
                    color: Notifs.dnd ? Theme.inkLine : Theme.paper
                    border.width: 2
                    border.color: Theme.inkLine
                    Text {
                        anchors.centerIn: parent
                        text: Notifs.dnd ? "DND ON · D" : "DND OFF · D"
                        font.family: Theme.sans
                        font.weight: Font.Black
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        color: Notifs.dnd ? Theme.paper : Theme.inkLine
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
            }
        }
    }
}
