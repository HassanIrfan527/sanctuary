pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Both recorders, as the shell sees them. The scripts own the recordings; this
// only READS their state files once a second and SENDS them commands:
//
//   screen  scripts/sanctuary/screenrec.sh   → $XDG_RUNTIME_DIR/screenrec/state.json
//   audio   scripts/sanctuary/meeting-rec.sh → $XDG_RUNTIME_DIR/meeting-rec/state.json
//
// No file = not recording. Because the truth is on disk, a Quickshell restart
// mid-recording loses nothing: the cells come straight back.
Singleton {
    id: root

    readonly property string scripts: Quickshell.env("HOME") + "/.dotfiles/scripts/sanctuary/"
    readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    // ── screen ────────────────────────────────────────────────────────
    property var scr: null          // parsed state.json, or null
    readonly property bool scrActive: scr !== null
    readonly property bool scrPaused: scrActive && scr.state === "paused"
    readonly property bool scrSaving: scrActive && scr.state === "saving"
    readonly property bool scrRegion: scrActive && scr.mode === "region"
    readonly property bool scrMic: scrActive && scr.mic
    readonly property bool scrSys: scrActive && scr.sys
    readonly property real scrMs: elapsed(scr)

    // ── audio ─────────────────────────────────────────────────────────
    property var aud: null
    readonly property bool audActive: aud !== null
    readonly property bool audPaused: audActive && aud.state === "paused"
    readonly property bool audSolo: audActive && aud.solo
    readonly property real audMs: elapsed(aud)

    readonly property bool any: scrActive || audActive

    // Toasts sit top-right on the Overlay layer — inside a recorded region they
    // would be in the video. So a screen recording turns DND on (messages still
    // land in the centre; critical ones still pop), and turns it back off after
    // — but only if it was this that turned it on.
    property bool dndOurs: false
    onScrActiveChanged: {
        if (scrActive && !Notifs.dnd) {
            Notifs.dnd = true;
            dndOurs = true;
        } else if (!scrActive && dndOurs) {
            dndOurs = false;
            Notifs.dnd = false;
        }
    }

    // Debug: fake states, for drawing the cells without recording anything
    // (shell.qml `debug fakeRec`). null = use the real files.
    property var fakeScr: null
    property var fakeAud: null

    property real now: Date.now()

    function elapsed(s) {
        if (!s)
            return 0;
        return s.acc_ms + (s.seg_started_ms > 0 ? Math.max(0, now - s.seg_started_ms) : 0);
    }

    // 03:12, or 1:03:12 past the hour. Fixed width within each range.
    function clock(ms) {
        const t = Math.floor(ms / 1000);
        const h = Math.floor(t / 3600), m = Math.floor(t % 3600 / 60), s = t % 60;
        return (h > 0 ? h + ":" : "") + Theme.pad(m, 2, "0") + ":" + Theme.pad(s, 2, "0");
    }

    function screen(args) {
        Quickshell.execDetached([scripts + "screenrec.sh"].concat(args));
    }
    function audio(args) {
        Quickshell.execDetached([scripts + "meeting-rec.sh"].concat(args));
    }

    function parse(view, fake) {
        if (fake)
            return fake;
        try {
            return JSON.parse(view.text());
        } catch (e) {
            return null;
        }
    }

    FileView {
        id: scrFile
        path: root.runtime + "/screenrec/state.json"
        printErrors: false
        onLoaded: root.scr = root.parse(scrFile, root.fakeScr)
        onLoadFailed: root.scr = root.fakeScr
    }
    FileView {
        id: audFile
        path: root.runtime + "/meeting-rec/state.json"
        printErrors: false
        onLoaded: root.aud = root.parse(audFile, root.fakeAud)
        onLoadFailed: root.aud = root.fakeAud
    }

    // Once a second: two tiny file reads, no processes. Fast enough for a
    // seconds counter; a command's effect shows within a second at worst.
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
    function poll() {
        now = Date.now();
        scrFile.reload();
        audFile.reload();
    }
}
