import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · ToastCard — one notification on screen.
//
//     ┌ AHMED ┐                                  ← the name tab, pink
//   ╔═╧═══════╧═══════════════════════════════╗
//   ║ ┌──────┐ ▣ discord                 now  ║
//   ║ │ face │ bro the CS201 assignment,      ║
//   ║ └──────┘ deadline is tonight            ║
//   ║          [ reply ] [ mark read ]        ║
//   ║ ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔ ← time left        ║
//   ╚═════════════════════════════════════════╝
//
//   urgency   "low" | "normal" | "critical"
//   life      1 → 0 as its time runs out (drawn only when `timed`)
//   actions   [{ text, invoke() }] — the app's buttons
//   appear() / vanish(); vanished() when it has gone
// Lantern: one wooden frame; the portrait sunk in a slot inside it — the
// notification's own picture in fat pixels, or else the app's icon (Harry,
// 2026-10-16: nothing invented); the summary on a pink tab over the top edge;
// the first action pink, the rest wood. Critical swaps pink for red: tab,
// frame, header and slot. No motion: it is there, then it isn't.
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

    function appear() { }
    function vanish() { Qt.callLater(card.vanished); }

    readonly property bool critical: urgency === "critical"
    readonly property color mark: critical ? Theme.lanAlarm : Theme.lanPink
    readonly property string appKey: app.toLowerCase()

    width: 430
    height: 14 + frame.height

    Wood {
        id: frame
        y: 14
        width: card.width
        height: content.implicitHeight + 2 * edge + 24 + (card.timed ? 8 : 0)
        thick: 6
        shadow: true
        outline: card.critical ? Theme.lanAlarm : Theme.lanOutline
        fill: hover.hovered ? Theme.lanRaised : Theme.lanPaper

        Row {
            id: content
            x: 12
            y: 14
            width: parent.width - 24
            spacing: 12

            Slot {
                id: portrait
                width: 72
                height: 72
                tone: card.critical ? "alarm" : ""
                Image {
                    id: pic
                    anchors.fill: parent
                    z: -1
                    visible: card.image !== "" && status === Image.Ready
                    source: card.image
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: false
                    sourceSize.width: 24          // 3× on screen: fat square pixels
                    sourceSize.height: 24
                }
                Icon {
                    anchors.centerIn: parent
                    visible: !pic.visible
                    size: 48
                    name: card.critical ? "bell-ring" : (appProbe.known ? card.appKey : "bell")
                    color: card.critical ? Theme.lanAlarm : Theme.lanDim
                }
                Icon { id: appProbe; visible: false; name: card.appKey }
            }

            Column {
                width: parent.width - portrait.width - parent.spacing
                spacing: 4

                Item {   // header: which app, and when
                    width: parent.width
                    height: 22
                    LText {
                        width: parent.width - when.implicitWidth - 12
                        elide: Text.ElideRight
                        text: G.plain((card.app || "—").toLowerCase())
                        color: card.critical ? Theme.lanAlarm : Theme.lanDim
                    }
                    LText {
                        id: when
                        anchors.right: parent.right
                        text: Qt.formatDateTime(card.time, "h:mm AP").toLowerCase()
                        color: card.critical ? Theme.lanAlarm : Theme.lanDim
                    }
                }
                LText {
                    width: parent.width
                    visible: text !== ""
                    text: G.plain(card.body !== "" ? card.body : card.summary)
                    textFormat: card.body !== "" ? Text.StyledText : Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    color: Theme.lanText
                }
                Row {
                    visible: card.actions.length > 0
                    spacing: 8
                    topPadding: 4
                    Repeater {
                        model: card.actions
                        delegate: Item {
                            id: act
                            required property var modelData
                            required property int index
                            readonly property bool primary: index === 0
                            width: actText.implicitWidth + 24
                            height: 28
                            Rectangle { x: 2; width: parent.width - 4; height: parent.height; color: Theme.lanOutline }
                            Rectangle { y: 2; width: parent.width; height: parent.height - 4; color: Theme.lanOutline }
                            Rectangle {
                                x: 2
                                y: 2
                                width: parent.width - 4
                                height: parent.height - 4
                                color: act.primary || actArea.containsMouse ? card.mark : Theme.lanWood
                                Rectangle {
                                    width: parent.width
                                    height: 2
                                    color: act.primary || actArea.containsMouse ? (card.critical ? Theme.lanAlarmHi : Theme.lanPinkHi) : Theme.lanWoodLit
                                }
                            }
                            LText {
                                id: actText
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 1
                                text: G.plain(act.modelData.text.toLowerCase())
                                color: act.primary || actArea.containsMouse
                                       ? (card.critical ? Theme.lanOnAlarm : Theme.lanOnPink) : "#fff0cc"
                            }
                            MouseArea {
                                id: actArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: act.modelData.invoke()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {   // time left: a 2px line, in 2px steps
            visible: card.timed
            x: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            width: parent.width - 24
            height: 2
            color: Theme.lanSunk
            Rectangle {
                width: Math.floor(parent.width * Math.max(0, Math.min(1, card.life)) / 2) * 2
                height: 2
                color: card.mark
            }
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

    Item {   // the tab: who / what, over the frame's top edge
        x: 14
        y: 0
        width: tabText.width + 24
        height: 28
        Rectangle { x: 2; width: parent.width - 4; height: parent.height; color: Theme.lanOutline }
        Rectangle { y: 2; width: parent.width; height: parent.height - 4; color: Theme.lanOutline }
        Rectangle {
            x: 2
            y: 2
            width: parent.width - 4
            height: parent.height - 4
            color: card.mark
            LText {
                id: tabText
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                width: Math.min(implicitWidth, 300)
                elide: Text.ElideRight
                text: G.plain((card.body !== "" ? card.summary : card.app).toUpperCase())
                color: card.critical ? Theme.lanOnAlarm : Theme.lanOnPink
            }
        }
    }
}
