//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

// The Sanctuary in Quickshell — one process that is the bar, the toasts and the
// notification centre, for the QS modes (Ink, Signal).
//
// Started at login by scripts/sanctuary/shell.sh (niri startup.kdl), which also
// owns style switches (Mod+Shift+T → Picker.qml → `shell.sh set <style>`) and
// the waybar + swaync fallback. The style is the `SANCTUARY_QS` env var — see
// Theme.qml. Run by hand to hack on it:
//
//     SANCTUARY_QS=signal qs -p ~/.dotfiles/quickshell/sanctuary
//
// Saving any .qml file here hot-reloads the running shell.
ShellRoot {
    id: shell

    // Touch the notification singleton at startup: singletons are lazy, and the
    // server must claim org.freedesktop.Notifications now — not when the first
    // toast window happens to read it.
    readonly property bool _notifsUp: Notifs.dnd || true

    // ── Ink ───────────────────────────────────────────────────────────
    Variants {
        model: Theme.ink ? Quickshell.screens : []
        InkBar {}
    }
    LazyLoader {
        active: Theme.ink
        Toasts {
            toastWidth: 360
            gap: 4
            delegate: Component { InkToast {} }
        }
    }
    LazyLoader {
        active: Theme.ink
        InkCentre {}
    }

    // ── Signal ────────────────────────────────────────────────────────
    Variants {
        model: Theme.signal ? Quickshell.screens : []
        SignalBar {}
    }
    LazyLoader {
        active: Theme.signal
        Toasts {
            toastWidth: 380
            gap: 8
            delegate: Component { SignalToast {} }
        }
    }
    LazyLoader {
        active: Theme.signal
        SignalCentre {}
    }

    // ── Every style: volume pop-up, music card ────────────────────────
    LazyLoader {
        active: true
        Osd {}
    }
    LazyLoader {
        active: true
        Player {}
    }
    LazyLoader {
        active: true
        Picker {}
    }
    LazyLoader {
        active: true
        Launcher {}
    }
    LazyLoader {
        active: true
        PowerMenu {}
    }
    LazyLoader {
        active: true
        WallPicker {}
    }
    LazyLoader {
        active: true
        TrayMenu {}
    }

    // ── IPC — what the keybinds call (scripts/sanctuary/notif.sh, bar.sh) ──
    //   qs ipc -p ~/.dotfiles/quickshell/sanctuary call notifs toggle
    IpcHandler {
        target: "notifs"
        function toggle(): void { Ui.centreOpen = !Ui.centreOpen; }
        function open(): void { Ui.centreOpen = true; }
        function close(): void { Ui.centreOpen = false; }
        function clear(): void { Notifs.clearAll(); }
        function dnd(): void { Notifs.dnd = !Notifs.dnd; }
        function setDnd(on: bool): void { Notifs.dnd = on; }
        function isDnd(): bool { return Notifs.dnd; }
        function count(): int { return Notifs.count; }
        // qs.sh polls this after a start: an answer means the shell, and so the
        // notification server, is up — safe to send the mode toast.
        function ping(): string { return "pong " + Theme.style; }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { Ui.launcherOpen = !Ui.launcherOpen; }
        function close(): void { Ui.launcherOpen = false; }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { Ui.powerOpen = !Ui.powerOpen; }
        function close(): void { Ui.powerOpen = false; }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { Ui.wallOpen = !Ui.wallOpen; }
        function close(): void { Ui.wallOpen = false; }
    }

    IpcHandler {
        target: "picker"
        function toggle(): void { Ui.pickerOpen = !Ui.pickerOpen; }
    }

    IpcHandler {
        target: "player"
        function toggle(): void { Ui.playerOpen = !Ui.playerOpen; }
        function close(): void { Ui.playerOpen = false; }
    }

    IpcHandler {
        target: "caution"
        function acknowledge(): void { Caution.acknowledge(); }
        function reasons(): string { return Caution.reasons.join(" "); }
    }

    // Test hooks — for seeing the warning states on demand:
    //   qs.sh call debug fakeTemp 95     TEMP cell (red) + Master Caution
    //   qs.sh call debug fakeTemp -1     back to the real sensor
    IpcHandler {
        target: "debug"
        function fakeTemp(c: real): void { Sys.tempOverride = c; }
        //   qs.sh call debug launcherType fir · qs.sh call debug launcherEnter
        function launcherType(text: string): void { Ui.launcherType(text); }
        function launcherEnter(): void { Ui.launcherEnter(); }
        //   qs.sh call debug trayMenu 0   open tray item 0's menu (as a right-click would)
        function trayMenu(i: int): string {
            const item = SystemTray.items.values[i];
            if (!item || !item.hasMenu)
                return "no menu";
            Ui.trayX = 1800;
            Ui.trayMenu = item.menu;
            return item.id;
        }
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { Ui.barShown = !Ui.barShown; }
        function show(): void { Ui.barShown = true; }
        function hide(): void { Ui.barShown = false; }
    }
}
