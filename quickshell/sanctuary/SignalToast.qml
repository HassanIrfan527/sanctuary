import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// One notification as a log entry on an instrument:
//
//   ▌MSG·07  DISCORD                                   22:41
//   ▌Summary in bold
//   ▌Body, three lines at most…
//   ▌[ reply ]  [ mark read ]
//   ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  ← time left, draining
//
// The stripe is the urgency (trace / dim / alarm). The bottom rule drains as
// the toast's time runs out, and stops while you hover.
Item {
    id: toast
    required property var modelData
    readonly property var n: modelData
    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
    readonly property bool low: n?.urgency === NotificationUrgency.Low
    readonly property color stripe: critical ? Theme.sigAlarm : low ? Theme.surface2 : Theme.sigHot
    readonly property var extra: Notifs.extraActions(n)
    readonly property var m: Notifs.meta(n)

    width: 380
    height: box.height

    // ── life ─────────────────────────────────────────────────────────
    property real life: 1
    NumberAnimation on life {
        id: lifeAnim
        running: Notifs.timeoutFor(toast.n) > 0
        paused: running && hover.hovered
        from: 1
        to: 0
        duration: Math.max(1, Notifs.timeoutFor(toast.n))
        onFinished: leave.start()
    }
    Connections {
        target: toast.n
        function onSummaryChanged() { toast.restart(); }
        function onBodyChanged() { toast.restart(); }
    }
    function restart() {
        if (Notifs.timeoutFor(n) > 0)
            lifeAnim.restart();
        enter.restart();
    }

    // ── motion: slide in from the right, ease-out, 160ms ─────────────
    Component.onCompleted: enter.start()
    ParallelAnimation {
        id: enter
        NumberAnimation { target: box; property: "x"; from: 28; to: 0; duration: Theme.duration; easing.type: Easing.OutCubic }
        NumberAnimation { target: box; property: "opacity"; from: 0; to: 1; duration: Theme.duration; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: leave
        ParallelAnimation {
            NumberAnimation { target: box; property: "x"; to: 28; duration: Theme.quick; easing.type: Easing.InCubic }
            NumberAnimation { target: box; property: "opacity"; to: 0; duration: Theme.quick; easing.type: Easing.InCubic }
        }
        ScriptAction { script: Notifs.unpop(toast.n) }
    }

    Rectangle {
        id: box
        width: toast.width
        height: col.implicitHeight + 22
        color: hover.hovered ? Theme.sigCell : Theme.sigFill
        border.width: 1
        border.color: toast.critical ? Theme.sigAlarm : Theme.sigRule

        Rectangle {   // urgency stripe
            x: 1
            y: 1
            width: 2
            height: parent.height - 2
            color: toast.stripe
        }

        Column {
            id: col
            x: 14
            y: 10
            width: parent.width - 26
            spacing: 4

            Item {
                width: parent.width
                height: head.implicitHeight
                Text {
                    id: head
                    text: "MSG·" + Theme.pad(toast.m.seq, 2, "0")
                          + "  " + ((toast.n?.appName ?? "") || "—").toUpperCase()
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: toast.critical ? Theme.sigAlarm : Theme.sigLabel
                }
                Text {
                    anchors.right: parent.right
                    text: Qt.formatDateTime(toast.m.time, "hh:mm:ss")
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.sigLabel
                }
            }

            Row {
                width: parent.width
                spacing: 10

                Image {
                    id: art
                    visible: ((toast.n?.image ?? "") || "") !== ""
                    width: visible ? 38 : 0
                    height: 38
                    source: visible ? (toast.n?.image ?? "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 76
                    sourceSize.height: 76
                }

                Column {
                    width: parent.width - (art.visible ? art.width + 10 : 0)
                    spacing: 3
                    Text {
                        width: parent.width
                        text: (toast.n?.summary ?? "")
                        elide: Text.ElideRight
                        font.family: Theme.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.sigValue
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: (toast.n?.body ?? "")
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        font.family: Theme.mono
                        font.pixelSize: 11
                        color: Theme.subtext0
                    }
                }
            }

            Row {
                visible: toast.extra.length > 0
                spacing: 10
                topPadding: 2
                Repeater {
                    model: toast.extra
                    delegate: Text {
                        required property var modelData
                        text: "[ " + modelData.text.toLowerCase() + " ]"
                        font.family: Theme.mono
                        font.pixelSize: 10
                        color: act.containsMouse ? Theme.sigValue : Theme.sigHot
                        MouseArea {
                            id: act
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }

        Rectangle {   // time left
            visible: Notifs.timeoutFor(toast.n) > 0
            x: 3
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            height: 1
            width: (parent.width - 4) * toast.life
            color: toast.stripe
            opacity: 0.7
        }

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    toast.n.dismiss();
                else
                    Notifs.activate(toast.n);
            }
        }
    }
}
