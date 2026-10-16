import QtQuick
import Quickshell.Io
import Quickshell.Services.Polkit
import "kit"

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
//   ┌ AUTH ─────────────────────── ADMIN ┐
//   │ Authentication is required to …    │
//   │ org.freedesktop.udisks2.…          │
//   │ PASSWORD ▏••••••••                 │
//   └ enter submit · esc cancel ─────────┘
//
//   type  password     enter  submit     esc  cancel
Popup {
    id: win

    name: "polkit"
    readonly property var flow: agent.flow
    open: agent.isActive && flow !== null
    cardWidth: 440
    // A dimmed scrim, not click-outside-to-close: a stray click must not
    // cancel the request out from under the app that asked.
    dim: true
    clickAway: false

    PolkitAgent {
        id: agent
    }

    //   qs.sh call polkit registered   → true once polkit accepted this agent
    IpcHandler {
        target: "polkit"
        function registered(): bool { return agent.isRegistered; }
    }

    onVisibleChanged: {
        field.text = "";
        if (visible)
            field.focusInput();
    }

    function submit() {
        if (!flow || !flow.isResponseRequired)
            return;
        flow.submit(field.text);
        field.text = "";
    }
    function cancel() {
        if (flow)
            flow.cancelAuthenticationRequest();
    }

    readonly property bool error: flow !== null && (flow.failed || flow.supplementaryIsError)
    readonly property string note: flow && flow.supplementaryMessage ? flow.supplementaryMessage
                                 : flow && flow.failed ? "wrong password — try again" : ""

    Panel {
        width: parent.width
        pad: 16
        vpad: 14
        inset: 0
        spacing: 10
        headerHeight: 12
        hintGap: 0
        title: "AUTH"
        detail: "ADMIN"
        hint: "enter submit · esc cancel"
        tone: "warn"
        titleTone: "warn"
        edgeTone: win.error ? "alarm" : ""

        Label {
            text: win.flow ? win.flow.message : ""
        }
        Label {
            role: "fine"
            text: win.flow ? win.flow.actionId : ""
        }
        Field {
            id: field
            label: "PASSWORD"
            secret: !(win.flow && win.flow.responseVisible)
            inputEnabled: win.flow !== null && win.flow.isResponseRequired
            tone: win.error ? "alarm" : ""
            onAccepted: win.submit()
            onEscaped: win.cancel()
        }
        Label {
            role: "note"
            visible: text !== ""
            text: win.note
            tone: win.error ? "alarm" : ""
        }
    }
}
