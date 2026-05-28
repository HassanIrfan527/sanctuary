# Study Mode — One-time setup

## 1. Sudoers entry for passwordless /etc/hosts edit

Without this, study-mode will prompt for your sudo password on every toggle (unusable).

Run **once**:

```bash
sudo visudo -f /etc/sudoers.d/study-mode
```

Paste exactly:

```
anonymous ALL=(root) NOPASSWD: /usr/bin/install -m 644 /tmp/* /etc/hosts
```

Save & exit. This grants you passwordless `install` *only* for writing to `/etc/hosts` from a `/tmp/*` file. Nothing else. Tight scope.

## 2. Backup your current /etc/hosts

```bash
sudo cp /etc/hosts ~/.dotfiles/hypr/hypr/scripts/study/hosts.original
```

If anything ever goes weird, restore with:

```bash
sudo install -m 644 ~/.dotfiles/hypr/hypr/scripts/study/hosts.original /etc/hosts
```

## 3. Test

```bash
~/.config/hypr/scripts/study/study-mode.sh on
~/.config/hypr/scripts/study/study-mode.sh status   # → on
curl -sI https://www.youtube.com | head -1          # should fail / not resolve
~/.config/hypr/scripts/study/study-mode.sh force-off  # disable without 60s friction (testing only)
```

## Keybinds

| Bind | Action |
|---|---|
| `Super+Shift+T` | Open today's study plan in Neovim (auto-generates daily file) |
| `Super+Shift+S` | Toggle study mode (on → blocks YT/IG, kills Steam/Lutris, calm wallpaper) |
| `Super+ALT+P`   | Start Pomodoro session (4 × 25/5) |
| `Super+ALT+D`   | Old scratchterm bind (was `Super+Shift+T`) |

## Files

- Scripts: `~/.dotfiles/hypr/hypr/scripts/study/`
- Data: `~/study/` (NOT in dotfiles repo; this is your personal notes)
- Blocklist: `~/.dotfiles/hypr/hypr/scripts/study/blocklist.txt` — edit to add/remove sites
- State: `~/.cache/study-mode/state` (`on` or `off`)

## Adjust

- **Add a site to block:** append a line to `blocklist.txt`. Toggle off then on to apply.
- **Add an app to kill in study mode:** edit `KILL_APPS` array in `study-mode.sh`.
- **Different Pomodoro length:** `POMODORO_STUDY=50 POMODORO_BREAK=10 POMODORO_CYCLES=2 ~/.config/hypr/scripts/study/study-pomodoro.sh`
- **Change schedule:** edit `~/study/phase.md`. Tomorrow's daily file picks it up.
