import QtQuick
import Quickshell.Services.Pipewire
import "kit"

// PATCH — where the sound goes, Mod+O (scripts/sanctuary/patch.sh). Every
// output (speakers, headphones, HDMI, Bluetooth) and every input (mics) as one
// list; the ● row is the default, and picking another one moves what is playing
// / recording over to it (WirePlumber follows the default). Volume and mute per
// device, so you can set the headset up before you switch to it.
//
//   OUT  ● 01  Built-in Audio Analog Stereo   INT  ▕██████████▏ 100
//          02  WH-1000XM4                     BT   ▕██████░░░░▏  60
//   IN   ● 01  Built-in Audio Analog Stereo   INT  ▕███░░░░░░░▏  32
//
//   enter space  make default     m  mute     h l ← →  volume ±5
//   j k ↑ ↓  move     tab  jump OUT ⇄ IN     x  full mixer (wiremix)     esc q  close
//   click a row = default · right-click = mute · scroll = volume
//
// Fallback (Quickshell down): the same key opens wiremix in a floating kitty.
Popup {
    id: win

    name: "patch"
    open: Ui.patchOpen
    onDismissed: Ui.patchOpen = false
    cardWidth: 560
    // Its own keys, not the list keys: here l / → turn the volume up.
    onKeyPressed: event => key(event)

    // Hardware and virtual devices only — not the apps' own streams. A camera
    // is a node too, but it has no `audio`, so it never shows up here.
    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var outs: devices.filter(n => n.isSink)
    readonly property var ins: devices.filter(n => !n.isSink)
    // One flat list for the cursor: outputs first, then inputs.
    readonly property var rows: outs.concat(ins)

    // Volume and mute are empty until a node is tracked — track them all while open.
    PwObjectTracker {
        objects: win.visible ? win.devices : []
    }

    onVisibleChanged: {
        if (visible) {
            // Open on the current default output, where you most likely want to start.
            const i = rows.indexOf(Pipewire.defaultAudioSink);
            cursor = Math.max(0, i);
        }
    }

    function isDefault(n) {
        return n === (n.isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource);
    }
    function route(n) {
        if (!n)
            return;
        if (n.isSink)
            Pipewire.preferredDefaultAudioSink = n;
        else
            Pipewire.preferredDefaultAudioSource = n;
    }
    function mute(n) {
        if (n && n.audio)
            n.audio.muted = !n.audio.muted;
    }
    // Outputs stop at 100% (the same cap as the volume keys); inputs may go to
    // 150% — some mics really are that quiet.
    function nudge(n, d) {
        if (!n || !n.audio)
            return;
        const cap = n.isSink ? 1.0 : 1.5;
        n.audio.volume = Math.max(0, Math.min(cap, Math.round((n.audio.volume + d) * 20) / 20));
    }
    function openMixer() {
        Ui.patchOpen = false;
        Media.openMixer();
    }

    // A short tag for where a device lives, from its node name:
    // bluez_output.… BT · alsa_output.usb-… USB · …hdmi… HDMI · alsa pci INT.
    function bus(n) {
        const s = (n.name || "").toLowerCase();
        if (s.startsWith("bluez"))
            return "BT";
        if (s.indexOf("usb") >= 0)
            return "USB";
        if (s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0)
            return "HDMI";
        if (s.startsWith("alsa"))
            return "INT";
        return "VIRT";
    }
    function label(n) {
        return n.description || n.nickname || n.name || ("node " + n.id);
    }

    function key(event) {
        const k = event.key;
        const n = rows.length;
        const cur = rows[cursor];
        if (n === 0)
            return;
        else if (k === Qt.Key_J || k === Qt.Key_Down)
            cursor = (cursor + 1) % n;
        else if (k === Qt.Key_K || k === Qt.Key_Up)
            cursor = (cursor + n - 1) % n;
        else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
            // jump to the other section's default (or its first row)
            const other = cur && cur.isSink ? ins : outs;
            if (other.length === 0)
                return;
            const d = other.find(x => isDefault(x)) || other[0];
            cursor = rows.indexOf(d);
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            route(cur);
        else if (k === Qt.Key_M)
            mute(cur);
        else if (k === Qt.Key_H || k === Qt.Key_Left)
            nudge(cur, -0.05);
        else if (k === Qt.Key_L || k === Qt.Key_Right)
            nudge(cur, 0.05);
        else if (k === Qt.Key_X)
            openMixer();
        else
            return;
        event.accepted = true;
    }

    Panel {
        width: parent.width
        title: "PATCH"
        detail: win.outs.length + " OUT · " + win.ins.length + " IN"
        hint: "enter route · m mute · h l vol · tab out⇄in · x mixer · esc"
        hintGap: 10

        Repeater {
            model: win.rows
            delegate: ChannelRow {
                required property var modelData
                required property int index
                readonly property var node: modelData
                // A section label above the first row of each section.
                readonly property bool first: index === 0 || win.rows[index - 1].isSink !== node.isSink
                section: !first ? "" : node.isSink ? "OUT  ▸ speakers · headphones" : "IN   ◂ microphones"
                isDefault: win.isDefault(node)
                number: Theme.pad(index + 1 - (node.isSink ? 0 : win.outs.length), 2, "0")
                name: win.label(node)
                tag: win.bus(node)
                level: node.audio ? node.audio.volume : 0
                muted: node.audio ? node.audio.muted : false
                selected: index === win.cursor
                onHovered: win.cursor = index
                onClicked: win.route(node)
                onRightClicked: win.mute(node)
                onWheeled: d => win.nudge(node, d * 0.05)
            }
        }

        Label {
            visible: win.rows.length === 0
            x: 14
            width: implicitWidth
            topPadding: 6
            role: "empty"
            text: "no audio devices — is PipeWire up?"
        }
    }
}
