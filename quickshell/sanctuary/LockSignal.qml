import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

// Signal's lock face — the instrument panel, powered down to STANDBY.
//
//   ┌ SANCTUARY · CITADEL ─────── ● SESSION LOCKED ─────── LOCKED 00:12:41 ┐
//   │                                                                     │
//   │                          09:41:07                                   │
//   │                          ─────────── (the minute, filling)          │
//   │                      MONDAY · 05 OCTOBER 2026                       │
//   │                                                                     │
//   │            ┌ KEY ▮▮▮▮▮▮▮▯▯▯▯▯▯▯▯▯▯▯▯▯              INPUT ┐          │
//   │                       attempts · caps                               │
//   │  ╱╲╱‾‾╲__╱╲ (the CPU trace, scope-sized, very faint)                │
//   └ CPU 12% ╱╲ │ MEM 41% ╱╲ │ MIC LIVE │ SCR ● │ MSG +3 ┘
//
// Colour is state, as everywhere in Signal: green listening, yellow verifying,
// red denied. Wrong key shakes the panel; the right one collapses the screen to
// a line like a CRT switching off, then unlocks.
//
// The background is the current still wallpaper, blurred hard and pushed under
// crust — never a screenshot: nothing that was on screen is visible here.
//
// Keys: type · enter submit · backspace · esc / ctrl+u clear (preview: esc on an
// empty field closes it).
Item {
    id: face
    required property var ctl

    readonly property string phase: ctl.phase
    readonly property color state: phase === "denied" ? Theme.sigAlarm
                                 : phase === "verify" ? Theme.sigWarn
                                 : Theme.sigHot
    readonly property string stateWord: phase === "denied" ? "DENIED"
                                      : phase === "verify" ? "VERIFY"
                                      : phase === "granted" ? "GRANTED"
                                      : phase === "input" ? "INPUT" : "STANDBY"

    property real lastKey: Date.now()
    readonly property bool resting: phase === "idle" && clock.date.getTime() - lastKey > 20000

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // ── input ─────────────────────────────────────────────────────────
    focus: true
    Component.onCompleted: forceActiveFocus()
    Keys.onPressed: event => {
        lastKey = Date.now();
        const k = event.key;
        const ctrl = event.modifiers & Qt.ControlModifier;
        if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            ctl.submit();
        } else if (k === Qt.Key_Backspace) {
            ctrl ? ctl.clear() : ctl.backspace();
        } else if (k === Qt.Key_Escape || (ctrl && k === Qt.Key_U)) {
            if (ctl.preview && ctl.buffer === "")
                ctl.preview = false;
            else
                ctl.clear();
        } else if (!ctrl && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
            // Caps Lock, inferred: a letter whose case disagrees with Shift.
            const t = event.text;
            if (t.toLowerCase() !== t.toUpperCase()) {
                const upper = t === t.toUpperCase();
                const shift = !!(event.modifiers & Qt.ShiftModifier);
                ctl.caps = upper !== shift;
            }
            ctl.type(t);
        } else {
            return;
        }
        event.accepted = true;
    }

    // ── background ────────────────────────────────────────────────────
    // wallpaper.sh keeps the current still's path here (a live wallpaper is a
    // video — then there is just crust).
    FileView {
        id: wallFile
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/sanctuary/wallpaper"
        printErrors: false
        onLoaded: {
            const p = wallFile.text().trim();
            face.wallPath = /\.(png|jpe?g|webp|bmp)$/i.test(p) ? "file://" + p : "";
        }
    }
    property string wallPath: ""
    Image {
        id: wallImg
        anchors.fill: parent
        source: face.wallPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        sourceSize.width: 960          // blurred anyway: half size is plenty
    }
    MultiEffect {
        anchors.fill: parent
        source: wallImg
        visible: wallImg.status === Image.Ready
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        saturation: -0.5
        brightness: -0.1
    }
    Rectangle {
        anchors.fill: parent
        color: Theme.crust
        opacity: 0.82
    }
    // Scan lines: every third pixel, barely there. Drawn once.
    Canvas {
        anchors.fill: parent
        opacity: 0.35
        onPaint: {
            const c = getContext("2d");
            c.reset();
            c.fillStyle = "#000000";
            for (let y = 0; y < height; y += 3)
                c.fillRect(0, y, width, 1);
        }
    }

    // ── everything that powers on / off ───────────────────────────────
    Item {
        id: panel
        anchors.fill: parent
        transformOrigin: Item.Center

        // Power-on: the frame closes in from wide, everything fades up.
        // Granted: the CRT collapse — squash to a line, then out.
        property real boot: 0
        Component.onCompleted: bootAnim.start()
        NumberAnimation {
            id: bootAnim
            target: panel
            property: "boot"
            from: 0
            to: 1
            duration: 520
            easing.type: Easing.OutCubic
        }
        property real fade: 1
        opacity: Math.min(1, boot * 1.4) * fade

        property real yScale: 1
        transform: Scale {
            origin.x: panel.width / 2
            origin.y: panel.height / 2
            yScale: panel.yScale
        }
        SequentialAnimation {
            id: collapse
            NumberAnimation { target: panel; property: "yScale"; to: 0.004; duration: 300; easing.type: Easing.InCubic }
            NumberAnimation { target: panel; property: "fade"; to: 0; duration: 160 }
        }
        Connections {
            target: face.ctl
            function onPhaseChanged() {
                if (face.ctl.phase === "granted")
                    collapse.restart();
            }
        }

        // The frame + registration marks.
        readonly property int inset: 28 + Math.round((1 - boot) * 90)
        Rectangle {
            x: panel.inset
            y: panel.inset
            width: parent.width - panel.inset * 2
            height: parent.height - panel.inset * 2
            color: "transparent"
            border.width: 1
            border.color: Theme.sigRule
        }
        SignalTicks {
            x: panel.inset - 4
            y: panel.inset - 4
            width: parent.width - panel.inset * 2 + 8
            height: parent.height - panel.inset * 2 + 8
            len: 22
            w: 2
            color: face.state
            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }

        // ── top strip ──
        Item {
            id: top
            x: panel.inset + 1
            y: panel.inset + 1
            width: parent.width - panel.inset * 2 - 2
            height: 40
            opacity: face.resting ? 0.35 : 1
            Behavior on opacity { NumberAnimation { duration: 600 } }

            Row {
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Text {
                    text: "SANCTUARY"
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 3
                    color: Theme.sigHot
                }
                Text {
                    text: "· " + (Quickshell.env("HOSTNAME") || "citadel").toUpperCase() + " · " + (Quickshell.env("USER") || "").toUpperCase()
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    color: Theme.sigLabel
                }
            }
            Row {
                anchors.centerIn: parent
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 6
                    radius: 3
                    color: face.state
                    opacity: beat.on ? 1 : 0.25
                }
                Text {
                    text: face.ctl.preview ? "PREVIEW — NOT LOCKED" : "SESSION LOCKED"
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 3
                    color: Theme.sigValue
                }
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                    text: "LOCKED"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 1.4
                    color: Theme.sigLabel
                }
                Text {
                    readonly property int s: Math.max(0, Math.floor((clock.date.getTime() - face.ctl.lockedAt) / 1000))
                    text: Theme.pad(Math.floor(s / 3600), 2, "0") + ":" + Theme.pad(Math.floor(s % 3600 / 60), 2, "0")
                          + ":" + Theme.pad(s % 60, 2, "0")
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.sigValue
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.sigRule
            }
        }

        // ── the clock ──
        Column {
            id: clockCol
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.25
            spacing: 14

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    id: hm
                    text: Qt.formatDateTime(clock.date, "hh:mm AP").slice(0, 5)
                    font.family: Theme.mono
                    font.pixelSize: 168
                    font.weight: Font.Light
                    font.letterSpacing: -4
                    color: Theme.sigValue
                }
                Text {
                    anchors.baseline: hm.baseline
                    leftPadding: 10
                    text: Qt.formatDateTime(clock.date, "ss")
                    font.family: Theme.mono
                    font.pixelSize: 44
                    font.weight: Font.Light
                    color: Theme.sigHot
                }
                Text {
                    anchors.baseline: hm.baseline
                    leftPadding: 10
                    text: Qt.formatDateTime(clock.date, "AP")
                    font.family: Theme.mono
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    color: Theme.sigLabel
                }
            }
            // The minute as a meter: a hairline that fills with the seconds.
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: hm.width
                height: 9
                Rectangle {
                    y: 4
                    width: parent.width
                    height: 1
                    color: Theme.sigRule
                }
                Rectangle {
                    y: 4
                    width: parent.width * clock.date.getSeconds() / 59
                    height: 1
                    color: Theme.sigHot
                    Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                }
                Repeater {   // ticks at every 15 s
                    model: 5
                    delegate: Rectangle {
                        required property int index
                        x: Math.min(parent.width - 1, parent.width * index / 4)
                        width: 1
                        height: 9
                        color: Theme.surface1
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd · dd MMMM yyyy").toUpperCase()
                font.family: Theme.mono
                font.pixelSize: 13
                font.letterSpacing: 5
                color: Theme.sigLabel
            }
        }

        // ── the key panel ──
        Item {
            id: keyWrap
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.6
            width: 560
            height: 52
            opacity: face.resting ? 0.3 : 1
            Behavior on opacity { NumberAnimation { duration: 600 } }

            // Wrong key: a shake. The panel moves, the frame stays.
            property real shake: 0
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: keyWrap; property: "shake"; to: -14; duration: 50 }
                NumberAnimation { target: keyWrap; property: "shake"; to: 12; duration: 70 }
                NumberAnimation { target: keyWrap; property: "shake"; to: -8; duration: 60 }
                NumberAnimation { target: keyWrap; property: "shake"; to: 5; duration: 60 }
                NumberAnimation { target: keyWrap; property: "shake"; to: 0; duration: 60 }
            }
            Connections {
                target: face.ctl
                function onPhaseChanged() {
                    if (face.ctl.phase === "denied")
                        shakeAnim.restart();
                }
            }

            Rectangle {
                id: keyBox
                x: keyWrap.shake
                width: parent.width
                height: parent.height
                color: Qt.rgba(0.07, 0.07, 0.11, 0.92)
                border.width: 1
                border.color: face.phase === "denied" ? Theme.sigAlarm
                            : face.phase === "idle" ? Theme.sigRule : Qt.darker(face.state, 1.6)
                Behavior on border.color { ColorAnimation { duration: Theme.duration } }

                SignalTicks {
                    anchors.fill: parent
                    anchors.margins: -4
                    len: 9
                    color: face.state
                }

                Text {
                    id: keyLabel
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "KEY"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    color: face.phase === "idle" ? Theme.sigLabel : face.state
                }

                // The slots: one cell per character, 24 of them; past that a
                // +N count. While verifying a light runs along them.
                Row {
                    id: slots
                    x: keyLabel.x + keyLabel.implicitWidth + 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: 24
                        delegate: Rectangle {
                            required property int index
                            readonly property bool filled: index < face.ctl.buffer.length
                            readonly property bool runner: face.phase === "verify"
                                                           && Math.abs(index - sweep.pos) < 1.5
                            width: 11
                            height: 18
                            color: face.phase === "denied" ? Qt.rgba(0.95, 0.55, 0.66, 0.22)
                                 : face.phase === "granted" ? Theme.sigHot
                                 : runner ? Theme.sigWarn
                                 : face.phase === "verify" ? Qt.rgba(0.98, 0.89, 0.69, 0.18)
                                 : filled ? Theme.sigHot : Theme.surface0
                            Behavior on color { ColorAnimation { duration: 90 } }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: face.ctl.buffer.length > 24
                        text: "+" + (face.ctl.buffer.length - 24)
                        font.family: Theme.mono
                        font.pixelSize: 10
                        color: Theme.sigHot
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: face.stateWord
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    color: face.phase === "idle" ? Theme.sigLabel : face.state
                }
            }

            // Below the panel: what went wrong, how many times, caps lock.
            Row {
                anchors.top: keyBox.bottom
                anchors.topMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                Text {
                    visible: face.ctl.note !== "" && face.phase === "denied"
                    text: "▲ " + face.ctl.note
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.6
                    color: Theme.sigAlarm
                }
                Text {
                    visible: face.ctl.attempts > 0
                    text: "ATTEMPTS " + Theme.pad(face.ctl.attempts, 2, "0")
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.6
                    color: Theme.sigLabel
                }
                Text {
                    visible: face.ctl.caps
                    text: "CAPS LOCK"
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.6
                    color: Theme.sigWarn
                }
                Text {
                    visible: face.phase === "idle" && face.ctl.attempts === 0 && !face.ctl.caps
                    text: "type to unlock · esc clear"
                    font.family: Theme.mono
                    font.pixelSize: 10
                    color: Theme.surface2
                }
            }
        }

        // ── the scope: the CPU trace, screen-wide and faint ──
        Canvas {
            id: scope
            x: panel.inset + 1
            width: parent.width - panel.inset * 2 - 2
            y: parent.height * 0.74
            height: 120
            opacity: 0.5
            property var values: Sys.cpuHist
            onValuesChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                const v = values || [];
                // grid: a hairline every 10%
                c.strokeStyle = Theme.sigRule;
                c.globalAlpha = 0.5;
                c.lineWidth = 1;
                c.beginPath();
                c.moveTo(0, height - 0.5);
                c.lineTo(width, height - 0.5);
                c.stroke();
                if (v.length < 2)
                    return;
                const dx = width / (v.length - 1);
                const yOf = s => height - 2 - Math.max(0, Math.min(1, s)) * (height - 4);
                c.globalAlpha = 0.08;
                c.fillStyle = Theme.sigHot;
                c.beginPath();
                c.moveTo(0, height);
                for (let i = 0; i < v.length; i++)
                    c.lineTo(i * dx, yOf(v[i]));
                c.lineTo(width, height);
                c.closePath();
                c.fill();
                c.globalAlpha = 0.45;
                c.strokeStyle = Theme.sigHot;
                c.lineWidth = 1.2;
                c.beginPath();
                for (let i = 0; i < v.length; i++)
                    i === 0 ? c.moveTo(0, yOf(v[0])) : c.lineTo(i * dx, yOf(v[i]));
                c.stroke();
            }
            Text {
                x: 18
                y: -16
                text: "CPU · " + Sys.pct(Sys.cpu)
                font.family: Theme.mono
                font.pixelSize: 9
                font.letterSpacing: 1.4
                color: Theme.surface2
            }
        }

        // ── bottom strip: the bar's readouts, read-only ──
        Rectangle {
            id: bottom
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - panel.inset - height - 18
            width: cells.implicitWidth + 2
            height: Theme.sigStripH
            color: Theme.sigFill
            border.width: 1
            border.color: Theme.sigRule
            opacity: face.resting ? 0.35 : 1
            Behavior on opacity { NumberAnimation { duration: 600 } }

            Row {
                id: cells
                x: 1
                height: parent.height

                SignalCell {
                    label: "CPU"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Sys.pct(Sys.cpu)
                        font.family: Theme.mono
                        font.pixelSize: 11
                        color: Theme.sigValue
                    }
                    Sparkline {
                        anchors.verticalCenter: parent.verticalCenter
                        values: Sys.cpuHist
                    }
                }
                SignalCell {
                    label: "MEM"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Sys.pct(Sys.mem)
                        font.family: Theme.mono
                        font.pixelSize: 11
                        color: Theme.sigValue
                    }
                }
                // Mic matters most here: a live mic on a locked desk is worth seeing.
                SignalCell {
                    label: "MIC"
                    visible: Media.micKnown
                    labelColor: Media.micOn ? Theme.sigHot : Theme.sigLabel
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Media.micOn ? "LIVE" : "MUTE"
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Media.micOn ? Theme.sigHot : Theme.surface2
                    }
                }
                SignalCell {
                    visible: Rec.scrActive
                    label: "SCR"
                    labelColor: Theme.sigAlarm
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (Rec.scrPaused ? "‖ " : "● ") + Rec.clock(Rec.scrMs)
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Rec.scrPaused ? Theme.sigWarn : Theme.sigAlarm
                    }
                }
                SignalCell {
                    visible: Rec.audActive
                    label: Rec.audSolo ? "AUD·1" : "AUD·2"
                    labelColor: Theme.peach
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (Rec.audPaused ? "‖ " : "● ") + Rec.clock(Rec.audMs)
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Rec.audPaused ? Theme.sigWarn : Theme.peach
                    }
                }
                SignalCell {
                    visible: Media.hasTrack
                    label: Media.playing ? "PLAY" : "HOLD"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 220)
                        elide: Text.ElideRight
                        text: Media.title + (Media.artist !== "" ? " — " + Media.artist : "")
                        font.family: Theme.mono
                        font.pixelSize: 10
                        color: Theme.sigValue
                    }
                }
                // What arrived while you were away.
                SignalCell {
                    id: msgCell
                    readonly property int fresh: Math.max(0, Notifs.count - face.ctl.msgsAtLock)
                    label: "MSG"
                    rule: false
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: msgCell.fresh > 0 ? "+" + Theme.pad(msgCell.fresh, 2, "0") : "00"
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: msgCell.fresh > 0 ? Theme.peach : Theme.surface2
                    }
                }
            }
        }
    }

    // A dot that breathes: one beat a second.
    Timer {
        id: beat
        property bool on: true
        interval: 1000
        repeat: true
        running: true
        onTriggered: on = !on
    }
    // The verify runner: a light moving along the slots.
    Item {
        id: sweep
        property real pos: -2
        NumberAnimation on pos {
            running: face.phase === "verify"
            from: -2
            to: 26
            duration: 700
            loops: Animation.Infinite
        }
    }
}
