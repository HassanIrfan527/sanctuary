import QtQuick
import Quickshell
import Quickshell.Wayland

// Ink — the bar as a strip of manga panels.
//
//   [ workspaces ]          [ CLOCK ]          [ music ] [ mic ] [ tray ] [ 3 ]
//
// Every module is a separate panel (islands are non-negotiable, §3); each one's
// hard shadow is its accent. The clock panel is tilted two degrees, the way a
// key panel on a manga page is, and carries a screentone.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    visible: Ui.barShown
    color: "transparent"
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.inkBarH
    exclusiveZone: Theme.inkBarH

    WlrLayershell.namespace: "sanctuary-bar"
    WlrLayershell.layer: WlrLayer.Top

    readonly property string output: modelData ? modelData.name : ""

    // ── left: workspaces ─────────────────────────────────────────────
    // A page of panels: each workspace is a box, and a box grows wider with the
    // number of windows in it — busy workspaces literally take more of the page.
    //   focused  solid ink        occupied  screentone
    //   empty    bare outline     urgent    red
    InkPanel {
        id: wsPanel
        x: 10
        y: 8
        accent: Theme.mauve
        padX: 8
        interactive: true
        onScrolled: wheel => wheel.angleDelta.y > 0 ? Niri.workspaceUp() : Niri.workspaceDown()

        Row {
            spacing: 5
            Repeater {
                model: Niri.workspacesOn(bar.output)

                delegate: MouseArea {
                    id: ws
                    required property var modelData
                    readonly property int wins: Niri.windowCount(modelData.id)
                    readonly property bool focused: modelData.is_active
                    width: 18 + Math.min(wins, 3) * 7
                    height: 18
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.focusWorkspace(modelData.idx)

                    Behavior on width { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        color: ws.modelData.is_urgent ? Theme.red : ws.focused ? Theme.inkLine : Theme.paper
                        border.width: ws.wins > 0 || ws.focused ? 2 : 1.5
                        border.color: ws.wins > 0 || ws.focused ? Theme.inkLine : Theme.inkMuted
                        Behavior on color { ColorAnimation { duration: Theme.duration } }

                        InkHalftone {
                            anchors.fill: parent
                            anchors.margins: 2
                            visible: ws.wins > 0 && !ws.focused && !ws.modelData.is_urgent
                            from: 0.5       // tone the right half only; the digit sits in clean paper
                            step: 4
                            strength: 0.45
                        }

                        // Knockout: a paper patch behind the digit, so the tone
                        // never runs through the number (it made 1 and 2 mud).
                        Rectangle {
                            anchors.centerIn: parent
                            width: wsNum.implicitWidth + 4
                            height: wsNum.implicitHeight - 2
                            color: Theme.paper
                            visible: ws.wins > 0 && !ws.focused && !ws.modelData.is_urgent
                        }

                        Text {
                            id: wsNum
                            anchors.centerIn: parent
                            text: ws.modelData.name || ws.modelData.idx
                            font.family: Theme.sans
                            font.weight: Font.Black
                            font.pixelSize: 10
                            color: ws.focused || ws.modelData.is_urgent ? Theme.paper
                                 : ws.wins > 0 ? Theme.inkLine : Theme.inkMuted
                        }
                    }
                }
            }
        }
    }

    // ── centre: the clock ────────────────────────────────────────────
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    InkPanel {
        id: clockPanel
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        rotation: -2
        antialiasing: true
        accent: Caution.active ? Theme.red : Theme.peach   // Master Caution, part 1
        hot: Caution.active
        tone: 0.22
        toneFrom: 0.62
        padX: 16

        Row {
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "hh:mm AP").split(" ")[0]
                font.family: Theme.display
                font.weight: Theme.displayWeight
                font.pixelSize: Theme.hasBangers ? 26 : 21
                font.letterSpacing: 1
                color: Theme.inkLine
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: -1
                Text {
                    text: Qt.formatDateTime(clock.date, "AP")
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 9
                    color: Theme.inkLine
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "ddd dd").toUpperCase()
                    font.family: Theme.sans
                    font.weight: Font.Bold
                    font.pixelSize: 9
                    font.letterSpacing: 0.5
                    color: Theme.inkSoft
                }
            }
        }
    }

    // Master Caution, part 2: a red "!!" panel beside the clock, naming what
    // is wrong — the manga "!" over a character's head. Only while something
    // is. Click = acknowledge (Caution.qml).
    InkPanel {
        visible: Caution.active
        anchors.right: clockPanel.left
        anchors.rightMargin: 14 + Theme.inkShadow
        y: 8
        rotation: 3
        antialiasing: true
        accent: Theme.red
        face: Theme.red
        padX: 10
        interactive: true
        onClicked: Caution.acknowledge()

        Row {
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "!!"
                font.family: Theme.display
                font.weight: Theme.displayWeight
                font.pixelSize: Theme.hasBangers ? 22 : 17
                color: Theme.crust
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Caution.text
                font.family: Theme.sans
                font.weight: Font.Black
                font.pixelSize: 10
                font.letterSpacing: 0.8
                color: Theme.crust
            }
        }
    }

    // ── right: exceptions · music · mic · tray · notifications ───────
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 10 + Theme.inkShadow
        y: 8
        spacing: 10 + Theme.inkShadow
        layoutDirection: Qt.LeftToRight

        // Exception panels: only while a reading is abnormal (TEMP hot, DISK
        // nearly full — Sys.exceptions). Yellow shadow = warn, red = alarm.
        Repeater {
            model: Sys.exceptions
            delegate: InkPanel {
                id: exc
                required property var modelData
                accent: modelData.level === "alarm" ? Theme.red : Theme.yellow
                interactive: modelData.key === "temp"
                onClicked: mouse => { if (mouse.button === Qt.RightButton) Sys.btop(); }
                Row {
                    spacing: 6
                    Text {
                        text: exc.modelData.label
                        font.family: Theme.sans
                        font.weight: Font.Black
                        font.pixelSize: 10
                        color: Theme.inkLine
                    }
                    Text {
                        text: exc.modelData.value.toUpperCase()
                        font.family: Theme.sans
                        font.weight: Font.Black
                        font.pixelSize: 10
                        color: exc.modelData.level === "alarm" ? Theme.red : Theme.inkLine
                    }
                }
            }
        }

        // Left: play / pause. Right: the player card (Player.qml).
        InkPanel {
            id: music
            visible: Media.hasTrack
            accent: Theme.lavender
            progress: Media.progress
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    Ui.playerX = music.mapToItem(null, music.width / 2, 0).x;
                    Ui.playerOpen = !Ui.playerOpen;
                } else {
                    Media.toggle();
                }
            }
            onScrolled: wheel => wheel.angleDelta.y > 0 ? Media.next() : Media.previous()

            Row {
                spacing: 7
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.playing ? "▶" : "‖"
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 11
                    color: Theme.inkLine
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 220)
                    elide: Text.ElideRight
                    text: Media.title.toUpperCase()
                          + (Media.artist !== "" ? "  —  " + Media.artist.toUpperCase() : "")
                    font.family: Theme.sans
                    font.weight: Font.Bold
                    font.pixelSize: 10
                    font.letterSpacing: 0.4
                    color: Theme.inkLine
                }
            }
        }

        InkPanel {
            id: mic
            visible: Media.micKnown
            accent: Media.micOn ? Theme.green : Theme.surface1
            face: Media.micOn ? Theme.paper : Theme.paperDim
            interactive: true
            onClicked: mouse => mouse.button === Qt.RightButton ? Media.toggleMic() : Media.openMixer()

            Row {
                spacing: 6
                Text {
                    text: "MIC"
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 10
                    color: Theme.inkLine
                }
                Text {
                    text: Media.micOn ? "ON" : "--"
                    font.family: Theme.sans
                    font.weight: Font.Black
                    font.pixelSize: 10
                    color: Media.micOn ? Theme.inkLine : Theme.inkMuted
                }
            }
        }

        InkPanel {
            visible: !trayRow.empty
            accent: Theme.surface1
            padX: 10
            Tray {
                id: trayRow
                iconSize: 14
            }
        }

        // The count, lettered like a sound effect. Renders nothing at zero (§2),
        // unless DND is on — then it says "Zzz", which is what DND is.
        InkPanel {
            id: notif
            visible: Notifs.count > 0 || Notifs.dnd
            accent: Notifs.dnd ? Theme.surface1 : Theme.peach
            hot: Ui.centreOpen
            padX: 10
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    Notifs.dnd = !Notifs.dnd;
                else
                    Ui.centreOpen = !Ui.centreOpen;
            }

            Text {
                text: Notifs.dnd ? "Zzz" : String(Notifs.count)
                font.family: Theme.display
                font.weight: Theme.displayWeight
                font.pixelSize: Theme.hasBangers ? 20 : 16
                color: Notifs.dnd ? Theme.inkMuted : Theme.inkLine
            }
        }
    }
}
