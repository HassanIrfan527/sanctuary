import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// One notification as a speech bubble. The tail points up at the bar, so the
// toast reads as the desk talking. Critical ones shout: zigzag balloon, red
// shadow, and they stay until dismissed.
//
// It arrives with a slam — oversized and tilted, snapping to rest in 120ms,
// ease-out, no bounce (§2). Each bubble rests at a tiny tilt picked from its
// id, so a stack looks lettered by hand instead of laid out by a grid.
//
//   left click   the notification's default action (or dismiss)
//   right click  dismiss
//   hover        holds it on screen
Item {
    id: toast
    required property var modelData
    readonly property var n: modelData
    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
    readonly property var extra: Notifs.extraActions(n)
    readonly property bool hasImage: (n.image || "") !== ""

    readonly property int tail: 12
    readonly property int pad: 16

    width: 360
    height: tail + bubble.height + Theme.inkShadow + 8

    rotation: ((n.id % 3) - 1) * 0.8
    transformOrigin: Item.TopRight
    antialiasing: true

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
    // A replaced notification (same id, new text) starts its clock again.
    Connections {
        target: toast.n
        function onSummaryChanged() { toast.restart(); }
        function onBodyChanged() { toast.restart(); }
    }
    function restart() {
        if (Notifs.timeoutFor(n) > 0)
            lifeAnim.restart();
        slam.restart();
    }

    // ── motion ───────────────────────────────────────────────────────
    scale: 1
    opacity: 1
    Component.onCompleted: slam.start()

    ParallelAnimation {
        id: slam
        NumberAnimation { target: toast; property: "scale"; from: 1.14; to: 1; duration: Theme.quick; easing.type: Easing.OutCubic }
        NumberAnimation { target: toast; property: "opacity"; from: 0; to: 1; duration: Theme.quick * 0.6; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: leave
        ParallelAnimation {
            NumberAnimation { target: toast; property: "opacity"; to: 0; duration: Theme.quick; easing.type: Easing.OutCubic }
            NumberAnimation { target: toast; property: "scale"; to: 0.94; duration: Theme.quick; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: Notifs.unpop(toast.n) }
    }

    // ── the balloon ──────────────────────────────────────────────────
    Item {
        id: bubble
        x: 0
        y: toast.tail
        width: toast.width - Theme.inkShadow - 6
        height: body.implicitHeight + toast.pad * 2 + 6

        InkBubbleShape {
            x: Theme.inkShadow
            y: Theme.inkShadow
            width: parent.width
            height: parent.height
            tail: toast.tail
            shout: toast.critical
            fill: toast.critical ? Theme.red : Theme.peach
            stroke: "transparent"
        }
        InkBubbleShape {
            anchors.fill: parent
            tail: toast.tail
            shout: toast.critical
        }

        // The caption box: an ink tab hanging off the top-left, holding the app
        // name — the narration box of a manga panel.
        Rectangle {
            x: toast.pad
            y: -height / 2
            width: cap.implicitWidth + 12
            height: cap.implicitHeight + 4
            color: Theme.inkLine
            visible: cap.text !== ""
            Text {
                id: cap
                anchors.centerIn: parent
                text: ((toast.n?.appName ?? "") || "").toUpperCase()
                font.family: Theme.sans
                font.weight: Font.Black
                font.pixelSize: 9
                font.letterSpacing: 1
                color: Theme.paper
            }
        }

        Row {
            id: body
            x: toast.pad
            y: toast.pad + 4
            width: bubble.width - toast.pad * 2
            spacing: 12

            // Artwork (album art, an avatar) gets its own small panel.
            Rectangle {
                visible: toast.hasImage
                width: 46
                height: 46
                color: Theme.paper
                border.width: 2
                border.color: Theme.inkLine
                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: toast.hasImage ? (toast.n?.image ?? "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 92
                    sourceSize.height: 92
                }
            }

            Column {
                width: body.width - (toast.hasImage ? 58 : 0)
                spacing: 4

                Text {
                    width: parent.width
                    text: (toast.n?.summary ?? "")
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 14
                    color: Theme.inkLine
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: (toast.n?.body ?? "")
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font.family: Theme.sans
                    font.weight: Font.Medium
                    font.pixelSize: 12
                    lineHeight: 1.1
                    color: Theme.inkSoft
                }

                Row {
                    visible: toast.extra.length > 0
                    spacing: 8
                    topPadding: 4
                    Repeater {
                        model: toast.extra
                        delegate: Rectangle {
                            required property var modelData
                            width: lbl.implicitWidth + 16
                            height: 22
                            color: btn.pressed ? Theme.inkLine : Theme.paper
                            border.width: 2
                            border.color: Theme.inkLine
                            Text {
                                id: lbl
                                anchors.centerIn: parent
                                text: parent.modelData.text.toUpperCase()
                                font.family: Theme.sans
                                font.weight: Font.Black
                                font.pixelSize: 9
                                font.letterSpacing: 0.6
                                color: btn.pressed ? Theme.paper : Theme.inkLine
                            }
                            MouseArea {
                                id: btn
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: parent.modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }

    HoverHandler { id: hover }

    // z -1 puts it under the balloon. Text and shapes don't take clicks, so they
    // fall through to here; the action buttons' own MouseAreas still win.
    MouseArea {
        anchors.fill: bubble
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
