import QtQuick
import Quickshell
import Quickshell.Io
import "Glyphs.js" as G
import ".."

// KIT · LockFace — Lantern's lock screen: the same place, shutters down for
// the night. (Lock.qml owns the session lock and the password; this is the look.)
//
//   (your wallpaper, in fat pixels, under a dusk wash)
//
//                 ╔══════════════════════════════╗
//                 ║            ☾                 ║
//                 ║          10:41  pm           ║
//                 ║     thursday · 16 october    ║
//                 ║  ┌────────────────────────┐  ║
//                 ║  │ ■ ■ ■ ■ ■         input│  ║
//                 ║  └────────────────────────┘  ║
//                 ║   2 tries · caps lock is on  ║
//                 ║ locked 12m      ✉ +3   ♪ …   ║
//                 ╚══════════════════════════════╝
//
// The colour keeps its job: what you type is pink (you), verifying is amber,
// denied is red and turns the frame red. No motion: nothing breathes, nothing
// sweeps, nothing collapses; the face is simply gone when you're in.
//
// The background is the current still wallpaper drawn at 1/8 size in hard
// pixels — never a screenshot: nothing that was on screen is visible here.
//
// Keys: type · enter submit · backspace · esc / ctrl+u clear (preview: esc on
// an empty field closes it).
Item {
    id: face
    required property var ctl

    readonly property string phase: ctl.phase
    readonly property color stateColor: phase === "denied" ? Theme.lanAlarm
                                 : phase === "verify" ? Theme.lanAmber
                                 : phase === "granted" ? Theme.lanOk
                                 : phase === "input" ? Theme.lanPink : Theme.lanDim
    readonly property string stateWord: phase === "denied" ? "denied"
                                      : phase === "verify" ? "checking"
                                      : phase === "granted" ? "welcome back"
                                      : phase === "input" ? "" : "type your password"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── input ─────────────────────────────────────────────────────────
    focus: true
    Component.onCompleted: forceActiveFocus()
    Keys.onPressed: event => {
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
    // video — then there is just the dusk colour).
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
    Rectangle {
        anchors.fill: parent
        color: Theme.lanSunk
    }
    Image {
        anchors.fill: parent
        source: face.wallPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: false
        sourceSize.width: Math.max(1, Math.round(face.width / 8))
        sourceSize.height: Math.max(1, Math.round(face.height / 8))
    }
    Rectangle {
        anchors.fill: parent
        color: Theme.lanSunk
        opacity: 0.62
    }

    // ── the plaque ────────────────────────────────────────────────────
    Wood {
        id: plaque
        anchors.centerIn: parent
        width: 560
        height: col.implicitHeight + 2 * edge + 48
        thick: 6
        shadow: true
        outline: face.phase === "denied" ? Theme.lanAlarm : Theme.lanOutline

        Column {
            id: col
            anchors.horizontalCenter: parent.horizontalCenter
            y: 24
            width: parent.width - 48
            spacing: 10

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: clock.date.getHours() >= 6 && clock.date.getHours() < 18 ? "sun" : "moon"
                size: 48
                color: Theme.lanAmber
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                LText {
                    id: hm
                    big: true
                    font.pixelSize: Theme.lanBig * 3
                    text: Qt.formatDateTime(clock.date, "h:mm AP").split(" ")[0]
                    color: Theme.lanLamp
                }
                LText {
                    anchors.baseline: hm.baseline
                    text: Qt.formatDateTime(clock.date, "AP").toLowerCase()
                    color: Theme.lanDim
                }
            }
            LText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd · d MMMM").toLowerCase()
                color: Theme.lanText
            }
            Item { width: 1; height: 6 }

            // the key well: one pink pip per character typed
            Rectangle {
                id: well
                width: parent.width
                height: 44
                color: Theme.lanSunk
                Rectangle { width: parent.width; height: 2; color: Qt.rgba(0, 0, 0, 0.28) }
                Rectangle {
                    anchors.fill: parent
                    visible: face.phase === "denied" || face.phase === "verify"
                    color: "transparent"
                    border.width: 2
                    border.color: face.stateColor
                }
                Icon {
                    id: key
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    name: "lock"
                    color: face.phase === "idle" ? Theme.lanDim : face.stateColor
                }
                Row {
                    x: 48
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: Math.min(face.ctl.buffer.length, 28)
                        Rectangle {
                            width: 10
                            height: 14
                            color: face.phase === "verify" ? Theme.lanAmber : Theme.lanPink
                            Rectangle {
                                width: parent.width
                                height: 2
                                color: face.phase === "verify" ? Theme.lanLamp : Theme.lanPinkHi
                            }
                        }
                    }
                }
                LText {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 1
                    text: face.stateWord
                    color: face.stateColor
                }
            }

            // what went wrong, how many tries, caps lock, preview
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                height: 22
                LText {
                    visible: face.ctl.note !== "" && face.phase === "denied"
                    text: G.plain(face.ctl.note.toLowerCase())
                    color: Theme.lanAlarm
                }
                LText {
                    visible: face.ctl.attempts > 0
                    text: face.ctl.attempts + (face.ctl.attempts === 1 ? " try" : " tries")
                    color: Theme.lanDim
                }
                LText {
                    visible: face.ctl.caps
                    text: "caps lock is on"
                    color: Theme.lanWarn
                }
                LText {
                    visible: face.ctl.preview
                    text: "preview · not checked"
                    color: Theme.lanDim
                }
            }

            Rectangle {
                width: parent.width
                height: 2
                color: Theme.lanSunk
            }

            // the quiet line: how long, what's waiting, what's playing
            Item {
                width: parent.width
                height: 26
                LText {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property int m: Math.max(0, Math.floor((clock.date.getTime() - face.ctl.lockedAt) / 60000))
                    text: "locked " + (m < 60 ? m + "m" : Math.floor(m / 60) + "h " + m % 60 + "m")
                    color: Theme.lanDim
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16
                    Row {
                        spacing: 6
                        visible: Media.hasTrack
                        Icon { name: "music"; color: Theme.lanSound }
                        LText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 1
                            width: Math.min(implicitWidth, 200)
                            elide: Text.ElideRight
                            text: G.plain(Media.title)
                        }
                    }
                    Row {
                        id: mail
                        readonly property int fresh: Math.max(0, Notifs.count - face.ctl.msgsAtLock)
                        spacing: 6
                        Icon { name: "mailbox"; color: mail.fresh > 0 ? Theme.lanPink : Theme.lanDim }
                        LText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 1
                            text: mail.fresh > 0 ? "+" + mail.fresh : "0"
                            color: mail.fresh > 0 ? Theme.lanPink : Theme.lanDim
                        }
                    }
                }
            }
        }
    }
}
