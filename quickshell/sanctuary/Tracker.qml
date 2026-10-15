pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The time tracker: a stopwatch on the bar (the TMR cell). Left-click starts /
// stops it, right-click resets it to 00:00. Stopping keeps the time, so the
// next start carries on from it.
//
// The truth is ~/.local/state/sanctuary/timer.json — { acc_ms, started_ms }:
// time banked by earlier runs, and when the current run began (0 = stopped).
// Because it's a start time, not a counter, a Quickshell restart (or a reboot)
// mid-run loses nothing: the cell comes back still counting.
Singleton {
    id: root

    property real accMs: 0          // banked by earlier runs
    property real startedMs: 0      // epoch ms the current run began; 0 = stopped
    readonly property bool running: startedMs > 0
    readonly property bool idle: !running && accMs === 0   // at 00:00

    property real now: Date.now()
    readonly property real ms: accMs + (running ? Math.max(0, now - startedMs) : 0)

    // 00:00, or 1:03:12 past the hour — the same face as the recorders' clocks.
    readonly property string text: Rec.clock(ms)

    function toggle() {
        now = Date.now();
        if (running) {
            accMs = ms;
            startedMs = 0;
        } else {
            startedMs = now;
        }
        save();
    }
    function reset() {
        accMs = 0;
        startedMs = 0;
        save();
    }

    function save() {
        file.setText(JSON.stringify({ acc_ms: accMs, started_ms: startedMs }));
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/sanctuary/timer.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const s = JSON.parse(file.text());
                root.accMs = Number(s.acc_ms) || 0;
                root.startedMs = Number(s.started_ms) || 0;
            } catch (e) {}
        }
    }

    // Ticks only while running; stopped, nothing on screen changes.
    Timer {
        interval: 1000
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }
}
