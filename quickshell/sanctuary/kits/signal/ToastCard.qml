import QtQuick
import ".."

// KIT · ToastCard — one notification on screen, and how it comes and goes.
//
//   ▌MSG·07  DISCORD                                   22:41
//   ▌Summary in bold
//   ▌Body, three lines at most…
//   ▌[ reply ]  [ mark read ]
//   ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  ← time left, draining
//
//   urgency   "low" | "normal" | "critical"
//   life      1 → 0 as its time runs out (drawn only when `timed`)
//   actions   [{ text, invoke() }] — the app's buttons
//   appear() / vanish() play the motion; vanished() when it has gone
// Signal: a log entry — the stripe is the urgency (trace / dim / alarm); it
// slides in from the right, 160ms ease-out.
Item {
    id: card

    property string urgency: "normal"
    property int seq: 0
    property string app: ""
    property var time: new Date()
    property string image: ""
    property string summary: ""
    property string body: ""
    property var actions: []
    property bool timed: false
    property real life: 1
    readonly property alias hovered: hover.hovered

    signal activated()
    signal dismissed()
    signal vanished()

    function appear() { enter.restart(); }
    function vanish() { leave.start(); }

    readonly property bool critical: urgency === "critical"
    readonly property color stripe: critical ? Theme.sigAlarm : urgency === "low" ? Theme.surface2 : Theme.sigHot

    width: 380
    height: box.height

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
        ScriptAction { script: card.vanished() }
    }

    Rectangle {
        id: box
        width: card.width
        height: col.implicitHeight + 22
        color: hover.hovered ? Theme.sigCell : Theme.sigFill
        border.width: 1
        border.color: card.critical ? Theme.sigAlarm : Theme.sigRule

        Rectangle {   // urgency stripe
            x: 1
            y: 1
            width: 2
            height: parent.height - 2
            color: card.stripe
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
                    text: "MSG·" + Theme.pad(card.seq, 2, "0") + "  " + (card.app || "—").toUpperCase()
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: card.critical ? Theme.sigAlarm : Theme.sigLabel
                }
                Text {
                    anchors.right: parent.right
                    text: Qt.formatDateTime(card.time, "hh:mm:ss")
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
                    visible: card.image !== ""
                    width: visible ? 38 : 0
                    height: 38
                    source: visible ? card.image : ""
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
                        text: card.summary
                        elide: Text.ElideRight
                        font.family: Theme.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.sigValue
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: card.body
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
                visible: card.actions.length > 0
                spacing: 10
                topPadding: 2
                Repeater {
                    model: card.actions
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
            visible: card.timed
            x: 3
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            height: 1
            width: (parent.width - 4) * card.life
            color: card.stripe
            opacity: 0.7
        }

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => mouse.button === Qt.RightButton ? card.dismissed() : card.activated()
        }
    }
}
