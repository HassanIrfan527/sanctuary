import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// The lock screen. A real ext-session-lock (WlSessionLock): niri itself keeps
// the session locked until THIS unlocks it — if Quickshell dies mid-lock the
// screen goes red and stays locked, it never falls open.
//
// Reached the same way as before: Mod+Escape / idle / suspend → logind Lock →
// swayidle → scripts/sanctuary/lock.sh, which asks this first and falls back to
// swaylock. Rescue on a dead or red lock: Mod+Alt+Escape (allowed while locked)
// → `lock.sh rescue` → swaylock takes the lock over. Also automatic: shell.sh's
// watcher starts swaylock if Quickshell dies while $XDG_RUNTIME_DIR/sanctuary-lock
// exists (written by lock.sh, removed here on unlock).
//
// Password: PAM, service "swaylock" (/etc/pam.d/swaylock → login), the same
// stack swaylock has always used here.
//
// The face is LockSignal.qml (every style, for now — Ink/Paper get theirs later).
//
//   qs.sh call lock lock        lock now (lock.sh does this)
//   qs.sh call lock secure      true once niri confirms the lock
//   qs.sh call lock preview     the face in a normal overlay window — NO lock, NO
//                               PAM (any key "fails"); esc closes. For screenshots.
Scope {
    id: root

    property bool preview: false
    readonly property bool engaged: lock.locked || preview

    // ── what the face draws ───────────────────────────────────────────
    property string buffer: ""
    property string phase: "idle"     // idle · input · verify · denied · granted
    property int attempts: 0
    property string note: ""
    property real lockedAt: 0
    property int msgsAtLock: 0
    property bool caps: false

    readonly property string flag: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/sanctuary-lock"

    function engage() {
        if (lock.locked)
            return;
        reset();
        lockedAt = Date.now();
        msgsAtLock = Notifs.count;
        lock.locked = true;
    }

    function openPreview() {
        if (lock.locked)
            return;
        reset();
        lockedAt = Date.now() - 754000;
        msgsAtLock = Math.max(0, Notifs.count - 3);
        preview = true;
    }

    function reset() {
        buffer = "";
        phase = "idle";
        attempts = 0;
        note = "";
        caps = false;
    }

    function type(t) {
        if (phase === "verify" || phase === "granted")
            return;
        buffer += t;
        phase = "input";
    }
    function backspace() {
        if (phase === "verify" || phase === "granted")
            return;
        buffer = buffer.slice(0, -1);
        phase = buffer === "" ? "idle" : "input";
    }
    function clear() {
        if (phase === "verify" || phase === "granted")
            return;
        buffer = "";
        phase = "idle";
    }

    function submit() {
        if (phase === "verify" || phase === "granted" || buffer === "")
            return;
        phase = "verify";
        if (preview) {             // never authenticate from the preview
            previewVerdict.restart();
            return;
        }
        if (!pam.start())
            fail("PAM DID NOT START");
    }

    function fail(why) {
        attempts += 1;
        note = why;
        buffer = "";
        phase = "denied";
        settle.restart();
    }

    function grant() {
        phase = "granted";
        release.restart();       // let the collapse play, then unlock
    }

    PamContext {
        id: pam
        config: "swaylock"
        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.buffer);
        }
        onCompleted: result => {
            if (result === PamResult.Success)
                root.grant();
            else
                root.fail(result === PamResult.MaxTries ? "TOO MANY TRIES" : "WRONG KEY");
        }
        onError: error => root.fail("PAM ERROR")
    }

    Timer {   // denied → back to listening
        id: settle
        interval: 1500
        onTriggered: if (root.phase === "denied") root.phase = root.buffer === "" ? "idle" : "input"
    }
    Timer {
        id: release
        interval: 560
        onTriggered: {
            root.buffer = "";
            if (root.preview) {
                root.preview = false;
                return;
            }
            lock.locked = false;
            Quickshell.execDetached(["rm", "-f", root.flag]);
        }
    }
    Timer {
        id: previewVerdict
        interval: 900
        onTriggered: root.fail("PREVIEW — NOT CHECKED")
    }

    WlSessionLock {
        id: lock
        WlSessionLockSurface {
            color: Theme.crust
            LockSignal {
                anchors.fill: parent
                ctl: root
            }
        }
    }

    LazyLoader {
        active: root.preview
        PanelWindow {
            color: Theme.crust
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "sanctuary-lock-preview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            LockSignal {
                anchors.fill: parent
                ctl: root
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.engage(); }
        function isLocked(): bool { return lock.locked; }
        function secure(): bool { return lock.secure; }
        function preview(): void { root.preview ? root.preview = false : root.openPreview(); }
        // preview only: put text in the field / press enter, for screenshots
        function previewType(t: string): void { if (root.preview) root.type(t); }
        function previewEnter(): void { if (root.preview) root.submit(); }
        function previewGrant(): void { if (root.preview) root.grant(); }
    }
}
