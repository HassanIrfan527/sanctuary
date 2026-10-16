import QtQuick
import Quickshell
import Quickshell.Wayland
import "kit"

// The bar: what you're in, the time, and how the machine is doing — one cell
// per readout, in this order. How it looks (the strip, the cells, the clock)
// is the kit's.
//
//   ◉ │ WS 1 2 3 4 │ WIN kitty · nvim      10:41:07 PM      VC 04 LIVE │ TMR 00:00 │ CPU 12% ╱╲ │ MEM 41% ╱╲ │ MIC LIVE ▮▮▮▯▯ │ ♪ … │ tray │ MSG 03
//
// Every value is fixed-width so nothing shuffles as numbers change.
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
    implicitHeight: Theme.barH
    exclusiveZone: Theme.barH

    WlrLayershell.namespace: "sanctuary-bar"
    WlrLayershell.layer: WlrLayer.Top

    readonly property string output: modelData ? modelData.name : ""

    // Compact (Ui.barCompact, DESK "Compact / extend bar"): no CPU/MEM, no
    // idle ◉ (the live SCR/AUD cells still show), no window title, and the
    // strip shrinks to a centred block (the kit keeps the clock dead centre).
    readonly property bool compact: Ui.barCompact

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    BarStrip {
        id: strip
        compact: bar.compact
        caution: Caution.active

        // ── left ─────────────────────────────────────────────────────
        leftItems: [
            // ── recorders: ◉ opens RIG; while recording it becomes the REC
            // cells instead. SCR is the screen (alarm), AUD is sound (the
            // second voice), and the words say which. Left-click stops,
            // right-click = RIG.
            Row {
                id: recRow
                height: parent.height

                Cell {
                    visible: !Rec.any && !bar.compact
                    interactive: true
                    onClicked: Ui.rigOpen = !Ui.rigOpen
                    Value { size: "glyph"; text: "◉"; tone: Ui.rigOpen ? "hot" : "dim" }
                }
                Cell {
                    visible: Rec.scrActive
                    label: "SCR"
                    labelTone: Rec.scrPaused ? "warn" : "alarm"
                    interactive: true
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            Ui.rigOpen = !Ui.rigOpen;
                        else if (!Rec.scrSaving)
                            Rec.screen(["stop"]);
                    }
                    Value {
                        strong: true
                        text: Rec.scrSaving ? "SAVING" : (Rec.scrPaused ? "‖ " : "● ") + Rec.clock(Rec.scrMs)
                        tone: Rec.scrPaused || Rec.scrSaving ? "warn" : "alarm"
                    }
                }
                Cell {
                    visible: Rec.audActive
                    label: Rec.audSolo ? "AUD·1" : "AUD·2"
                    labelTone: Rec.audPaused ? "warn" : "second"
                    interactive: true
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            Ui.rigOpen = !Ui.rigOpen;
                        else
                            Rec.audio(["stop"]);
                    }
                    Value {
                        strong: true
                        text: (Rec.audPaused ? "‖ " : "● ") + Rec.clock(Rec.audMs)
                        tone: Rec.audPaused ? "warn" : "second"
                    }
                }
            },

            Cell {
                id: wsCell
                label: "WS"
                interactive: true
                onScrolled: wheel => Wm.wheel(wheel)

                Repeater {
                    model: Wm.workspacesOn(bar.output)
                    delegate: WsNumber {
                        required property var modelData
                        text: Theme.pad(modelData.name || modelData.idx, 2, "0")
                        focused: modelData.is_active
                        occupied: Wm.windowCount(modelData.id) > 0
                        urgent: modelData.is_urgent
                        onClicked: Wm.focusWorkspace(modelData.idx)
                    }
                }

                // Mango only: the viewed tag's layout (SCROLL, TILE, GRID …),
                // in label weight so the numbers stay the thing you read.
                // niri has one layout, so it says nothing there.
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: implicitWidth
                    visible: text !== ""
                    role: "tag"
                    text: Wm.layoutOn(bar.output)
                }
            },

            Cell {
                label: "WIN"
                visible: Wm.focusedWindow !== null && !bar.compact
                rule: false
                Value {
                    // Yields to the alert row: never closer than 24px to it.
                    width: Math.max(0, Math.min(implicitWidth, 260,
                                                strip.alertRow.x - strip.leftRow.x - recRow.width - wsCell.width - 70))
                    elide: Text.ElideRight
                    tone: "soft"
                    text: Wm.focusedWindow
                          ? (Wm.focusedWindow.app_id || "?") + "  " + (Wm.focusedWindow.title || "")
                          : ""
                }
            }
        ]

        // ── centre: the clock ────────────────────────────────────────
        centreItem: BarClock {
            date: clock.date
            caution: Caution.active
        }

        // ── left of the clock: what is WRONG, if anything ───────────────
        // The caution lamp nearest the clock, then the exception cells (TEMP,
        // DISK). Both exist only while something is off. The right side is
        // already full, so alarms take space from the window title instead.
        alertItems: [
            // Master Caution, part 3. Click = acknowledge: dark until a NEW
            // reason appears (Caution.qml).
            CautionLamp {
                visible: Caution.active
                text: Caution.text
                onClicked: Caution.acknowledge()
            },
            Repeater {
                model: Sys.exceptions
                delegate: Cell {
                    id: exc
                    required property var modelData
                    label: modelData.label
                    rule: false
                    labelTone: modelData.level === "alarm" ? "alarm" : "warn"
                    interactive: modelData.key === "temp"   // right-click TEMP: btop
                    onClicked: mouse => { if (mouse.button === Qt.RightButton) Sys.btop(); }
                    Value {
                        strong: true
                        text: exc.modelData.value
                        tone: exc.modelData.level === "alarm" ? "alarm" : "warn"
                    }
                }
            }
        ]

        // ── right ────────────────────────────────────────────────────
        rightItems: [
            // Discord voice (Comms.qml): only while you're in a call. People in
            // the room, then YOUR Discord mic — alarm when muted or deafened.
            // Click: the COMMS card. Not the system mic; that's MIC below.
            Cell {
                label: "VC"
                visible: Comms.inCall
                labelTone: Ui.commsOpen ? "hot" : ""
                interactive: true
                onClicked: Ui.commsOpen = !Ui.commsOpen
                Value { text: Theme.pad(Comms.count, 2, "0") }
                Value {
                    strong: true
                    text: Comms.selfDeaf ? "DEAF" : Comms.selfMute ? "MUTE" : "LIVE"
                    tone: Comms.selfMute || Comms.selfDeaf ? "alarm" : "hot"
                }
            },

            // The time tracker (Tracker.qml). Always here, even compact: 00:00
            // dim at rest, hot while running, warn when stopped mid-way.
            // Left: start / stop (stop keeps the time). Right: reset to 00:00.
            Cell {
                label: "TMR"
                labelTone: Tracker.running ? "hot" : ""
                interactive: true
                onClicked: mouse => mouse.button === Qt.RightButton ? Tracker.reset() : Tracker.toggle()
                Value {
                    text: Tracker.text
                    strong: !Tracker.idle
                    tone: Tracker.running ? "hot" : Tracker.idle ? "dim" : "warn"
                }
            },

            // Right-click CPU or MEM: btop, floating (again to close it).
            Cell {
                label: "CPU"
                visible: !bar.compact
                interactive: true
                onClicked: mouse => { if (mouse.button === Qt.RightButton) Sys.btop(); }
                Reading { level: Sys.cpu; text: Sys.pct(Sys.cpu) }
                Trace { level: Sys.cpu; values: Sys.cpuHist }
            },
            Cell {
                label: "MEM"
                visible: !bar.compact
                interactive: true
                onClicked: mouse => { if (mouse.button === Qt.RightButton) Sys.btop(); }
                Reading { level: Sys.mem; text: Sys.pct(Sys.mem) }
                Trace { level: Sys.mem; values: Sys.memHist }
            },

            // Mic: state word + input gain as five cells. Live is hot;
            // muted goes dim.
            Cell {
                label: "MIC"
                visible: Media.micKnown
                labelTone: Media.micOn ? "hot" : ""
                interactive: true
                onClicked: mouse => mouse.button === Qt.RightButton ? Media.toggleMic() : Media.openMixer()
                Value {
                    strong: true
                    text: Media.micOn ? "LIVE" : "MUTE"
                    tone: Media.micOn ? "hot" : "dim"
                }
                Meter {
                    anchors.verticalCenter: parent.verticalCenter
                    segments: 5
                    cellWidth: 3
                    cellHeight: 9
                    value: Media.micVolume
                    off: !Media.micOn
                }
            },

            // Left: play / pause. Right: the player card (Player.qml).
            Cell {
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
                TrackLine {
                    text: Media.title + (Media.artist !== "" ? " — " + Media.artist : "")
                    progress: Media.progress
                }
            },

            Cell {
                visible: !tray.empty
                Tray {
                    id: tray
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: 14
                }
            },

            // Message count. Renders nothing at zero (§2) unless DND is on.
            Cell {
                label: "MSG"
                visible: Notifs.count > 0 || Notifs.dnd
                rule: false
                labelTone: Ui.centreOpen ? "hot" : ""
                interactive: true
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        Notifs.dnd = !Notifs.dnd;
                    else
                        Ui.centreOpen = !Ui.centreOpen;
                }
                Value {
                    strong: true
                    text: Notifs.dnd ? "DND" : Theme.pad(Notifs.count, 2, "0")
                    tone: Notifs.dnd ? "warn" : "second"
                }
            }
        ]
    }
}
