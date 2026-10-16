import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland

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
PanelWindow {
    id: win

    visible: Ui.patchOpen
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-patch"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Hardware and virtual devices only — not the apps' own streams. A camera
    // is a node too, but it has no `audio`, so it never shows up here.
    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var outs: devices.filter(n => n.isSink)
    readonly property var ins: devices.filter(n => !n.isSink)
    // One flat list for the cursor: outputs first, then inputs.
    readonly property var rows: outs.concat(ins)
    property int cursor: 0

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
    function pct(n) {
        return n.audio ? Math.round(n.audio.volume * 100) : 0;
    }

    function key(event) {
        const k = event.key;
        const n = rows.length;
        const cur = rows[cursor];
        if (k === Qt.Key_Escape || k === Qt.Key_Q)
            Ui.patchOpen = false;
        else if (n === 0)
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

    MouseArea {   // scrim: click outside = close
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Ui.patchOpen = false
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: 560
        height: sig.height
        focus: true
        Keys.onPressed: event => win.key(event)

        MouseArea {   // swallow clicks on the card
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        // ══ Signal: a patch bay ═══════════════════════════════════════
        Rectangle {
            id: sig
            width: parent.width
            height: sigCol.implicitHeight + 24
            color: Theme.sigFill
            border.width: 1
            border.color: Theme.sigRule

            SignalTicks {
                anchors.fill: parent
                anchors.margins: -3
            }

            Column {
                id: sigCol
                x: 1
                y: 12
                width: parent.width - 2
                spacing: 2

                Item {
                    width: parent.width
                    height: 20
                    Text {
                        x: 14
                        text: "PATCH"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigHot
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        text: win.outs.length + " OUT · " + win.ins.length + " IN"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        color: Theme.sigLabel
                    }
                }

                Repeater {
                    model: win.rows
                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property var node: modelData
                        readonly property bool sel: index === win.cursor
                        readonly property bool def: win.isDefault(node)
                        readonly property bool muted: node.audio ? node.audio.muted : false
                        // A section label above the first row of each section.
                        readonly property bool first: index === 0 || win.rows[index - 1].isSink !== node.isSink
                        width: sigCol.width
                        height: (first ? 22 : 0) + 30

                        Text {
                            visible: row.first
                            x: 14
                            y: 8
                            text: row.node.isSink ? "OUT  ▸ speakers · headphones" : "IN   ◂ microphones"
                            font.family: Theme.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1.4
                            color: Theme.surface2
                        }

                        Rectangle {
                            y: row.first ? 22 : 0
                            width: parent.width
                            height: 30
                            color: row.sel ? Theme.sigCell : "transparent"

                            Rectangle {
                                width: 2
                                height: parent.height
                                color: Theme.sigHot
                                visible: row.sel
                            }
                            Row {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Text {
                                    width: 10
                                    text: row.def ? "●" : "○"
                                    font.family: Theme.mono
                                    font.pixelSize: 10
                                    color: row.def ? Theme.sigHot : Theme.surface1
                                }
                                Text {
                                    text: Theme.pad(row.index + 1 - (row.node.isSink ? 0 : win.outs.length), 2, "0")
                                    font.family: Theme.mono
                                    font.pixelSize: 10
                                    color: Theme.surface2
                                }
                                Text {
                                    width: 250
                                    elide: Text.ElideRight
                                    text: win.label(row.node)
                                    font.family: Theme.mono
                                    font.pixelSize: 12
                                    font.weight: row.def || row.sel ? Font.Bold : Font.Normal
                                    color: row.sel ? Theme.sigHot : row.def ? Theme.sigValue : Theme.sigLabel
                                }
                                Text {
                                    width: 34
                                    text: win.bus(row.node)
                                    font.family: Theme.mono
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                    color: Theme.sigLabel
                                }
                            }
                            // gauge: ten cells; muted = yellow word instead of a level
                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Repeater {
                                        model: 10
                                        delegate: Rectangle {
                                            required property int index
                                            width: 4
                                            height: 9
                                            color: row.muted ? Theme.surface0
                                                 : win.pct(row.node) > index * 10 + 2
                                                   ? (row.def ? Theme.sigHot : Theme.sigLabel)
                                                   : Theme.surface0
                                        }
                                    }
                                }
                                Text {
                                    width: 32
                                    horizontalAlignment: Text.AlignRight
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.muted ? "MUTE" : win.pct(row.node)
                                    font.family: Theme.mono
                                    font.pixelSize: 10
                                    font.weight: row.muted ? Font.Bold : Font.Normal
                                    color: row.muted || row.node.audio.volume > 1.005 ? Theme.sigWarn : Theme.sigValue
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.cursor = row.index
                                onClicked: mouse => mouse.button === Qt.RightButton ? win.mute(row.node) : win.route(row.node)
                                onWheel: wheel => win.nudge(row.node, wheel.angleDelta.y > 0 ? 0.05 : -0.05)
                            }
                        }
                    }
                }

                Text {
                    visible: win.rows.length === 0
                    x: 14
                    topPadding: 6
                    text: "no audio devices — is PipeWire up?"
                    font.family: Theme.mono
                    font.pixelSize: 11
                    color: Theme.surface2
                }

                Text {
                    x: 14
                    topPadding: 10
                    text: "enter route · m mute · h l vol · tab out⇄in · x mixer · esc"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
            }
        }

    }
}
