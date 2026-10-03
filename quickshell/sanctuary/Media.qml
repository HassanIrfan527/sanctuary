pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Now-playing, output volume and the mic, for every QS style.
Singleton {
    id: root

    // ── Music ─────────────────────────────────────────────────────────
    // Prefer whatever is actually playing; otherwise the first player. Same
    // choice waybar/scripts/music.sh makes with playerctl.
    readonly property var player: {
        const ps = Mpris.players.values;
        for (const p of ps)
            if (p.isPlaying)
                return p;
        return ps.length > 0 ? ps[0] : null;
    }
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property bool playing: player ? player.isPlaying : false
    // Empty state renders nothing (§2): stopped or untitled means no module.
    readonly property bool hasTrack: player !== null && title !== ""
        && player.playbackState !== MprisPlaybackState.Stopped
    readonly property real progress: (player && player.lengthSupported && player.length > 0)
        ? Math.max(0, Math.min(1, player.position / player.length)) : 0
    readonly property string album: player ? (player.trackAlbum || "") : ""
    readonly property string art: player ? (player.trackArtUrl || "") : ""
    readonly property string identity: player ? (player.identity || "") : ""
    readonly property real position: player ? player.position : 0
    readonly property real length: (player && player.lengthSupported) ? player.length : 0
    readonly property bool canSeek: player ? (player.canSeek && player.positionSupported) : false

    function seek(frac) {
        if (canSeek && length > 0)
            player.position = Math.max(0, Math.min(1, frac)) * length;
    }

    // 3:07 / 1:02:44
    function clock(sec) {
        const s = Math.max(0, Math.floor(sec));
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60;
        return (h > 0 ? h + ":" + Theme.pad(m, 2, "0") : String(m)) + ":" + Theme.pad(r, 2, "0");
    }

    // Mpris position is not pushed by players; Quickshell asks you to poke it.
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    function toggle() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (player && player.canGoNext)
            player.next();
    }
    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }

    // ── Output volume — feeds the volume pop-up (Osd.qml) ─────────────
    // `touched` fires when the volume or mute ACTUALLY changes. Two guards stop
    // it firing for things that aren't you pressing a key: nothing for the first
    // moments after start (the tracker fills properties in = "changes"), and
    // nothing for a beat after the default sink itself changes (plugging in
    // headphones swaps the node — that is not a volume change).
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkKnown: sink !== null && sink.audio !== null
    readonly property real volume: sinkKnown ? sink.audio.volume : 0
    readonly property bool muted: sinkKnown ? sink.audio.muted : false
    signal touched()

    property bool _quiet: true
    Timer {
        id: settle
        interval: 800
        running: true
        onTriggered: root._quiet = false
    }
    onSinkChanged: {
        _quiet = true;
        settle.restart();
    }
    onVolumeChanged: if (!_quiet) touched()
    onMutedChanged: if (!_quiet) touched()

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // ── Mic ───────────────────────────────────────────────────────────
    // A readout, not a button (§1). The two clicks match the waybar module:
    // left opens the mixer, right cuts the mic.
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool micKnown: source !== null && source.audio !== null
    readonly property bool micOn: micKnown && !source.audio.muted
    readonly property real micVolume: micKnown ? source.audio.volume : 0

    // Pipewire node properties stay empty until something tracks the node.
    PwObjectTracker {
        objects: root.source ? [root.source] : []
    }

    function toggleMic() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
    }
    function openMixer() {
        Quickshell.execDetached(["kitty", "--class", "sanctuary-mixer", "-e", "wiremix"]);
    }
}
