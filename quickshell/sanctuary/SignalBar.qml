import QtQuick
import Quickshell
import Quickshell.Wayland

// Signal — the bar as an instrument strip.
//
//   WS 1 2 3 4 │ WIN kitty · nvim      10:41:07 PM      NET ↓1.2M ↑40K ╱╲ │ CPU 12% ╱╲ │ MEM 41% ╱╲ │ MIC LIVE ▮▮▮▯▯ │ ♪ … │ tray │ MSG 03
//
// One panel, cut into cells by hairlines, with registration marks at the
// corners. Every value is fixed-width so nothing shuffles as numbers change.
// Colour is spent on state only: the trace green, yellow at warn, red at alarm.
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
    implicitHeight: Theme.sigBarH
    exclusiveZone: Theme.sigBarH

    WlrLayershell.namespace: "sanctuary-bar"
    WlrLayershell.layer: WlrLayer.Top

    readonly property string output: modelData ? modelData.name : ""

    // Threshold colouring, shared by the three meters.
    function level(v) {
        return v >= 0.85 ? Theme.sigAlarm : v >= 0.65 ? Theme.sigWarn : Theme.sigHot;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        id: strip
        x: 8
        y: 6
        width: parent.width - 16
        height: Theme.sigStripH
        color: Theme.sigFill
        border.width: 1
        border.color: Theme.sigRule

        // Master Caution, part 1: the registration marks turn red. They frame
        // the whole strip, so the alarm is visible from anywhere on it.
        SignalTicks {
            anchors.fill: parent
            anchors.margins: -3
            color: Caution.active ? Theme.sigAlarm : Theme.sigHot
            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }

        // ── left ─────────────────────────────────────────────────────
        Row {
            id: left
            height: parent.height

            SignalCell {
                id: wsCell
                label: "WS"
                interactive: true
                onScrolled: wheel => wheel.angleDelta.y > 0 ? Niri.workspaceUp() : Niri.workspaceDown()

                Repeater {
                    model: Niri.workspacesOn(bar.output)
                    delegate: MouseArea {
                        id: ws
                        required property var modelData
                        readonly property bool focused: modelData.is_active
                        readonly property int wins: Niri.windowCount(modelData.id)
                        width: num.implicitWidth + 4
                        height: 18
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Niri.focusWorkspace(modelData.idx)

                        Text {
                            id: num
                            anchors.centerIn: parent
                            text: Theme.pad(ws.modelData.name || ws.modelData.idx, 2, "0")
                            font.family: Theme.mono
                            font.pixelSize: 11
                            font.weight: ws.focused ? Font.Bold : Font.Normal
                            color: ws.modelData.is_urgent ? Theme.sigAlarm
                                 : ws.focused ? Theme.sigHot
                                 : ws.wins > 0 ? Theme.sigValue : Theme.surface2
                        }
                        Rectangle {   // the focused cursor: a 2px underline
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: num.implicitWidth
                            height: 2
                            color: Theme.sigHot
                            visible: ws.focused
                        }
                    }
                }
            }

            SignalCell {
                label: "WIN"
                visible: Niri.focusedWindow !== null
                rule: false
                Text {
                    // Yields to the alert row: never closer than 24px to it.
                    width: Math.max(0, Math.min(implicitWidth, 260,
                                                alertRow.x - left.x - wsCell.width - 70))
                    elide: Text.ElideRight
                    text: Niri.focusedWindow
                          ? (Niri.focusedWindow.app_id || "?") + "  " + (Niri.focusedWindow.title || "")
                          : ""
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.subtext0
                }
            }
        }

        // ── centre: the clock (§1: the one thing read without looking) ──
        Row {
            id: clockRow
            anchors.centerIn: parent
            spacing: 8
            Row {   // hh:mm big, :ss small in the trace colour, sharing a baseline
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: hm
                    // 12-hour, like every other clock here. "hh" is only 12-hour
                    // when AP is in the SAME format string, so format once, slice.
                    text: Qt.formatDateTime(clock.date, "hh:mm AP").slice(0, 5)
                    font.family: Theme.mono
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.sigValue
                }
                Text {
                    anchors.baseline: hm.baseline
                    text: Qt.formatDateTime(clock.date, ":ss")
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Caution.active ? Theme.sigAlarm : Theme.sigHot   // caution, part 2
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "AP · ddd dd MMM").toUpperCase()
                font.family: Theme.mono
                font.pixelSize: 9
                font.letterSpacing: 1.2
                color: Theme.sigLabel
            }
        }

        // ── left of the clock: what is WRONG, if anything ───────────────
        // Built outward from the clock: the caution lamp nearest it, then the
        // exception cells (TEMP, DISK). Both exist only while something is off.
        // The right side is already full, so alarms take space from the window
        // title on the left instead (see WIN's width).
        Row {
            id: alertRow
            anchors.right: clockRow.left
            anchors.rightMargin: 14
            height: parent.height
            layoutDirection: Qt.RightToLeft
            spacing: 6

            // Master Caution, part 3: the lamp, naming what is wrong. Click =
            // acknowledge: dark until a NEW reason appears (Caution.qml).
            Item {
                visible: Caution.active
                width: lamp.width
                height: parent.height
                Rectangle {
                    id: lamp
                    anchors.verticalCenter: parent.verticalCenter
                    width: lampText.implicitWidth + 16
                    height: Theme.sigStripH - 12
                    color: lampArea.containsMouse ? "#3a1f2a" : "#2a1720"
                    border.width: 1
                    border.color: Theme.sigAlarm
                    Text {
                        id: lampText
                        anchors.centerIn: parent
                        text: "▲ " + Caution.text
                        font.family: Theme.mono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                        color: Theme.sigAlarm
                    }
                    MouseArea {
                        id: lampArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Caution.acknowledge()
                    }
                }
            }

            Repeater {
                model: Sys.exceptions
                delegate: SignalCell {
                    id: exc
                    required property var modelData
                    label: modelData.label
                    rule: false
                    labelColor: modelData.level === "alarm" ? Theme.sigAlarm : Theme.sigWarn
                    interactive: modelData.key === "temp"   // right-click TEMP: btop
                    onClicked: mouse => { if (mouse.button === Qt.RightButton) Sys.btop(); }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: exc.modelData.value
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: exc.modelData.level === "alarm" ? Theme.sigAlarm : Theme.sigWarn
                    }
                }
            }
        }

        // ── right ────────────────────────────────────────────────────
        Row {
            anchors.right: parent.right
            height: parent.height

            SignalCell {
                label: "NET"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↓" + Theme.pad(Sys.rate(Sys.rx), 4, " ") + " ↑" + Theme.pad(Sys.rate(Sys.tx), 4, " ")
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.sigValue
                }
                Sparkline {
                    anchors.verticalCenter: parent.verticalCenter
                    values: Sys.netHist
                    max: 0
                    line: Theme.teal
                }
            }

            // Right-click CPU or MEM: btop, floating (again to close it).
            SignalCell {
                label: "CPU"
                interactive: true
                onClicked: mouse => { if (mouse.button === Qt.RightButton) Sys.btop(); }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.pct(Sys.cpu)
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Sys.cpu >= 0.65 ? bar.level(Sys.cpu) : Theme.sigValue
                }
                Sparkline {
                    anchors.verticalCenter: parent.verticalCenter
                    values: Sys.cpuHist
                    line: bar.level(Sys.cpu)
                }
            }

            SignalCell {
                label: "MEM"
                interactive: true
                onClicked: mouse => { if (mouse.button === Qt.RightButton) Sys.btop(); }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.pct(Sys.mem)
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Sys.mem >= 0.65 ? bar.level(Sys.mem) : Theme.sigValue
                }
                Sparkline {
                    anchors.verticalCenter: parent.verticalCenter
                    values: Sys.memHist
                    line: bar.level(Sys.mem)
                }
            }

            // Mic: state word + input gain as five cells. Live earns the accent
            // (§3, the one thing that survived "ember"); muted goes dim.
            SignalCell {
                label: "MIC"
                visible: Media.micKnown
                labelColor: Media.micOn ? Theme.sigHot : Theme.sigLabel
                interactive: true
                onClicked: mouse => mouse.button === Qt.RightButton ? Media.toggleMic() : Media.openMixer()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.micOn ? "LIVE" : "MUTE"
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Media.micOn ? Theme.sigHot : Theme.surface2
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            required property int index
                            width: 3
                            height: 9
                            color: Media.micOn && Media.micVolume > index / 5 ? Theme.sigHot : Theme.surface0
                        }
                    }
                }
            }

            // Left: play / pause. Right: the player card (Player.qml).
            SignalCell {
                id: musicCell
                label: Media.playing ? "PLAY" : "HOLD"
                visible: Media.hasTrack
                interactive: true
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        Ui.playerX = musicCell.mapToItem(null, musicCell.width / 2, 0).x;
                        Ui.playerOpen = !Ui.playerOpen;
                    } else {
                        Media.toggle();
                    }
                }
                onScrolled: wheel => wheel.angleDelta.y > 0 ? Media.next() : Media.previous()

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        id: track
                        width: Math.min(implicitWidth, 150)
                        elide: Text.ElideRight
                        text: Media.title + (Media.artist !== "" ? " — " + Media.artist : "")
                        font.family: Theme.mono
                        font.pixelSize: 10
                        color: Theme.sigValue
                    }
                    Rectangle {   // position, as a hairline meter
                        width: track.width
                        height: 1
                        color: Theme.surface0
                        Rectangle {
                            width: parent.width * Media.progress
                            height: 1
                            color: Theme.sigHot
                        }
                    }
                }
            }

            SignalCell {
                visible: !tray.empty
                Tray {
                    id: tray
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: 14
                }
            }

            // Message count. Renders nothing at zero (§2) unless DND is on.
            SignalCell {
                label: "MSG"
                visible: Notifs.count > 0 || Notifs.dnd
                rule: false
                labelColor: Ui.centreOpen ? Theme.sigHot : Theme.sigLabel
                interactive: true
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        Notifs.dnd = !Notifs.dnd;
                    else
                        Ui.centreOpen = !Ui.centreOpen;
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.dnd ? "DND" : Theme.pad(Notifs.count, 2, "0")
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Notifs.dnd ? Theme.sigWarn : Theme.peach
                }
            }
        }
    }
}
