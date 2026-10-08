pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Discord voice, as Vesktop sees it. The SanctuaryComms Vencord plugin
// (~/.dotfiles/vesktop/sanctuaryComms, built by scripts/sanctuary/vencord.sh)
// serves one JSON line per change on a unix socket; this reads it, and writes
// the card's commands back (mute | deafen | leave).
//
// No socket = Vesktop closed or the plugin off: `linked` false, nothing shown
// on the bar. Discord's mute here is separate from Mod+M (the system mic).
Singleton {
    id: root

    readonly property string path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/sanctuary-comms.sock"

    readonly property bool linked: sock.connected
    property bool inCall: false
    property string channel: ""
    property string guild: ""
    property bool selfMute: false
    property bool selfDeaf: false
    property var members: []        // [{ id, name, me, mute, deaf, speaking }] — you first, then A→Z
    readonly property int count: members.length

    function send(cmd) {
        if (!sock.connected)
            return;
        sock.write(cmd + "\n");
        sock.flush();
    }
    function mute() { send("mute"); }
    function deafen() { send("deafen"); }
    function leave() { send("leave"); }

    // Vesktop's window; started if it isn't running.
    function focus() {
        for (const id in Niri.windows) {
            if (Niri.windows[id].app_id === "vesktop") {
                Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)]);
                return;
            }
        }
        Quickshell.execDetached(["vesktop"]);
    }

    function _take(line) {
        let s;
        try {
            s = JSON.parse(line);
        } catch (e) {
            return;
        }
        inCall = !!s.inCall;
        channel = s.channel || "";
        guild = s.guild || "";
        selfMute = !!s.selfMute;
        selfDeaf = !!s.selfDeaf;
        members = s.members || [];
    }

    function _reset() {
        inCall = false;
        channel = "";
        guild = "";
        selfMute = false;
        selfDeaf = false;
        members = [];
    }

    Socket {
        id: sock
        path: root.path
        parser: SplitParser {
            onRead: data => root._take(data)
        }
        onConnectedChanged: if (!connected) root._reset()
    }

    // While unlinked, look for the socket every 3s (Vesktop may start or
    // restart any time) and connect only once it exists — connecting blind
    // logs a ServerNotFoundError warning on every try.
    Process {
        id: probe
        command: ["test", "-S", root.path]
        onExited: code => { if (code === 0) sock.connected = true; }
    }
    Timer {
        interval: 3000
        running: !sock.connected
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }
}
