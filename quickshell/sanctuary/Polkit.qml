import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Polkit

// The password prompt — the polkit authentication agent. When an app asks for
// admin rights (pkexec, a system Flatpak, disks, firewall…), polkit asks the
// session's agent to get your password. Before this there was NO agent running
// (mate-polkit was installed 2026-09-26 but only autostarts under MATE), so
// those requests failed silently.
//
// Only one agent may hold a session. shell.sh owns the handover: Quickshell up
// → this one; fallback (waybar) → mate-polkit, killed again before Quickshell
// comes back. If registering fails anyway, nothing breaks — this stays hidden.
//
//   type  password     enter  submit     esc  cancel
PanelWindow {
    id: win

    readonly property var flow: agent.flow
    visible: agent.isActive && flow !== null

    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    PolkitAgent {
        id: agent
    }

    //   qs.sh call polkit registered   → true once polkit accepted this agent
    IpcHandler {
        target: "polkit"
        function registered(): bool { return agent.isRegistered; }
    }

    onVisibleChanged: {
        input.text = "";
        if (visible)
            input.forceActiveFocus();
    }

    function submit() {
        if (!flow || !flow.isResponseRequired)
            return;
        flow.submit(input.text);
        input.text = "";
    }
    function cancel() {
        if (flow)
            flow.cancelAuthenticationRequest();
    }

    // A scrim, not click-outside-to-close: a stray click must not cancel the
    // request out from under the app that asked.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }
    }

    readonly property bool error: flow !== null && (flow.failed || flow.supplementaryIsError)
    readonly property string note: flow && flow.supplementaryMessage ? flow.supplementaryMessage
                                 : flow && flow.failed ? "wrong password — try again" : ""

    Item {
        id: card
        anchors.centerIn: parent
        width: 440
        height: sig.height

        // ══ Signal ═══════════════════════════════════════════════════
        //   ┌ AUTH ─────────────────────── ADMIN ┐
        //   │ Authentication is required to …    │
        //   │ org.freedesktop.udisks2.…          │
        //   │ PASSWORD ▏••••••••                 │
        //   └ enter submit · esc cancel ─────────┘
        Rectangle {
            id: sig
            width: parent.width
            height: sigCol.implicitHeight + 28
            color: Theme.sigFill
            border.width: 1
            border.color: win.error ? Theme.sigAlarm : Theme.sigRule

            SignalTicks {
                anchors.fill: parent
                anchors.margins: -3
                color: Theme.sigWarn
            }

            Column {
                id: sigCol
                x: 16
                y: 14
                width: parent.width - 32
                spacing: 10

                Item {
                    width: parent.width
                    height: 12
                    Text {
                        text: "AUTH"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: Theme.sigWarn
                    }
                    Text {
                        anchors.right: parent.right
                        text: "ADMIN"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        color: Theme.sigLabel
                    }
                }
                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: win.flow ? win.flow.message : ""
                    font.family: Theme.mono
                    font.pixelSize: 12
                    color: Theme.sigValue
                }
                Text {
                    width: parent.width
                    elide: Text.ElideMiddle
                    text: win.flow ? win.flow.actionId : ""
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
                Rectangle {
                    id: sigBox
                    width: parent.width
                    height: 32
                    color: Theme.sigCell
                    border.width: 1
                    border.color: win.error ? Theme.sigAlarm : Theme.sigRule
                    Text {
                        id: sigPrompt
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PASSWORD"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: Theme.sigLabel
                    }
                }
                Text {
                    visible: text !== ""
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: win.note
                    font.family: Theme.mono
                    font.pixelSize: 10
                    color: win.error ? Theme.sigAlarm : Theme.sigLabel
                }
                Text {
                    text: "enter submit · esc cancel"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    color: Theme.surface2
                }
            }
        }


        // The one input, laid over the prompt box.
        TextInput {
            id: input
            readonly property Item box: sigBox
            x: sig.x + sigCol.x + box.x + sigPrompt.x + sigPrompt.implicitWidth + 12
            y: sigCol.y + box.y + (box.height - height) / 2
            width: box.width - sigPrompt.implicitWidth - 34
            focus: true
            enabled: win.flow !== null && win.flow.isResponseRequired
            echoMode: win.flow && win.flow.responseVisible ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            font.family: Theme.mono
            font.pixelSize: 14
            color: Theme.sigValue
            selectionColor: Theme.surface1
            clip: true
            Keys.onReturnPressed: win.submit()
            Keys.onEnterPressed: win.submit()
            Keys.onEscapePressed: win.cancel()
        }
    }
}
