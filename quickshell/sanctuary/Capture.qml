import QtQuick
import Quickshell
import Quickshell.Wayland

// The screen recorder's overlay — Ctrl+Print, or SCREEN in RIG.
//
//   1. The screen dims. Drag a region (drag again to redo it). The strip under
//      it has MIC (on) · SYS (off) · FULL · REC · ✕.
//   2. REC: the region stays clear, everything else stays dim, a red frame sits
//      just OUTSIDE the region, the strip becomes ● 03:12 · PAUSE · MIC · SYS ·
//      STOP · ✕. Only the strip takes clicks — work anywhere, dim or not.
//   3. STOP saves (screenrec.sh joins + toasts "Open"). ✕ asks once more.
//
// Nothing drawn here can end up in the video: the dim, the frame and the strip
// are all outside the region, and wf-recorder only captures the region. That is
// also why FULL draws nothing while it records — there is no "outside" — and is
// controlled from the bar's SCR cell, RIG and Ctrl+Print instead.
//
// The recording itself is screenrec.sh's; this reads Rec.scr for its state, so
// a Quickshell restart mid-recording redraws the same region from state.json.
//
//   selecting:  drag  region   enter r  record   f  full screen   m  mic   s  sys   esc  cancel
PanelWindow {
    id: win

    readonly property bool selecting: Ui.captureOpen && !Rec.scrActive
    readonly property bool recRegion: Rec.scrRegion && !Rec.scrSaving

    visible: Ui.captureOpen || Rec.scrActive
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-capture"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: selecting ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // While choosing, the whole screen takes input. While recording, only the
    // strip does; everything else clicks straight through to your windows.
    mask: selecting ? null : recRegion && stripShown ? stripMask : emptyMask
    Region { id: stripMask; item: strip }
    Region { id: emptyMask }

    // A visible surface with an inhibitor keeps swayidle from locking the screen
    // mid-recording — the lock screen would be recorded. Paused = no need.
    IdleInhibitor {
        window: win
        enabled: Rec.scrActive && !Rec.scrPaused
    }

    // ── the region ────────────────────────────────────────────────────
    // While choosing: the drag. While recording: from state.json ("X,Y WxH").
    property int selX: 0
    property int selY: 0
    property int selW: 0
    property int selH: 0
    readonly property var recGeom: {
        const m = Rec.scrActive ? /^(-?\d+),(-?\d+) (\d+)x(\d+)$/.exec(Rec.scr.geom || "") : null;
        return m ? { x: +m[1], y: +m[2], w: +m[3], h: +m[4] } : null;
    }
    readonly property int rx: recGeom ? recGeom.x : selX
    readonly property int ry: recGeom ? recGeom.y : selY
    readonly property int rw: recGeom ? recGeom.w : selW
    readonly property int rh: recGeom ? recGeom.h : selH
    readonly property bool hasRegion: rw > 0 && rh > 0

    // Choices made before REC.
    property bool wantMic: true
    property bool wantSys: false
    // Between pressing REC and screenrec.sh's state appearing: draw nothing,
    // so the first frames of a FULL recording are not of this overlay.
    property bool launching: false
    property bool confirmDiscard: false

    onSelectingChanged: {
        if (selecting) {
            selW = 0;
            selH = 0;
            wantMic = true;
            wantSys = false;
            launching = false;
        }
    }

    Connections {
        target: Rec
        function onScrActiveChanged() {
            if (Rec.scrActive) {
                Ui.captureOpen = false;
                win.launching = false;
            }
        }
    }

    function record(full) {
        if (!full && !hasRegion)
            return;
        launching = true;
        const args = ["start", "--mic", wantMic ? "1" : "0", "--sys", wantSys ? "1" : "0"];
        if (full)
            args.push("--full");
        else
            args.push("--geom", rx + "," + ry + " " + rw + "x" + rh);
        startArgs = args;
        startDelay.restart();
    }
    property var startArgs: []
    // One frame's grace for the overlay to vanish (FULL) before capture starts.
    Timer {
        id: startDelay
        interval: 120
        onTriggered: {
            Rec.screen(win.startArgs);
            giveUp.restart();
        }
    }
    // screenrec.sh toasts its own failure; just get out of the way.
    Timer {
        id: giveUp
        interval: 4000
        onTriggered: if (!Rec.scrActive) {
            Ui.captureOpen = false;
            win.launching = false;
        }
    }
    Timer {
        id: discardArm
        interval: 2500
        onTriggered: win.confirmDiscard = false
    }

    function cancel() {
        Ui.captureOpen = false;
    }

    readonly property bool drawDim: !launching && (selecting || recRegion)
    readonly property color frameColor: Rec.scrPaused ? Theme.yellow
                                      : Rec.scrActive ? Theme.red
                                      : Theme.signal ? Theme.sigHot : Theme.inkLine

    // ── dim: four slabs around the region (or one, before there is one) ──
    Item {
        anchors.fill: parent
        visible: win.drawDim
        readonly property color shade: Qt.rgba(0, 0, 0, win.selecting ? 0.5 : 0.42)

        Rectangle {   // whole screen, until a region exists
            anchors.fill: parent
            visible: !win.hasRegion
            color: parent.shade
        }
        Rectangle {   // above
            visible: win.hasRegion
            width: parent.width
            height: win.ry
            color: parent.shade
        }
        Rectangle {   // below
            visible: win.hasRegion
            y: win.ry + win.rh
            width: parent.width
            height: parent.height - y
            color: parent.shade
        }
        Rectangle {   // left
            visible: win.hasRegion
            y: win.ry
            width: win.rx
            height: win.rh
            color: parent.shade
        }
        Rectangle {   // right
            visible: win.hasRegion
            x: win.rx + win.rw
            y: win.ry
            width: parent.width - x
            height: win.rh
            color: parent.shade
        }

        // The frame: 2px, one pixel clear of the region on every side.
        Rectangle {
            visible: win.hasRegion
            x: win.rx - 3
            y: win.ry - 3
            width: win.rw + 6
            height: win.rh + 6
            color: "transparent"
            border.width: 2
            border.color: win.frameColor
        }

        // Size readout while choosing, outside the top-left corner.
        Text {
            visible: win.selecting && win.hasRegion
            x: Math.max(4, win.rx - 3)
            y: win.ry - 3 - height - 4 >= 0 ? win.ry - 3 - height - 4 : win.ry + win.rh + 6
            text: win.rw + " × " + win.rh
            font.family: Theme.mono
            font.pixelSize: 10
            color: "#ffffff"
        }
    }

    // ── choosing: drag a region ───────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        enabled: win.selecting && !win.launching
        cursorShape: Qt.CrossCursor
        property int ox: 0
        property int oy: 0
        onPressed: mouse => {
            ox = mouse.x;
            oy = mouse.y;
            win.selW = 0;
            win.selH = 0;
        }
        onPositionChanged: mouse => {
            const x0 = Math.max(0, Math.min(ox, mouse.x)), y0 = Math.max(0, Math.min(oy, mouse.y));
            const x1 = Math.min(win.width, Math.max(ox, mouse.x)), y1 = Math.min(win.height, Math.max(oy, mouse.y));
            win.selX = Math.round(x0);
            win.selY = Math.round(y0);
            // H.264 wants even sizes.
            win.selW = Math.floor((x1 - x0) / 2) * 2;
            win.selH = Math.floor((y1 - y0) / 2) * 2;
        }
        onReleased: {
            if (win.selW < 16 || win.selH < 16) {   // a click, not a drag
                win.selW = 0;
                win.selH = 0;
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: win.selecting
        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape || k === Qt.Key_Q)
                win.cancel();
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_R)
                win.record(false);
            else if (k === Qt.Key_F)
                win.record(true);
            else if (k === Qt.Key_M)
                win.wantMic = !win.wantMic;
            else if (k === Qt.Key_S)
                win.wantSys = !win.wantSys;
            else
                return;
            event.accepted = true;
        }
    }

    // ── the strip ─────────────────────────────────────────────────────
    // Under the region if it fits, else above it, else (a region that fills
    // the screen) nowhere: the bar's SCR cell and the keys still work.
    readonly property int stripGap: 12
    readonly property int stripY: {
        if (!hasRegion)
            return height - strip.height - 60;
        const below = ry + rh + 3 + stripGap;
        if (below + strip.height <= height - 4)
            return below;
        const above = ry - 3 - stripGap - strip.height;
        return above >= 4 ? above : -1;
    }
    readonly property bool stripShown: !launching && (selecting || recRegion) && stripY >= 0

    Item {
        id: strip
        visible: win.stripShown
        x: win.hasRegion ? Math.max(8, Math.min(win.rx - 3, win.width - width - 8))
                         : (win.width - width) / 2
        y: Math.max(0, win.stripY)
        width: row.implicitWidth + (Theme.signal ? 2 : 0)
        height: (Theme.signal ? 32 : 30) + (Theme.signal ? 2 : 0)

        // Signal: a strip like the bar's. Ink: the buttons float as panels.
        Rectangle {
            visible: Theme.signal
            anchors.fill: parent
            color: Theme.sigFill
            border.width: 1
            border.color: Rec.scrActive ? win.frameColor : Theme.sigRule
        }

        MouseArea {   // the strip is not part of the drag area
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Row {
            id: row
            x: Theme.signal ? 1 : 0
            y: Theme.signal ? 1 : 0
            spacing: Theme.signal ? 0 : 8

            // ── recording: the readout ──
            Item {
                visible: Rec.scrActive
                width: readout.implicitWidth + 24
                height: Theme.signal ? 32 : 30
                Rectangle {
                    visible: Theme.ink
                    anchors.fill: parent
                    color: Rec.scrPaused ? Theme.yellow : Theme.red
                    border.width: 2
                    border.color: Theme.inkLine
                }
                Text {
                    id: readout
                    anchors.centerIn: parent
                    text: (Rec.scrPaused ? "‖ " : blink.on ? "● " : "○ ") + Rec.clock(Rec.scrMs)
                    font.family: Theme.mono
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.ink ? Theme.crust : Rec.scrPaused ? Theme.sigWarn : Theme.sigAlarm
                }
                Rectangle {
                    visible: Theme.signal
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height - 12
                    color: Theme.sigRule
                }
            }
            CapButton {
                visible: Rec.scrActive
                text: Rec.scrPaused ? "▶ RESUME" : "‖ PAUSE"
                lit: Rec.scrPaused
                hot: Theme.yellow
                onClicked: Rec.screen(["pause-toggle"])
            }

            // ── choosing: the hint ──
            Item {
                visible: win.selecting && !win.hasRegion
                width: hint.implicitWidth + 24
                height: Theme.signal ? 32 : 30
                Text {
                    id: hint
                    anchors.centerIn: parent
                    text: "DRAG A REGION"
                    font.family: Theme.signal ? Theme.mono : Theme.sans
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: Theme.signal ? Theme.sigValue : "#ffffff"
                }
            }

            // ── both: what goes into the recording ──
            CapButton {
                readonly property bool on: Rec.scrActive ? Rec.scrMic : win.wantMic
                text: on ? "MIC ●" : "MIC ○"
                lit: on
                onClicked: Rec.scrActive ? Rec.screen(["mic", "toggle"]) : win.wantMic = !win.wantMic
            }
            CapButton {
                readonly property bool on: Rec.scrActive ? Rec.scrSys : win.wantSys
                text: on ? "SYS ●" : "SYS ○"
                lit: on
                onClicked: Rec.scrActive ? Rec.screen(["sys", "toggle"]) : win.wantSys = !win.wantSys
            }

            // ── choosing: go ──
            CapButton {
                visible: win.selecting
                text: "FULL"
                onClicked: win.record(true)
            }
            CapButton {
                visible: win.selecting && win.hasRegion
                text: "● REC"
                lit: true
                hot: Theme.red
                onClicked: win.record(false)
            }

            // ── recording: end it ──
            CapButton {
                visible: Rec.scrActive
                text: "■ STOP"
                lit: true
                hot: Theme.red
                onClicked: Rec.screen(["stop"])
            }

            CapButton {
                text: win.selecting ? "✕" : win.confirmDiscard ? "DISCARD?" : "✕"
                lit: win.confirmDiscard
                hot: Theme.red
                rule: false
                onClicked: {
                    if (win.selecting) {
                        win.cancel();
                    } else if (win.confirmDiscard) {
                        win.confirmDiscard = false;
                        Rec.screen(["discard"]);
                    } else {
                        win.confirmDiscard = true;
                        discardArm.restart();
                    }
                }
            }
        }
    }

    Timer {
        id: blink
        property bool on: true
        interval: 700
        repeat: true
        running: Rec.scrActive && !Rec.scrPaused
        onTriggered: on = !on
    }
}
