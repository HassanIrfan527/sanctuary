import QtQuick
import Quickshell
import Quickshell.Wayland

// The music player card — right-click the music module to open it.
//
// It is a full-screen, see-through layer with the card hung under the music
// module. The see-through part is the point: a click ANYWHERE outside the card
// lands on it and closes the card. Layer-shell popups have no "click outside"
// of their own, so this is how one gets it.
//
//   space  play / pause      h ←  previous      l →  next      esc q  close
//   click the progress line to seek (when the player allows it)
PanelWindow {
    id: win

    visible: Ui.playerOpen && Media.hasTrack
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-player"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // The track ending / the player quitting closes it too.
    Connections {
        target: Media
        function onHasTrackChanged() {
            if (!Media.hasTrack)
                Ui.playerOpen = false;
        }
    }

    readonly property int cardW: 380
    readonly property int cardTop: (Theme.signal ? Theme.sigBarH : Theme.inkBarH) + 4

    MouseArea {   // the scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.playerOpen = false
    }

    Item {
        id: card
        focus: true
        // Hung under the music module. Opened without a click (IPC / a keybind)
        // there is no module x, so it sits right, where the module usually is.
        x: Math.max(8, Math.min(win.width - win.cardW - 16,
                                (Ui.playerX > 0 ? Ui.playerX : win.width) - win.cardW / 2))
        y: win.cardTop
        width: win.cardW
        height: Theme.signal ? sigCard.height : inkCard.height + 6

        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape || k === Qt.Key_Q)
                Ui.playerOpen = false;
            else if (k === Qt.Key_Space)
                Media.toggle();
            else if (k === Qt.Key_H || k === Qt.Key_Left)
                Media.previous();
            else if (k === Qt.Key_L || k === Qt.Key_Right)
                Media.next();
            else
                return;
            event.accepted = true;
        }

        // Swallow clicks on the card so they don't reach the scrim.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        opacity: win.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

        // ══ Signal ═══════════════════════════════════════════════════
        Rectangle {
            id: sigCard
            visible: Theme.signal
            width: parent.width
            height: sigCol.implicitHeight + 28
            color: Theme.sigFill
            border.width: 1
            border.color: Theme.sigRule

            SignalTicks {
                anchors.fill: parent
                anchors.margins: -3
            }

            Column {
                id: sigCol
                x: 14
                y: 14
                width: parent.width - 28
                spacing: 10

                Item {
                    width: parent.width
                    height: sigHead.implicitHeight
                    Text {
                        id: sigHead
                        text: (Media.playing ? "PLAY" : "HOLD") + "  ·  " + Media.identity.toUpperCase()
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: Media.playing ? Theme.sigHot : Theme.sigLabel
                    }
                    Text {
                        anchors.right: parent.right
                        text: "esc"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        color: Theme.surface2
                    }
                }

                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        visible: Media.art !== ""
                        width: visible ? 84 : 0
                        height: 84
                        color: Theme.sigCell
                        border.width: 1
                        border.color: Theme.sigRule
                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            source: Media.art
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 168
                            sourceSize.height: 168
                        }
                    }

                    Column {
                        width: parent.width - (Media.art !== "" ? 96 : 0)
                        spacing: 4
                        Text {
                            width: parent.width
                            text: Media.title
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.family: Theme.mono
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: Theme.sigValue
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: Media.artist
                            elide: Text.ElideRight
                            font.family: Theme.mono
                            font.pixelSize: 11
                            color: Theme.subtext0
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: Media.album
                            elide: Text.ElideRight
                            font.family: Theme.mono
                            font.pixelSize: 10
                            color: Theme.sigLabel
                        }
                    }
                }

                // position: a hairline you can click to seek
                Column {
                    width: parent.width
                    spacing: 4
                    visible: Media.length > 0
                    Item {
                        width: parent.width
                        height: 10
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 2
                            color: Theme.surface0
                            Rectangle {
                                width: parent.width * Media.progress
                                height: 2
                                color: Theme.sigHot
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: Media.canSeek
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => Media.seek(mouse.x / width)
                        }
                    }
                    Item {
                        width: parent.width
                        height: 12
                        Text {
                            text: Media.clock(Media.position)
                            font.family: Theme.mono
                            font.pixelSize: 9
                            color: Theme.sigLabel
                        }
                        Text {
                            anchors.right: parent.right
                            text: Media.clock(Media.length)
                            font.family: Theme.mono
                            font.pixelSize: 9
                            color: Theme.sigLabel
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 22
                    Repeater {
                        model: [
                            { t: "|◀", hint: "h", act: () => Media.previous() },
                            { t: Media.playing ? "‖" : "▶", hint: "spc", act: () => Media.toggle() },
                            { t: "▶|", hint: "l", act: () => Media.next() }
                        ]
                        delegate: Item {
                            id: btn
                            required property var modelData
                            width: 52
                            height: 30
                            Rectangle {
                                anchors.fill: parent
                                color: ba.containsMouse ? Theme.sigCell : "transparent"
                                border.width: 1
                                border.color: ba.containsMouse ? Theme.sigHot : Theme.sigRule
                            }
                            Text {
                                anchors.centerIn: parent
                                text: btn.modelData.t
                                font.family: Theme.mono
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: Theme.sigValue
                            }
                            Text {
                                anchors.top: parent.bottom
                                anchors.topMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btn.modelData.hint
                                font.family: Theme.mono
                                font.pixelSize: 8
                                color: Theme.surface2
                            }
                            MouseArea {
                                id: ba
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: btn.modelData.act()
                            }
                        }
                    }
                }

                Item { width: 1; height: 4 }   // room for the key hints
            }
        }

        // ══ Ink / Paper ══════════════════════════════════════════════
        Item {
            id: inkCard
            visible: Theme.ink
            width: parent.width - 6
            height: inkCol.implicitHeight + 32

            Rectangle {   // hard shadow
                x: 6
                y: 6
                width: parent.width
                height: parent.height
                color: Theme.lavender
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.paper
                border.width: Theme.inkStroke
                border.color: Theme.inkLine

                InkHalftone {
                    anchors.fill: parent
                    anchors.margins: Theme.inkStroke
                    from: 0.7
                    strength: 0.18
                }
            }

            // Caption tab, like the toasts: the player's name.
            Rectangle {
                x: 16
                y: -height / 2
                width: capTxt.implicitWidth + 12
                height: capTxt.implicitHeight + 4
                color: Theme.inkLine
                Text {
                    id: capTxt
                    anchors.centerIn: parent
                    text: (Media.playing ? "NOW PLAYING · " : "PAUSED · ") + Media.identity.toUpperCase()
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    color: Theme.paper
                }
            }

            Column {
                id: inkCol
                x: 18
                y: 18
                width: parent.width - 36
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 14

                    Item {
                        visible: Media.art !== ""
                        width: visible ? 92 : 0
                        height: 92
                        Rectangle {
                            x: 4
                            y: 4
                            width: parent.width
                            height: parent.height
                            color: Theme.peach
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.paper
                            border.width: Theme.inkStroke
                            border.color: Theme.inkLine
                            Image {
                                anchors.fill: parent
                                anchors.margins: Theme.inkStroke
                                source: Media.art
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 184
                                sourceSize.height: 184
                            }
                        }
                    }

                    Column {
                        width: parent.width - (Media.art !== "" ? 106 : 0)
                        spacing: 4
                        Text {
                            width: parent.width
                            text: Media.title.toUpperCase()
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.family: Theme.sans
                            font.weight: Font.Black
                            font.pixelSize: 15
                            color: Theme.inkLine
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: Media.artist
                            elide: Text.ElideRight
                            font.family: Theme.sans
                            font.weight: Font.Bold
                            font.pixelSize: 12
                            color: Theme.inkSoft
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: Media.album
                            elide: Text.ElideRight
                            font.family: Theme.sans
                            font.pixelSize: 11
                            color: Theme.inkMuted
                        }
                    }
                }

                // position: a thick ink track, click to seek
                Column {
                    width: parent.width
                    spacing: 4
                    visible: Media.length > 0
                    Rectangle {
                        width: parent.width
                        height: 10
                        color: Theme.paper
                        border.width: 2
                        border.color: Theme.inkLine
                        Rectangle {
                            x: 2
                            y: 2
                            width: Math.max(0, (parent.width - 4) * Media.progress)
                            height: parent.height - 4
                            color: Theme.inkLine
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            enabled: Media.canSeek
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => Media.seek((mouse.x - 4) / (width - 8))
                        }
                    }
                    Item {
                        width: parent.width
                        height: 14
                        Text {
                            text: Media.clock(Media.position)
                            font.family: Theme.sans
                            font.weight: Font.Bold
                            font.pixelSize: 10
                            color: Theme.inkSoft
                        }
                        Text {
                            anchors.right: parent.right
                            text: Media.clock(Media.length)
                            font.family: Theme.sans
                            font.weight: Font.Bold
                            font.pixelSize: 10
                            color: Theme.inkSoft
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 18
                    Repeater {
                        model: [
                            { t: "|◀", act: () => Media.previous(), big: false },
                            { t: Media.playing ? "‖" : "▶", act: () => Media.toggle(), big: true },
                            { t: "▶|", act: () => Media.next(), big: false }
                        ]
                        delegate: Item {
                            id: ib
                            required property var modelData
                            width: modelData.big ? 58 : 44
                            height: 36
                            Rectangle {
                                x: iba.pressed ? 1 : 4
                                y: iba.pressed ? 1 : 4
                                width: parent.width
                                height: parent.height
                                color: ib.modelData.big ? Theme.peach : Theme.mauve
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: ib.modelData.big ? Theme.inkLine : Theme.paper
                                border.width: Theme.inkStroke
                                border.color: Theme.inkLine
                                Text {
                                    anchors.centerIn: parent
                                    text: ib.modelData.t
                                    font.family: Theme.sans
                                    font.weight: Font.Black
                                    font.pixelSize: ib.modelData.big ? 16 : 13
                                    color: ib.modelData.big ? Theme.paper : Theme.inkLine
                                }
                            }
                            MouseArea {
                                id: iba
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ib.modelData.act()
                            }
                        }
                    }
                }
            }
        }
    }
}
