import QtQuick
import "kit"

// RIG — the recorders, Mod+U (or click the ◉ cell on the bar). One letter per
// action, so it is two keypresses and never a menu to walk (DESIGN-BRIEF §1).
// Rows change with what is running:
//
//   idle          S  SCREEN      drag a region · mic on, sys off
//                 M  MEETING     you + them, two files
//                 P  PRACTICE    mic only
//   screen on     S  STOP SCREEN 03:12          D  PAUSE / RESUME SCREEN
//   audio on      M  STOP AUDIO  41:05          P  PAUSE / RESUME AUDIO
//
//   letter  act     j k ↑ ↓  move     enter  act     esc q  close
Popup {
    id: win

    name: "rig"
    open: Ui.rigOpen
    onDismissed: Ui.rigOpen = false
    cardWidth: 400
    count: rows.length
    tabMoves: true
    numberKeys: false
    onChosen: i => run(rows[i].act)
    onKeyPressed: event => {
        const row = rows.find(r => r.key === event.text.toUpperCase());
        if (row) {
            run(row.act);
            event.accepted = true;
        }
    }

    // key: the letter · name/desc: the words · state: "alarm" = recording,
    // "warn" = paused / saving, "" = idle · act: what it does.
    readonly property var rows: {
        const r = [];
        if (!Rec.scrActive) {
            r.push({ key: "S", name: "SCREEN", desc: "drag a region · mic on, sys off", state: "", act: "screen" });
        } else if (Rec.scrSaving) {
            r.push({ key: "S", name: "SAVING", desc: "joining the recording…", state: "warn", act: "" });
        } else {
            r.push({ key: "S", name: "STOP SCREEN", desc: Rec.clock(Rec.scrMs) + " · saves to Videos/Recordings", state: "alarm", act: "scr-stop" });
            r.push({ key: "D", name: Rec.scrPaused ? "RESUME SCREEN" : "PAUSE SCREEN", desc: Rec.scrPaused ? "paused" : "Ctrl+Alt+Print", state: Rec.scrPaused ? "warn" : "", act: "scr-pause" });
        }
        if (!Rec.audActive) {
            r.push({ key: "M", name: "MEETING", desc: "you + them, two files", state: "", act: "meeting" });
            r.push({ key: "P", name: "PRACTICE", desc: "mic only", state: "", act: "practice" });
        } else {
            r.push({ key: "M", name: "STOP AUDIO", desc: Rec.clock(Rec.audMs) + (Rec.audSolo ? " · practice" : " · meeting"), state: "alarm", act: "aud-stop" });
            r.push({ key: "P", name: Rec.audPaused ? "RESUME AUDIO" : "PAUSE AUDIO", desc: Rec.audPaused ? "paused" : "stop joins the parts", state: Rec.audPaused ? "warn" : "", act: "aud-pause" });
        }
        return r;
    }

    onVisibleChanged: if (visible) cursor = 0

    function run(act) {
        if (act === "")
            return;
        Ui.rigOpen = false;
        if (act === "screen")
            Ui.captureOpen = true;
        else if (act === "scr-stop")
            Rec.screen(["stop"]);
        else if (act === "scr-pause")
            Rec.screen(["pause-toggle"]);
        else if (act === "meeting")
            Rec.audio(["start"]);
        else if (act === "practice")
            Rec.audio(["start", "--solo"]);
        else if (act === "aud-stop")
            Rec.audio(["stop"]);
        else if (act === "aud-pause")
            Rec.audio(["pause-toggle"]);
    }

    Panel {
        width: parent.width
        title: "RIG"
        tone: Rec.any ? "alarm" : ""
        detailTone: tone
        detail: Rec.any ? "● REC" : "STANDBY"
        hint: "letter act · j k move · esc close"

        Repeater {
            model: win.rows
            delegate: MenuRow {
                required property var modelData
                required property int index
                key: modelData.key
                name: modelData.name
                desc: modelData.desc
                nameWidth: 120
                status: modelData.state
                selected: index === win.cursor
                litWhenSelected: true
                onHovered: win.cursor = index
                onClicked: win.run(modelData.act)
            }
        }
    }
}
