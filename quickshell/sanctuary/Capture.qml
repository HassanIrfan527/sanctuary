import QtQuick
import Quickshell
import Quickshell.Wayland
import "kit"

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
    // "" while choosing · alarm while recording · warn while paused
    readonly property string liveTone: Rec.scrPaused ? "warn" : Rec.scrActive ? "alarm" : ""

    // ── dim: the screen around the region, its frame, its size ──────
    RegionShade {
        anchors.fill: parent
        visible: win.drawDim
        rx: win.rx
        ry: win.ry
        rw: win.rw
        rh: win.rh
        strong: win.selecting
        tone: win.liveTone
        showSize: win.selecting
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

    ButtonStrip {
        id: strip
        visible: win.stripShown
        x: win.hasRegion ? Math.max(8, Math.min(win.rx - 3, win.width - width - 8))
                         : (win.width - width) / 2
        y: Math.max(0, win.stripY)
        tone: Rec.scrActive ? win.liveTone : ""

        // ── recording: the readout ──
        StripReadout {
            visible: Rec.scrActive
            text: (Rec.scrPaused ? "‖ " : blink.on ? "● " : "○ ") + Rec.clock(Rec.scrMs)
            tone: Rec.scrPaused ? "warn" : "alarm"
        }
        StripButton {
            visible: Rec.scrActive
            text: Rec.scrPaused ? "▶ RESUME" : "‖ PAUSE"
            lit: Rec.scrPaused
            tone: "warn"
            onClicked: Rec.screen(["pause-toggle"])
        }

        // ── choosing: the hint ──
        StripHint {
            visible: win.selecting && !win.hasRegion
            text: "DRAG A REGION"
        }

        // ── both: what goes into the recording ──
        StripButton {
            readonly property bool on: Rec.scrActive ? Rec.scrMic : win.wantMic
            text: on ? "MIC ●" : "MIC ○"
            lit: on
            onClicked: Rec.scrActive ? Rec.screen(["mic", "toggle"]) : win.wantMic = !win.wantMic
        }
        StripButton {
            readonly property bool on: Rec.scrActive ? Rec.scrSys : win.wantSys
            text: on ? "SYS ●" : "SYS ○"
            lit: on
            onClicked: Rec.scrActive ? Rec.screen(["sys", "toggle"]) : win.wantSys = !win.wantSys
        }

        // ── choosing: go ──
        StripButton {
            visible: win.selecting
            text: "FULL"
            onClicked: win.record(true)
        }
        StripButton {
            visible: win.selecting && win.hasRegion
            text: "● REC"
            lit: true
            tone: "alarm"
            onClicked: win.record(false)
        }

        // ── recording: end it ──
        StripButton {
            visible: Rec.scrActive
            text: "■ STOP"
            lit: true
            tone: "alarm"
            onClicked: Rec.screen(["stop"])
        }

        StripButton {
            text: win.selecting ? "✕" : win.confirmDiscard ? "DISCARD?" : "✕"
            lit: win.confirmDiscard
            tone: "alarm"
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

    Timer {
        id: blink
        property bool on: true
        interval: 700
        repeat: true
        running: Rec.scrActive && !Rec.scrPaused
        onTriggered: on = !on
    }
}
