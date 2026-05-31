# Minimal Preset Plan

A truly minimal, low-RAM Wayland shell. Built additively alongside `grid` (AGS), `sys24`, and `qs` (QuickShell) — never replacing them.

## Goal

A daily-driver shell at **~80-150MB total RAM** (vs. ~600MB+ for end-4's QS dots), built from modern Wayland-native tools. No GTK/Qt shell runtime. Design language: sys24/TUI-leaning, minimal animations but visible, monochrome-friendly.

## Stack

| Component | Tool | Notes |
|---|---|---|
| Compositor | Hyprland | |
| Bar | **waybar** | CSS + JSON; biggest community = best fallback when stuck |
| Launcher | **fuzzel** | Already in use |
| Clipboard | **wl-clipboard + cliphist + fuzzel** | `wl-copy`/`wl-paste` are the modern primitives |
| Notif daemon | **mako** | Wlroots-native, ~5-10MB |
| Notif "center" | **fuzzel --dmenu** action menu | No GTK center; click bar icon → fuzzel popup with actions |
| Wallpaper | **swww** | Animations |
| Wallpaper picker | fuzzel --dmenu script | Defer to v1.1 |
| Lock | **hyprlock** | Already have it |
| Idle | **hypridle** | Better dbus inhibit than swayidle |
| Night light | **wlsunset** | Replace current gammastep autostart |
| Screenshot | **grim + slurp + satty** | satty = modern Rust annotator |
| Power menu | fuzzel --dmenu | Reuse `session-fuzzel.sh` pattern |

### Explicitly rejected for v1
- **eww** — ~80-150MB GTK+Rust; reintroduces the RAM problem we're solving
- **ironbar** — fine tool, but waybar's community/docs advantage > 15MB RAM delta
- **swaync** — GTK ~50MB; fuzzel popup hits the spec lighter
- **dunst, gammastep, wofi/rofi-wayland, swappy** — legacy in 2026

## Bar design

Truly minimal, single row, top:

```
[ ● ○ ○ ○ ○ ]              [ 12:47 · Thu 28 ]              [ 󰂚 ]
  workspaces                   clock + date                   notif
```

- Workspaces: `●` filled = active, `○` empty = inactive. Hyprland `format-icons`.
- Clock: `HH:MM · Day DD`
- Notification icon: custom module; click → fuzzel action menu (night-light toggle, power, etc.)

CSS: monospace font (match terminal/sys24), transparent bg or thin top strip, no gradients, minimal padding.

## Notification "center" via fuzzel

Single keybind / bar-icon click opens a fuzzel `--dmenu` popup:

```
 Toggle night light  (on)
󰐥 Power off
󰍃 Logout
 Reboot
󰌾 Lock
 Clipboard history
 Wallpaper picker  [v1.1]
```

Each line dispatches a shell command. No GTK, no widget runtime, ~zero RAM when closed.

## Implementation order

1. **Cleanup pass** — remove `gammastep -O 3800` from `hypr/autostart.conf`; kill stray hyprsunset; standardize on wlsunset (`exec-once = wlsunset -t 3800 -T 6500`).
2. **Create preset files** — `minimal.conf` + `minimal-keybinds.conf` in this dir; wire into `active.conf` switching.
3. **waybar config** — `waybar/minimal/config.jsonc` + `style.css`. Workspaces, clock, custom notif module.
4. **Action menu script** — `hypr/scripts/minimal-actions.sh` (fuzzel --dmenu).
5. **Clipboard pipeline** — cliphist watcher in autostart; fuzzel picker script; bind to `Super+V`.
6. **Screenshot** — grim+slurp+satty pipeline script; bind to PrintScreen.
7. **swww** — replace hyprpaper in this preset only.
8. **Test daily-drive** — 1 week minimum before declaring stable.

## v1.1 / later

- Wallpaper picker (fuzzel + thumbnails via `chafa` previews? or just names)

## Open questions

- Font choice: stick with current terminal font or pick a dedicated bar font?
- Bar position: top (matches sys24) or bottom?

## Reference: current night-light mess to fix

```
gammastep -O 3800       # PID 2029, autostarted
hyprsunset -t 3551      # PID 17842, source unknown — find and remove
wlsunset                # installed, NOT running — should be the only one
```
