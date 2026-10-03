# Quickshell — the desk's shell

One Quickshell process is the **bar + notification toasts + notification centre +
volume pop-up + player card + style picker**. It starts at login, drawing
**Signal** unless you picked another style. The old waybar + swaync configs are
untouched and come up **automatically** if Quickshell fails.

## Install (once)

```sh
# Quickshell (Fedora COPR — needs 0.2 or newer; this desk runs 0.3.1)
sudo dnf copr enable errornointernet/quickshell
sudo dnf install quickshell

# Optional: Ink's lettering face. Without it Ink falls back to Geist Black.
mkdir -p ~/.local/share/fonts
curl -fLo ~/.local/share/fonts/Bangers-Regular.ttf \
  https://github.com/google/fonts/raw/main/ofl/bangers/Bangers-Regular.ttf
fc-cache -f

# Stop D-Bus auto-starting swaync before Quickshell claims notifications at login.
# (The fallback starts swaync directly, so it still works.) Undo: `unmask`.
systemctl --user mask swaync.service
```

## How it runs

```
niri startup ─► shell.sh start ─► qs.sh start <saved style>  (default: signal)
                     │                 └─ fails? ─► fallback: waybar + swaync (ascii)
                     └─► shell.sh watch   Quickshell dies later? ─► same fallback
Mod+Shift+T ─► Quickshell's picker ─► shell.sh set <style>   (remembered in ~/.local/state/sanctuary/style)
           └─ in fallback: retries Quickshell instead
```

**Styles:** `signal` (instrument strip), `ink` (dark manga, only ever dark),
`paper` (light manga). A switch restarts Quickshell only.

**Nothing rewrites niri config or keybinds.** niri's layout is the hand-kept
`niri/niri/layout.kdl` (Signal's numbers: square, tight, 2px green border). The
old per-mode renderer is in `archive/mode-system/`.

**Fallback** = `waybar/config.jsonc` + `style.css`, and swaync started with
`-c/-s swaync/swaync/themes/ascii/…` — your previous setup, exactly. A critical
toast says why it happened. `shell.sh status` prints which one is up.

## Files

| File | What |
|---|---|
| `sanctuary/shell.qml` | Entry. Loads the style's windows; IPC handlers (`notifs`, `bar`, `picker`, `player`, `caution`, `debug`). |
| `sanctuary/Theme.qml` | Tokens for both styles. Reads `SANCTUARY_QS`. |
| `sanctuary/Notifs.qml` | **The notification daemon** (Quickshell's `NotificationServer`), DND, history. |
| `sanctuary/Niri.qml` | Workspaces + windows from `niri msg --json event-stream`. |
| `sanctuary/Media.qml` | MPRIS now-playing, PipeWire mic. |
| `sanctuary/Sys.qml` | CPU / mem / net / temp / disk, history, thresholds, exceptions. |
| `sanctuary/Caution.qml` | Master Caution: reasons + acknowledge. |
| `sanctuary/Osd.qml`, `Player.qml` | Volume pop-up, music player card (all styles). |
| `sanctuary/Ink*.qml` | Ink: bar, panel, halftone, speech bubble, toast, centre. |
| `sanctuary/Signal*.qml`, `Sparkline.qml` | Signal: bar, cell, ticks, toast, centre. |
| `sanctuary/Toasts.qml`, `Tray.qml` | Shared: the toast column window, the system tray. |

| `sanctuary/Picker.qml` | Mod+Shift+T style picker. |
| `sanctuary/Launcher.qml` | Mod+Space app launcher (all styles); fsel is the fallback. |

Scripts: `scripts/sanctuary/shell.sh` (startup, style switch, fallback, crash
watch), `launcher.sh` (Mod+Space → Quickshell launcher, or fsel in fallback),
`qs.sh` (start/stop/IPC), `notif.sh` (notification keys → Quickshell or
swaync), `bar.sh` (Mod+Shift+A).

## Hacking on it

```sh
scripts/sanctuary/qs.sh log                     # follow the running shell's log
SANCTUARY_QS=signal qs -p ~/.dotfiles/quickshell/sanctuary   # run by hand
scripts/sanctuary/qs.sh call notifs toggle      # any IPC function in shell.qml
notify-send -u critical "test" "a shouting bubble in Ink"
```

Saving a `.qml` file hot-reloads the running shell; notification history
survives it (`keepOnReload`).

## Keys (same in every mode)

| Key | Action |
|---|---|
| `Mod+Space` | launcher — type to filter · `enter` launch · `↑↓`/`ctrl-j k`/`ctrl-n p` move · `esc` close (in fallback: fsel) |
| `Mod+Shift+T` | style picker — `j`/`k` move · `enter` or `1`-`3` pick · `esc` close (in fallback: retry Quickshell) |
| `Mod+Shift+A` | hide / show the bar |
| `Mod+Shift+D` | notification centre — inside it: `c` clear all · `d` DND · `esc` close |
| `Mod+Ctrl+D` | clear all notifications |
| `Mod+Alt+D` | DND toggle |

Mouse on the bar: workspaces click/scroll · music left play-pause, **right the player
card**, scroll skip · **CPU / MEM / TEMP right-click: btop** (again to close) · mic left
mixer, right mute · count left centre, right DND.

Player card keys: `space` play/pause · `h`/`←` previous · `l`/`→` next · `esc`/`q` close ·
click the progress line to seek · click anywhere outside to close.

## Every QS style also has

- **Volume pop-up** (`Osd.qml`) — under the bar when the output volume or mute changes.
- **Master Caution** (`Caution.qml`) — one light for "something needs you": CPU ≥90%
  sustained 5s, MEM ≥90%, TEMP ≥90°C, a disk ≥95% full, or an unread critical
  notification. Signal: red corner marks + red seconds + a `▲ REASON` lamp. Ink/Paper:
  the clock's shadow goes red + a `!! REASON` panel. Click the lamp to acknowledge —
  it stays dark until a *new* reason appears.
- **Exception cells** — `TEMP` (≥80°C) and `DISK` (≥90% used) exist only while
  abnormal. Thresholds: one block at the top of `Sys.qml`.

Test the warning states without heating anything:

```sh
scripts/sanctuary/qs.sh call debug fakeTemp 95   # TEMP cell + caution
scripts/sanctuary/qs.sh call debug fakeTemp -1   # back to the real sensor
```
