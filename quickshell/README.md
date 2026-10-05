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
`paper` (light manga). A switch re-points the window layout and restarts Quickshell.

**Windows follow the style, and nothing rewrites niri config.** Each style has a
hand-kept layout file — `niri/niri/layout-signal.kdl` (square, tight, 2px green
border), `layout-ink.kdl` (3px light outline + hard mauve shadow),
`layout-paper.kdl` (starts as Ink's). `layout.kdl` is a git-ignored symlink to
the active one; a style switch re-points it (after `niri validate` passes — a
broken file is refused and the old link kept) and reloads niri. Edit those files
by hand to change how windows look in a style. The old per-mode renderer is in
`archive/mode-system/`.

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
| `sanctuary/TrayMenu.qml` | A tray app's right-click menu, drawn in the current style (not Qt's native white QMenu). |
| `sanctuary/Picker.qml` | Mod+Shift+T style picker. |
| `sanctuary/Launcher.qml` | Mod+Space app launcher (all styles); fsel is the fallback. |
| `sanctuary/PowerMenu.qml` | Mod+Shift+Escape power menu (all styles); fzf in kitty is the fallback. |
| `sanctuary/Rec.qml` | Both recorders' state (reads `$XDG_RUNTIME_DIR/{screenrec,meeting-rec}/state.json` once a second) + commands. |
| `sanctuary/Rig.qml` | Mod+U RIG card: SCREEN / MEETING / PRACTICE, or stop / pause whatever runs. |
| `sanctuary/Capture.qml`, `CapButton.qml` | Ctrl+Print screen-record overlay: drag a region, the rest dims, strip with MIC/SYS/PAUSE/STOP. Fallback: `slurp`, no strip. |
| `sanctuary/Polkit.qml` | The polkit agent (admin password prompt). Fallback: mate-polkit, swapped by `shell.sh`. |
| `sanctuary/WallPicker.qml`, `Thumb.qml` | Mod+Shift+W wallpaper picker — stills + live videos as thumbnails; yazi is the fallback. |

Scripts: `scripts/sanctuary/shell.sh` (startup, style switch, fallback, crash
watch), `launcher.sh` (Mod+Space → Quickshell launcher, or fsel in fallback),
`power.sh open` / `wallpaper.sh open` (same idea: Quickshell, or the kitty TUI),
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
| `Mod+Shift+W` | wallpaper — type to filter · arrows/`ctrl-h j k l` move · `tab` still/live · `enter` set · `shift-enter` set and stay open · `esc` close (in fallback: yazi) |
| `Mod+Shift+Escape` | power — `j`/`k` move · `enter` or `1`-`5` act (no confirm; opens on lock) · `esc` close (in fallback: fzf) |
| `Mod+U` | RIG — `s` screen · `m` meeting · `p` practice; while recording: `s`/`m` stop, `d`/`p` pause · `esc` close |
| `Ctrl+Print` | screen recording: idle → overlay (drag · `enter`/`r` record · `f` full · `m` mic · `s` sys · `esc` cancel); recording → stop + save |
| `Ctrl+Alt+Print` | pause / resume the screen recording |
| `Mod+Shift+/` | niri's keybind cheat sheet |
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

## Recorders (2026-10-05)

- **Bar:** a `◉` cell at the far left opens RIG. While something records it becomes
  `SCR ● 03:12` (red — the screen) and/or `AUD·2 ● 41:05` (peach — sound; `·1` =
  practice, mic only). Paused shows `‖` in yellow. Left-click stops (saves), right-click
  opens RIG. Ink/Paper: the same as panels — `▣ SCR` with a red shadow, `∿ AUD` peach.
- **Screen** (`scripts/sanctuary/screenrec.sh`): wf-recorder, H.264 on the iGPU (VAAPI),
  mic + system audio each captured by `pw-record`. MIC/SYS only log *when* you flipped
  them; the silence is applied when saving — PipeWire is never touched, so your calls
  hear nothing different. Pause = new segment; stop joins them into
  `~/Videos/Recordings/Recording <date>.mp4` and toasts Open / Show folder. While
  recording an IdleInhibitor stops the screen locking (it would be recorded), and DND goes on
  (toasts would be recorded too; critical ones still pop) — back off after, unless it was
  already on. FULL draws
  no strip — control it from the bar cell, RIG or the keys.
- **Audio** (`meeting-rec.sh`): gained `pause | resume | pause-toggle` (parts joined back
  into one `me.wav` / `them.wav` on stop) and a `state.json` for the bar.
- **Debug:** `qs.sh call debug fakeRec scr|scr-paused|scr-full|aud|aud-solo|both|off`
  draws the cells and strip with nothing recording. `qs.sh call polkit registered`.
