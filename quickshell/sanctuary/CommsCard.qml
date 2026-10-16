import QtQuick
import "kit"

// COMMS — Discord voice without leaving your window. Mod+C, or click the VC
// cell on the bar. Same grammar as RIG: one letter per action, no SUPER.
//
//   COMMS                                        LIVE
//   #general · votel                              04
//   ▌harry · you                                   ●     green bar = speaking
//    ali                                         MUTE
//   M  MUTE      discord mic — not SUPER M
//   D  DEAFEN    hear no one
//   X  LEAVE     hang up
//   F  VESKTOP   switch to the window
//
// M here is DISCORD's mute (others see the red icon). SUPER M stays the
// system mic. Data: Comms.qml ← the SanctuaryComms Vencord plugin.
Popup {
    id: win

    name: "comms"
    open: Ui.commsOpen
    onDismissed: Ui.commsOpen = false
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

    // The one-word state: what the header lamp and the bar cell say.
    readonly property string word: !Comms.linked ? "NO LINK"
        : !Comms.inCall ? "NOT IN VOICE"
        : Comms.selfDeaf ? "DEAF"
        : Comms.selfMute ? "MUTE" : "LIVE"
    readonly property bool off: word === "MUTE" || word === "DEAF"

    readonly property var rows: {
        const r = [];
        if (Comms.inCall) {
            r.push({ key: "M", name: Comms.selfMute ? "UNMUTE" : "MUTE", desc: "discord mic — not SUPER M", act: "mute" });
            r.push({ key: "D", name: Comms.selfDeaf ? "UNDEAFEN" : "DEAFEN", desc: "hear no one", act: "deafen" });
            r.push({ key: "X", name: "LEAVE", desc: "hang up", act: "leave" });
        }
        r.push({ key: "F", name: "VESKTOP", desc: Comms.linked ? "switch to the window" : "open it", act: "focus" });
        return r;
    }

    onVisibleChanged: if (visible) cursor = 0

    function run(act) {
        Ui.commsOpen = false;
        if (act === "mute")
            Comms.mute();
        else if (act === "deafen")
            Comms.deafen();
        else if (act === "leave")
            Comms.leave();
        else if (act === "focus")
            Comms.focus();
    }

    // A person's right-hand mark: speaking dot, or what they've switched off.
    function mark(m) {
        return m.deaf ? "DEAF" : m.mute ? "MUTE" : m.speaking ? "●" : "";
    }

    Panel {
        width: parent.width
        title: "COMMS"
        headerHeight: 18
        tone: win.off ? "alarm" : ""
        detail: win.word
        detailStrong: true
        detailTone: win.word === "LIVE" ? "live" : win.off ? "alarm" : ""
        hint: "letter act · j k move · esc close"

        Pair {   // #channel · server ··· people count
            visible: Comms.inCall
            text: "#" + Comms.channel + (Comms.guild !== "" ? "  ·  " + Comms.guild : "")
            value: Theme.pad(Comms.count, 2, "0")
        }

        Label {   // why there's nothing
            visible: !Comms.inCall
            x: 14
            width: implicitWidth
            bottomPadding: 6
            role: "note"
            text: Comms.linked ? "join a voice channel in Vesktop"
                               : "vesktop closed, or SanctuaryComms off"
        }

        Repeater {   // the room
            model: Comms.inCall ? Comms.members : []
            delegate: PersonRow {
                required property var modelData
                name: modelData.name + (modelData.me ? "  · you" : "")
                speaking: modelData.speaking
                mark: win.mark(modelData)
                markAlarm: modelData.mute || modelData.deaf
            }
        }

        Rule { height: 1 }
        Item { width: 1; height: 4 }

        Repeater {   // the actions
            model: win.rows
            delegate: MenuRow {
                required property var modelData
                required property int index
                key: modelData.key
                name: modelData.name
                desc: modelData.desc
                nameWidth: 100
                selected: index === win.cursor
                litWhenSelected: true
                onHovered: win.cursor = index
                onClicked: win.run(modelData.act)
            }
        }
    }
}
